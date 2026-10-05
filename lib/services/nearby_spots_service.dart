import 'dart:convert';
import 'dart:math' as math;

import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import '../models/demo_data.dart';
import '../models/fishing_location.dart';
import 'geoapify_nearby_spots_source.dart';

abstract class NearbySpotsSource {
  Future<List<Map<String, dynamic>>> fetch(FishingLocation location);
}

class OverpassNearbySpotsSource implements NearbySpotsSource {
  OverpassNearbySpotsSource({http.Client? client, List<Uri>? endpoints})
    : _client = client ?? http.Client(),
      _endpoints = endpoints ?? _defaultEndpoints;

  static final _defaultEndpoints = [
    Uri.parse('https://overpass.private.coffee/api/interpreter'),
    Uri.parse('https://overpass-api.de/api/interpreter'),
  ];

  final http.Client _client;
  final List<Uri> _endpoints;

  static String queryFor(FishingLocation location) {
    final latitude = location.point.latitude;
    final longitude = location.point.longitude;
    final latitudeOffset = NearbySpotsService.radiusKm / 111.32;
    final longitudeScale = math.cos(latitude * math.pi / 180).abs();
    final longitudeOffset =
        NearbySpotsService.radiusKm / (111.32 * math.max(longitudeScale, .01));
    final bounds =
        latitude.abs() > 85 ||
            longitude - longitudeOffset < -180 ||
            longitude + longitudeOffset > 180
        ? '(around:${NearbySpotsService.radiusKm * 1000},$latitude,$longitude)'
        : '(${(latitude - latitudeOffset).clamp(-90, 90)},'
              '${longitude - longitudeOffset},'
              '${(latitude + latitudeOffset).clamp(-90, 90)},'
              '${longitude + longitudeOffset})';
    return '[out:json][timeout:10];('
        'nwr["leisure"="fishing"]["name"]$bounds;'
        'nwr["fishing"="yes"]["name"]$bounds;'
        'nwr["natural"~"^(beach|cape|bay)\$"]["name"]$bounds;'
        'nwr["leisure"="marina"]["name"]$bounds;'
        'nwr["man_made"="pier"]["name"]$bounds;'
        ');out center qt 80;';
  }

  @override
  Future<List<Map<String, dynamic>>> fetch(FishingLocation location) async {
    final query = queryFor(location);
    Object? lastError;
    for (final endpoint in _endpoints) {
      try {
        final response = await _client
            .post(
              endpoint,
              headers: const {
                'User-Agent': 'TidePathFishing/1.0 (nearby spots)',
                'Accept': 'application/json',
              },
              body: {'data': query},
            )
            .timeout(const Duration(seconds: 8));
        if (response.statusCode != 200) {
          throw StateError(
            'Nearby spots lookup failed: ${response.statusCode}',
          );
        }
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return (json['elements'] as List<dynamic>? ?? const [])
            .whereType<Map<String, dynamic>>()
            .toList();
      } catch (error) {
        lastError = error;
      }
    }
    throw StateError('Nearby spots providers unavailable: $lastError');
  }
}

class NearbySpotsService {
  static const radiusKm = 20;
  static const _geoapifyKey = String.fromEnvironment('GEOAPIFY_PLACES_API_KEY');

  static NearbySpotsSource _defaultSource() {
    final overpass = OverpassNearbySpotsSource();
    if (_geoapifyKey.isEmpty) return overpass;
    return FallbackNearbySpotsSource(
      GeoapifyNearbySpotsSource(apiKey: _geoapifyKey),
      overpass,
    );
  }

  NearbySpotsService({NearbySpotsSource? source, DateTime Function()? now})
    : _source = source ?? _defaultSource(),
      _now = now ?? DateTime.now;

  static final shared = NearbySpotsService();

  final NearbySpotsSource _source;
  final DateTime Function() _now;
  final Map<String, _SpotCacheEntry> _cache = {};
  final Map<String, Future<List<FishingSpot>>> _pending = {};

  String get attribution => _geoapifyKey.isEmpty
      ? '© OpenStreetMap contributors'
      : '© OpenStreetMap contributors · Powered by Geoapify';

  List<FishingSpot>? cachedFor(FishingLocation location) =>
      _cache[location.coordinates]?.spots;

  bool isUnavailable(FishingLocation location) =>
      _cache[location.coordinates]?.failed == true;

  Future<List<FishingSpot>> load(
    FishingLocation location, {
    bool forceRefresh = false,
  }) {
    final key = location.coordinates;
    final pending = _pending[key];
    if (pending != null) return pending;
    final cached = _cache[key];
    if (!forceRefresh &&
        cached != null &&
        _now().difference(cached.fetchedAt) <
            (cached.failed
                ? const Duration(minutes: 10)
                : const Duration(hours: 12))) {
      return Future.value(cached.spots);
    }
    final request = _source
        .fetch(location)
        .then((elements) => parseNearbySpots(elements, location))
        .then((spots) {
          _remember(key, spots, failed: false);
          return spots;
        })
        .catchError((Object _) {
          final fallback = cached?.spots ?? <FishingSpot>[];
          _remember(key, fallback, failed: true);
          return fallback;
        })
        .whenComplete(() {
          _pending.remove(key);
        });
    _pending[key] = request;
    return request;
  }

  void _remember(String key, List<FishingSpot> spots, {required bool failed}) {
    _cache.remove(key);
    _cache[key] = _SpotCacheEntry(spots, _now(), failed);
    if (_cache.length > 12) _cache.remove(_cache.keys.first);
  }

  bool isSample(FishingLocation location) =>
      _cache[location.coordinates]?.failed == true &&
      location.isNearAgadir &&
      (_cache[location.coordinates]?.spots.firstOrNull?.mapped == false);

  static List<FishingSpot> parseNearbySpots(
    List<Map<String, dynamic>> elements,
    FishingLocation location,
  ) {
    final distance = const Distance();
    final spots = <FishingSpot>[];
    final seen = <String>{};
    for (final element in elements) {
      final tags = element['tags'];
      if (tags is! Map<String, dynamic>) continue;
      final latitude = element['lat'] ?? (element['center'] as Map?)?['lat'];
      final longitude = element['lon'] ?? (element['center'] as Map?)?['lon'];
      if (latitude is! num || longitude is! num) continue;
      final point = LatLng(latitude.toDouble(), longitude.toDouble());
      final km = distance.as(LengthUnit.Kilometer, location.point, point);
      if (km > radiusKm) continue;
      final type = _typeFor(tags);
      final rawName = (tags['name:en'] ?? tags['name'])?.toString().trim();
      final name = rawName == null || rawName.isEmpty
          ? type == 'Fishing area'
                ? 'Fishing area near ${location.shortName}'
                : null
          : rawName;
      if (name == null) continue;
      final dedupe = '${name.toLowerCase()}-${(km * 2).round()}';
      if (!seen.add(dedupe)) continue;
      final id = '${element['type']}/${element['id']}';
      spots.add(
        FishingSpot(
          name,
          km < 10
              ? '${km.toStringAsFixed(1)} km away'
              : '${km.round()} km away',
          0,
          type,
          '',
          '',
          const [],
          type == 'Marina' || type == 'Pier'
              ? 'assets/images/marina.png'
              : 'assets/images/coast.png',
          point: point,
          mapped: true,
          sourceId: id,
        ),
      );
    }
    spots.sort((a, b) {
      final aKm = distance.as(LengthUnit.Kilometer, location.point, a.point!);
      final bKm = distance.as(LengthUnit.Kilometer, location.point, b.point!);
      return aKm.compareTo(bKm);
    });
    return spots.take(30).toList();
  }

  static String _typeFor(Map<String, dynamic> tags) {
    if (tags['leisure'] == 'fishing' || tags['fishing'] == 'yes') {
      return 'Fishing area';
    }
    if (tags['natural'] == 'beach') return 'Beach';
    if (tags['natural'] == 'cape') return 'Headland';
    if (tags['natural'] == 'bay') return 'Bay';
    if (tags['natural'] == 'coast') return 'Coast';
    if (tags['leisure'] == 'marina') return 'Marina';
    return 'Pier';
  }
}

class _SpotCacheEntry {
  const _SpotCacheEntry(this.spots, this.fetchedAt, this.failed);
  final List<FishingSpot> spots;
  final DateTime fetchedAt;
  final bool failed;
}
