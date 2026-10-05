import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/fishing_location.dart';
import '../models/nearby_fish.dart';
import 'inaturalist_photo_service.dart';
import 'wikimedia_fish_photo_service.dart';

abstract class NearbyFishSource {
  Future<NearbyFishPage> fetch(FishingLocation location, int page);
}

class INaturalistNearbyFishSource implements NearbyFishSource {
  INaturalistNearbyFishSource({
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

  static const radiusKm = 30;
  static const pageSize = 100;

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

  Uri requestFor(FishingLocation location, int page) =>
      Uri.https('api.inaturalist.org', '/v1/observations/species_counts', {
        'taxon_id': '47178', // Ray-finned fishes, the main angling fish group.
        'lat': location.point.latitude.toString(),
        'lng': location.point.longitude.toString(),
        'radius': '$radiusKm',
        'quality_grade': 'research',
        'per_page': '$pageSize',
        'page': '$page',
        'locale': 'en',
      });

  @override
  Future<NearbyFishPage> fetch(FishingLocation location, int page) async {
    await _pace();
    final response = await _client
        .get(
          requestFor(location, page),
          headers: const {
            'Accept': 'application/json',
            'User-Agent': 'TidePathFishing/1.0 (nearby fish)',
          },
        )
        .timeout(const Duration(seconds: 10));
    if (response.statusCode != 200) {
      throw StateError('Nearby fish lookup failed: ${response.statusCode}');
    }
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final raw = json['results'];
    if (raw is! List) throw const FormatException('Missing fish results');
    final total = (json['total_results'] as num?)?.toInt() ?? raw.length;
    final seen = <int>{};
    final fish = <NearbyFish>[];
    for (final item in raw.whereType<Map<String, dynamic>>()) {
      final taxon = item['taxon'];
      if (taxon is! Map<String, dynamic> || taxon['rank'] != 'species') {
        continue;
      }
      final id = taxon['id'];
      final scientific = taxon['name']?.toString().trim() ?? '';
      final count = item['count'];
      if (id is! num || scientific.isEmpty || count is! num) continue;
      if (!seen.add(id.toInt())) continue;
      final common = taxon['preferred_common_name']?.toString().trim();
      final photo = parseLicensedFishPhoto(taxon['default_photo']);
      fish.add(
        NearbyFish(
          taxonId: id.toInt(),
          name: common == null || common.isEmpty ? scientific : common,
          scientificName: scientific,
          observationCount: count.toInt(),
          photoUrl: photo?.url,
          photoCredit: photo?.credit,
          photoLicense: photo?.license,
          photoSourceUrl: photo?.sourceUrl,
        ),
      );
    }
    // Prefer a correctly identified and reusable photo. Keep requests bounded
    // to the leading species shown first in the guide.
    final missing = fish
        .take(24)
        .where((item) => item.photoUrl == null)
        .toList();
    if (missing.isNotEmpty) {
      final alternatives = await _photoLookup.findFor(
        missing.map((item) => item.taxonId),
      );
      for (var i = 0; i < fish.length; i++) {
        final photo = alternatives[fish[i].taxonId];
        if (photo != null && fish[i].photoUrl == null) {
          fish[i] = fish[i].withPhoto(
            url: photo.url,
            credit: photo.credit,
            license: photo.license,
            sourceUrl: photo.sourceUrl,
          );
        }
      }
    }
    final withoutPhoto = fish.take(24).where((item) => item.photoUrl == null);
    final commonsPhotos = await _wikimediaLookup
        .findFor({
          for (final item in withoutPhoto) item.taxonId: item.scientificName,
        })
        .timeout(const Duration(seconds: 6), onTimeout: () => const {});
    for (var i = 0; i < fish.length; i++) {
      final photo = commonsPhotos[fish[i].taxonId];
      if (photo != null && fish[i].photoUrl == null) {
        fish[i] = fish[i].withPhoto(
          url: photo.url,
          credit: photo.credit,
          license: photo.license,
          sourceUrl: photo.sourceUrl,
        );
      }
    }
    return NearbyFishPage(fish: fish, total: total, page: page);
  }
}

class NearbyFishService {
  NearbyFishService({NearbyFishSource? source, DateTime Function()? now})
    : _source = source ?? INaturalistNearbyFishSource(),
      _now = now ?? DateTime.now;

  static final shared = NearbyFishService();

  final NearbyFishSource _source;
  final DateTime Function() _now;
  final Map<String, _FishCacheEntry> _cache = {};
  final Map<String, Future<NearbyFishPage>> _pending = {};
  final Set<String> _unavailable = {};
  final Map<String, DateTime> _lastFailure = {};

  String _key(FishingLocation location, int page) =>
      '${location.coordinates}/$page';

  NearbyFishPage? cachedFor(FishingLocation location, {int page = 1}) =>
      _cache[_key(location, page)]?.result;

  bool isUnavailable(FishingLocation location, {int page = 1}) =>
      _unavailable.contains(_key(location, page));

  Future<NearbyFishPage> load(
    FishingLocation location, {
    int page = 1,
    bool forceRefresh = false,
  }) {
    final key = _key(location, page);
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
        cached?.result ?? NearbyFishPage(fish: const [], total: 0, page: page),
      );
    }
    final request = _source
        .fetch(location, page)
        .then((result) {
          _cache[key] = _FishCacheEntry(result, _now());
          _unavailable.remove(key);
          _lastFailure.remove(key);
          if (_cache.length > 24) _cache.remove(_cache.keys.first);
          return result;
        })
        .catchError((Object _) {
          _unavailable.add(key);
          _lastFailure[key] = _now();
          return cached?.result ??
              NearbyFishPage(fish: const [], total: 0, page: page);
        })
        .whenComplete(() {
          _pending.remove(key);
        });
    _pending[key] = request;
    return request;
  }
}

class _FishCacheEntry {
  const _FishCacheEntry(this.result, this.fetchedAt);
  final NearbyFishPage result;
  final DateTime fetchedAt;
}
