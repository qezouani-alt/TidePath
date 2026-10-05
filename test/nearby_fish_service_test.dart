import 'dart:async';
import 'dart:convert';

import 'package:fishing/models/fishing_location.dart';
import 'package:fishing/models/nearby_fish.dart';
import 'package:fishing/services/nearby_fish_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:latlong2/latlong.dart';

const _agadir = FishingLocation(
  label: 'Agadir, Morocco',
  point: LatLng(30.4278, -9.5981),
);
const _valencia = FishingLocation(
  label: 'Valencia, Spain',
  point: LatLng(39.4699, -0.3763),
);

void main() {
  test(
    'requests observed fish for the selected location and parses credits',
    () async {
      final client = MockClient((request) async {
        if (request.url.path.startsWith('/v1/taxa/')) {
          expect(request.url.path, '/v1/taxa/13');
          return http.Response(
            jsonEncode({
              'results': [
                {
                  'id': 13,
                  'taxon_photos': [
                    {
                      'photo': {
                        'id': 45,
                        'license_code': 'cc-by-nc',
                        'medium_url': 'https://example.org/restricted.jpg',
                        'attribution': 'Restricted photographer',
                      },
                    },
                    {
                      'photo': {
                        'id': 46,
                        'license_code': 'cc-by-sa',
                        'medium_url': 'https://example.org/usable.jpg',
                        'attribution': 'Alternative photographer',
                      },
                    },
                  ],
                },
              ],
            }),
            200,
          );
        }
        expect(request.url.host, 'api.inaturalist.org');
        expect(request.url.queryParameters['lat'], '30.4278');
        expect(request.url.queryParameters['lng'], '-9.5981');
        expect(request.url.queryParameters['radius'], '30');
        expect(request.url.queryParameters['taxon_id'], '47178');
        expect(request.url.queryParameters['quality_grade'], 'research');
        return http.Response(
          jsonEncode({
            'total_results': 2,
            'results': [
              {
                'count': 7,
                'taxon': {
                  'id': 12,
                  'rank': 'species',
                  'name': 'Diplodus sargus',
                  'preferred_common_name': 'White Seabream',
                  'default_photo': {
                    'id': 44,
                    'license_code': 'cc-by',
                    'medium_url': 'https://example.org/fish.jpg',
                    'attribution_name': 'A. Photographer',
                  },
                },
              },
              {
                'count': 4,
                'taxon': {
                  'id': 13,
                  'rank': 'species',
                  'name': 'Mugil cephalus',
                  'default_photo': {
                    'id': 45,
                    'license_code': 'cc-by-nc',
                    'medium_url': 'https://example.org/mullet.jpg',
                  },
                },
              },
            ],
          }),
          200,
        );
      });
      addTearDown(client.close);
      final page = await INaturalistNearbyFishSource(
        client: client,
        requestSpacing: Duration.zero,
      ).fetch(_agadir, 1);
      expect(page.total, 2);
      expect(page.fish.map((fish) => fish.name), [
        'White Seabream',
        'Mugil cephalus',
      ]);
      expect(page.fish.first.photoCredit, 'A. Photographer');
      expect(page.fish.first.photoLicense, 'CC BY');
      expect(page.fish.last.photoUrl, 'https://example.org/usable.jpg');
      expect(page.fish.last.photoLicense, 'CC BY-SA');
      expect(
        page.fish.last.photoSourceUrl,
        'https://www.inaturalist.org/photos/46',
      );
      expect(page.fish.first.observationLabel, '7 observations nearby');
    },
  );

  test(
    'uses a batched observation photo when taxon photos are restricted',
    () async {
      final client = MockClient((request) async {
        if (request.url.path == '/v1/observations/species_counts') {
          return http.Response(
            jsonEncode({
              'total_results': 1,
              'results': [
                {
                  'count': 2,
                  'taxon': {
                    'id': 118675,
                    'rank': 'species',
                    'name': 'Serranus cabrilla',
                    'preferred_common_name': 'Comber',
                    'default_photo': {
                      'id': 1,
                      'license_code': 'cc-by-nc',
                      'medium_url': 'https://example.org/restricted.jpg',
                    },
                  },
                },
              ],
            }),
            200,
          );
        }
        if (request.url.path == '/v1/taxa/118675') {
          return http.Response(
            jsonEncode({
              'results': [
                {'id': 118675, 'taxon_photos': []},
              ],
            }),
            200,
          );
        }
        expect(request.url.path, '/v1/observations');
        expect(request.url.queryParameters['taxon_ids'], '118675');
        expect(
          request.url.queryParameters['photo_license'],
          'cc0,cc-by,cc-by-sa',
        );
        return http.Response(
          jsonEncode({
            'results': [
              {
                'taxon': {'id': 118675},
                'photos': [
                  {
                    'id': 99,
                    'license_code': 'cc-by',
                    'url': 'https://example.org/photos/99/square.jpg',
                    'attribution': '© Fish observer (CC BY)',
                  },
                ],
              },
            ],
          }),
          200,
        );
      });
      addTearDown(client.close);
      final page = await INaturalistNearbyFishSource(
        client: client,
        requestSpacing: Duration.zero,
      ).fetch(_agadir, 1);
      expect(
        page.fish.single.photoUrl,
        'https://example.org/photos/99/medium.jpg',
      );
      expect(page.fish.single.photoCredit, '© Fish observer (CC BY)');
      expect(
        page.fish.single.photoSourceUrl,
        'https://www.inaturalist.org/photos/99',
      );
    },
  );

  test('one location request is shared and cached across screens', () async {
    final source = _ControlledSource();
    final service = NearbyFishService(source: source);
    final first = service.load(_agadir);
    final second = service.load(_agadir);
    expect(source.calls, 1);
    source.complete(const NearbyFishPage(fish: [], total: 0, page: 1));
    await first;
    await second;
    await service.load(_agadir);
    expect(source.calls, 1);
    expect(service.cachedFor(_agadir), isNotNull);
  });

  test('a different selected place makes a separate lookup', () async {
    final source = _ImmediateSource();
    final service = NearbyFishService(source: source);
    await service.load(_agadir);
    await service.load(_valencia);
    expect(source.calls, 2);
  });

  test('failure is cached briefly and refresh can retry', () async {
    final source = _FailingSource();
    final service = NearbyFishService(source: source);
    expect((await service.load(_agadir)).fish, isEmpty);
    expect(service.isUnavailable(_agadir), isTrue);
    await service.load(_agadir);
    expect(source.calls, 1);
    await service.load(_agadir, forceRefresh: true);
    expect(source.calls, 2);
  });
}

class _ControlledSource implements NearbyFishSource {
  final _completer = Completer<NearbyFishPage>();
  int calls = 0;

  @override
  Future<NearbyFishPage> fetch(FishingLocation location, int page) {
    calls++;
    return _completer.future;
  }

  void complete(NearbyFishPage result) => _completer.complete(result);
}

class _ImmediateSource implements NearbyFishSource {
  int calls = 0;

  @override
  Future<NearbyFishPage> fetch(FishingLocation location, int page) async {
    calls++;
    return NearbyFishPage(fish: const [], total: 0, page: page);
  }
}

class _FailingSource implements NearbyFishSource {
  int calls = 0;

  @override
  Future<NearbyFishPage> fetch(FishingLocation location, int page) {
    calls++;
    return Future.error(StateError('offline'));
  }
}
