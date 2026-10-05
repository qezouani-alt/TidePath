import 'dart:convert';

import 'package:fishing/models/fish_catalog.dart';
import 'package:fishing/services/fish_catalog_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test(
    'worldwide catalog searches fish groups and parses licensed photos',
    () async {
      final client = MockClient((request) async {
        expect(request.url.path, '/v1/taxa');
        expect(
          request.url.queryParameters['taxon_id'],
          '47178,196614,797045,85497',
        );
        expect(request.url.queryParameters['rank'], 'species');
        expect(request.url.queryParameters['q'], 'shark');
        expect(request.url.queryParameters['page'], '2');
        return http.Response(
          jsonEncode({
            'total_results': 42,
            'results': [
              {
                'id': 82128,
                'rank': 'species',
                'name': 'Cetorhinus maximus',
                'preferred_common_name': 'Basking Shark',
                'observations_count': 318,
                'default_photo': {
                  'id': 91,
                  'license_code': 'cc-by',
                  'medium_url': 'https://example.org/shark.jpg',
                  'attribution': '© Shark photographer (CC BY)',
                },
              },
            ],
          }),
          200,
        );
      });
      addTearDown(client.close);
      final source = INaturalistFishCatalogSource(
        client: client,
        requestSpacing: Duration.zero,
      );
      final page = await source.fetch('shark', 2);
      expect(page.total, 42);
      expect(page.page, 2);
      expect(page.species.single.name, 'Basking Shark');
      expect(
        page.species.single.observationLabel,
        '318 observations worldwide',
      );
      expect(page.species.single.photoLicense, 'CC BY');
      expect(
        page.species.single.photoSourceUrl,
        'https://www.inaturalist.org/photos/91',
      );
    },
  );

  test('catalog shares requests and caches each search page', () async {
    final source = _CatalogSource();
    final service = FishCatalogService(source: source);
    final first = service.load('shark');
    final same = service.load('shark');
    await first;
    await same;
    await service.load('shark');
    await service.load('shark', page: 2);
    await service.load('bass');
    expect(source.calls, ['shark/1', 'shark/2', 'bass/1']);
  });

  test('catalog keeps cached data when refresh fails', () async {
    final source = _CatalogSource();
    final service = FishCatalogService(source: source);
    final first = await service.load('');
    source.fail = true;
    final fallback = await service.load('', forceRefresh: true);
    expect(fallback.species.single.name, first.species.single.name);
    expect(service.isUnavailable(''), isTrue);
  });

  test('paging stops at the API limit while search remains available', () {
    expect(
      const FishCatalogPage(species: [], total: 37000, page: 1).hasMore,
      isTrue,
    );
    expect(
      const FishCatalogPage(species: [], total: 37000, page: 500).hasMore,
      isFalse,
    );
  });
}

class _CatalogSource implements FishCatalogSource {
  final List<String> calls = [];
  bool fail = false;

  @override
  Future<FishCatalogPage> fetch(String query, int page) async {
    calls.add('$query/$page');
    if (fail) throw StateError('offline');
    return FishCatalogPage(
      species: const [
        FishCatalogSpecies(
          taxonId: 1,
          name: 'Basking Shark',
          scientificName: 'Cetorhinus maximus',
          observationCount: 318,
        ),
      ],
      total: 1,
      page: page,
    );
  }
}
