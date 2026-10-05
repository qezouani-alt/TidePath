import 'dart:convert';

import 'package:fishing/models/fishing_location.dart';
import 'package:fishing/services/geoapify_nearby_spots_source.dart';
import 'package:fishing/services/nearby_spots_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:latlong2/latlong.dart';

const _valencia = FishingLocation(
  label: 'Valencia, Spain',
  point: LatLng(39.4699, -0.3763),
);

void main() {
  test(
    'keyed source requests nearby categories and parses a real place',
    () async {
      final client = MockClient((request) async {
        expect(request.url.host, 'api.geoapify.com');
        expect(
          request.url.queryParameters['filter'],
          'circle:-0.3763,39.4699,20000',
        );
        expect(
          request.url.queryParameters['bias'],
          'proximity:-0.3763,39.4699',
        );
        expect(request.url.queryParameters['categories'], contains('beach'));
        expect(
          request.url.queryParameters['categories'],
          contains('sport.fishing'),
        );
        expect(
          request.url.queryParameters['categories'],
          isNot(contains('commercial')),
        );
        expect(request.url.queryParameters['apiKey'], 'test-key');
        return http.Response(
          jsonEncode({
            'features': [
              {
                'properties': {
                  'name': 'Platja de la Malva-rosa',
                  'place_id': 'place-1',
                  'categories': ['beach'],
                },
                'geometry': {
                  'type': 'Point',
                  'coordinates': [-0.323, 39.478],
                },
              },
            ],
          }),
          200,
        );
      });
      addTearDown(client.close);

      final source = GeoapifyNearbySpotsSource(
        apiKey: 'test-key',
        client: client,
      );
      final raw = await source.fetch(_valencia);
      final spots = NearbySpotsService.parseNearbySpots(raw, _valencia);
      expect(spots, hasLength(1));
      expect(spots.single.name, 'Platja de la Malva-rosa');
      expect(spots.single.type, 'Beach');
      expect(spots.single.mapped, isTrue);
    },
  );

  test(
    'fallback source uses the other provider when the first fails',
    () async {
      final source = FallbackNearbySpotsSource(
        _FailingSource(),
        _PlaceSource(),
      );
      final result = await source.fetch(_valencia);
      expect(result.single['id'], 1);
    },
  );
}

class _FailingSource implements NearbySpotsSource {
  @override
  Future<List<Map<String, dynamic>>> fetch(FishingLocation location) =>
      Future.error(StateError('unavailable'));
}

class _PlaceSource implements NearbySpotsSource {
  @override
  Future<List<Map<String, dynamic>>> fetch(FishingLocation location) async => [
    {'id': 1},
  ];
}
