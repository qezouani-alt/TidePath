import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/fish_catalog.dart';
import 'inaturalist_photo_service.dart';
import 'wikimedia_fish_photo_service.dart';

abstract class FishCatalogSource {
  Future<FishCatalogPage> fetch(String query, int page);
}

class INaturalistFishCatalogSource implements FishCatalogSource {
  INaturalistFishCatalogSource({
    http.Client? client,
    this.requestSpacing = const Duration(seconds: 1),
  }) : _client = client ?? http.Client();

  final http.Client _client;
  final Duration requestSpacing;
  DateTime? _nextRequestAt;
  late final _photoLookup = INaturalistPhotoLookup(
    client: _client,
    beforeRequest: _pace,
  );
  late final _wikimediaLookup = WikimediaFishPhotoLookup(client: _client);

  static const pageSize = FishCatalogPage.pageSize;

  Future<void> _pace() async {
    final now = DateTime.now();
    final scheduled = _nextRequestAt != null && _nextRequestAt!.isAfter(now)
        ? _nextRequestAt!
        : now;
    _nextRequestAt = scheduled.add(requestSpacing);
    if (scheduled.isAfter(now)) {
      await Future.delayed(scheduled.difference(now));
    }
  }

  Uri requestFor(String query, int page) =>
      Uri.https('api.inaturalist.org', '/v1/taxa', {
        // Ray-finned, cartilaginous, jawless, and lobe-finned fishes.
        'taxon_id': '47178,196614,797045,85497',
        'rank': 'species',
        'order_by': 'observations_count',
        'per_page': '$pageSize',
        'page': '$page',
        'locale': 'en',
        if (query.trim().isNotEmpty) 'q': query.trim(),
      });

  @override
  Future<FishCatalogPage> fetch(String query, int page) async {
    await _pace();
    final response = await _client
        .get(
          requestFor(query, page),
          headers: const {
            'Accept': 'application/json',
            'User-Agent': 'TidePathFishing/1.0 (fish catalog)',
          },
        )
        .timeout(const Duration(seconds: 10));
    if (response.statusCode != 200) {
      throw StateError('Fish catalog lookup failed: ${response.statusCode}');
    }
    final data = jsonDecode(response.body);
    if (data is! Map<String, dynamic> || data['results'] is! List) {
      throw const FormatException('Missing fish catalog results');
    }
    final raw = data['results'] as List;
    final total = (data['total_results'] as num?)?.toInt() ?? raw.length;
    final species = <FishCatalogSpecies>[];
    final seen = <int>{};
    for (final item in raw.whereType<Map<String, dynamic>>()) {
      if (item['rank'] != 'species') continue;
      final id = item['id'];
      final scientific = item['name']?.toString().trim() ?? '';
      if (id is! num || scientific.isEmpty || !seen.add(id.toInt())) {
        continue;
      }
      final common = item['preferred_common_name']?.toString().trim();
      final photo = parseLicensedFishPhoto(item['default_photo']);
      species.add(
        FishCatalogSpecies(
          taxonId: id.toInt(),
          name: common == null || common.isEmpty ? scientific : common,
          scientificName: scientific,
          observationCount: (item['observations_count'] as num?)?.toInt() ?? 0,
          photoUrl: photo?.url,
          photoCredit: photo?.credit,
          photoLicense: photo?.license,
          photoSourceUrl: photo?.sourceUrl,
        ),
      );
    }
    final missing = species.where((fish) => fish.photoUrl == null);
    final alternatives = await _photoLookup.findFor(
      missing.map((fish) => fish.taxonId),
    );
    for (var i = 0; i < species.length; i++) {
      final photo = alternatives[species[i].taxonId];
      if (photo != null && species[i].photoUrl == null) {
        species[i] = species[i].withPhoto(
          url: photo.url,
          credit: photo.credit,
          license: photo.license,
          sourceUrl: photo.sourceUrl,
        );
      }
    }
    final withoutPhoto = species
        .take(24)
        .where((item) => item.photoUrl == null);
    final commonsPhotos = await _wikimediaLookup
        .findFor({
          for (final item in withoutPhoto) item.taxonId: item.scientificName,
        })
        .timeout(const Duration(seconds: 6), onTimeout: () => const {});
    for (var i = 0; i < species.length; i++) {
      final photo = commonsPhotos[species[i].taxonId];
      if (photo != null && species[i].photoUrl == null) {
        species[i] = species[i].withPhoto(
          url: photo.url,
          credit: photo.credit,
          license: photo.license,
          sourceUrl: photo.sourceUrl,
        );
      }
    }
    return FishCatalogPage(species: species, total: total, page: page);
  }
}

class FishCatalogService {
  FishCatalogService({FishCatalogSource? source, DateTime Function()? now})
    : _source = source ?? INaturalistFishCatalogSource(),
      _now = now ?? DateTime.now;

  static final shared = FishCatalogService();

  final FishCatalogSource _source;
  final DateTime Function() _now;
  final Map<String, _CatalogCacheEntry> _cache = {};
  final Map<String, Future<FishCatalogPage>> _pending = {};
  final Set<String> _unavailable = {};
  final Map<String, DateTime> _lastFailure = {};

  String _key(String query, int page) => '${query.trim().toLowerCase()}/$page';

  FishCatalogPage? cachedFor(String query, {int page = 1}) =>
      _cache[_key(query, page)]?.result;

  bool isUnavailable(String query, {int page = 1}) =>
      _unavailable.contains(_key(query, page));

  Future<FishCatalogPage> load(
    String query, {
    int page = 1,
    bool forceRefresh = false,
  }) {
    final normalized = query.trim();
    final key = _key(normalized, page);
    final pending = _pending[key];
    if (pending != null) return pending;
    final cached = _cache[key];
    if (!forceRefresh &&
        cached != null &&
        _now().difference(cached.fetchedAt) < const Duration(hours: 12)) {
      return Future.value(cached.result);
    }
    final lastFailure = _lastFailure[key];
    if (!forceRefresh &&
        lastFailure != null &&
        _now().difference(lastFailure) < const Duration(minutes: 5)) {
      return Future.value(
        cached?.result ??
            FishCatalogPage(species: const [], total: 0, page: page),
      );
    }
    final request = _source
        .fetch(normalized, page)
        .then((result) {
          _cache[key] = _CatalogCacheEntry(result, _now());
          _unavailable.remove(key);
          _lastFailure.remove(key);
          if (_cache.length > 36) _cache.remove(_cache.keys.first);
          return result;
        })
        .catchError((Object _) {
          _unavailable.add(key);
          _lastFailure[key] = _now();
          return cached?.result ??
              FishCatalogPage(species: const [], total: 0, page: page);
        })
        .whenComplete(() {
          _pending.remove(key);
        });
    _pending[key] = request;
    return request;
  }
}

class _CatalogCacheEntry {
  const _CatalogCacheEntry(this.result, this.fetchedAt);
  final FishCatalogPage result;
  final DateTime fetchedAt;
}
