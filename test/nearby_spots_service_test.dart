import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:fishing/models/fishing_location.dart';
import 'package:fishing/services/nearby_spots_service.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

const _tokyo = FishingLocation(
  label: 'Tokyo, Japan',
  point: LatLng(35.6762, 139.6503),
);

void main() {
  test(
    'falls back to the second approved provider after a server error',
    () async {
      final hosts = <String>[];
      final client = MockClient((request) async {
        hosts.add(request.url.host);
        expect(request.bodyFields['data'], contains('out center qt 80;'));
        if (hosts.length == 1) return http.Response('busy', 504);
        return http.Response(
          jsonEncode({
            'elements': [
              {
                'type': 'node',
                'id': 8,
                'lat': 35.6762,
                'lon': 139.6503,
                'tags': {'name': 'Test Pier', 'man_made': 'pier'},
              },
            ],
          }),
          200,
        );
      });
      addTearDown(client.close);
      final result = await OverpassNearbySpotsSource(client: client)
          .fetch(_tokyo);
      expect(result.single['id'], 8);
      expect(hosts, ['overpass.private.coffee', 'overpass-api.de']);
    },
  );

  test('query uses bounded output and a local box for ordinary locations', () {
    final query = OverpassNearbySpotsSource.queryFor(_tokyo);
    expect(query, contains('out center qt 80;'));
    expect(query, contains('nwr["natural"~"^(beach|cape|bay)\$"]'));
    expect(query, isNot(contains('around:')));
  });

  test('query uses a radius when a box would cross the date line', () {
    const location = FishingLocation(
      label: 'Fiji',
      point: LatLng(-17.7, 179.95),
    );
    expect(
      OverpassNearbySpotsSource.queryFor(location),
      contains('around:20000'),
    );
  });

  test('nearby search parses mapped places, distances, and categories', () {
    final spots = NearbySpotsService.parseNearbySpots([
      {
        'type': 'way',
        'id': 42,
        'center': {'lat': 35.6862, 'lon': 139.6503},
        'tags': {'name': 'Test Beach', 'natural': 'beach'},
      },
      {
        'type': 'node',
        'id': 43,
        'lat': 35.6772,
        'lon': 139.6503,
        'tags': {'name': 'Fishing Pier', 'man_made': 'pier'},
      },
      {
        'type': 'node',
        'id': 44,
        'lat': 35.8762,
        'lon': 139.6503,
        'tags': {'name': 'Outside the 20 km search', 'natural': 'beach'},
      },
    ], _tokyo);

    expect(spots.map((spot) => spot.name), ['Fishing Pier', 'Test Beach']);
    expect(spots.first.type, 'Pier');
    expect(spots.first.mapped, isTrue);
    expect(spots.first.sourceId, 'node/43');
    expect(spots.first.distance, contains('km away'));
    expect(spots.first.score, 0);
  });

  test('shared requests use one lookup and cache its result', () async {
    final source = _Source();
    final service = NearbySpotsService(source: source);
    final first = service.load(_tokyo);
    final second = service.load(_tokyo);
    expect(source.calls, 1);
    source.complete([]);
    expect(await first, isEmpty);
    expect(await second, isEmpty);
    expect(await service.load(_tokyo), isEmpty);
    expect(source.calls, 1);
  });

  test('failure never shows Agadir demo spots for another country', () async {
    final service = NearbySpotsService(source: _FailingSource());
    expect(await service.load(_tokyo), isEmpty);
    expect(service.isSample(_tokyo), isFalse);
  });

  test('failure does not show sample spots for Agadir', () async {
    final service = NearbySpotsService(source: _FailingSource());
    const agadir = FishingLocation(
      label: 'Agadir, Morocco',
      point: LatLng(30.4278, -9.5981),
    );
    final spots = await service.load(agadir);
    expect(spots, isEmpty);
    expect(service.isSample(agadir), isFalse);
  });
}

class _Source implements NearbySpotsSource {
  final _result = Completer<List<Map<String, dynamic>>>();
  int calls = 0;

  @override
  Future<List<Map<String, dynamic>>> fetch(FishingLocation location) {
    calls++;
    return _result.future;
  }

  void complete(List<Map<String, dynamic>> elements) =>
      _result.complete(elements);
}

class _FailingSource implements NearbySpotsSource {
  @override
  Future<List<Map<String, dynamic>>> fetch(FishingLocation location) =>
      Future.error(StateError('offline'));
}
