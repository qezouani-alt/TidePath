import 'dart:convert';
import 'dart:math' as math;

import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import '../models/coast_orientation.dart';
import '../models/fishing_location.dart';

abstract class CoastlineSource {
  Future<List<List<LatLng>>> fetch(FishingLocation location);
}

/// OpenStreetMap coastline ways are directed with land left and sea right.
class OverpassCoastlineSource implements CoastlineSource {
  const OverpassCoastlineSource();

  static final _endpoint = Uri.parse('https://overpass-api.de/api/interpreter');

  @override
  Future<List<List<LatLng>>> fetch(FishingLocation location) async {
    final latitude = location.point.latitude;
    final longitude = location.point.longitude;
    final query =
        '[out:json][timeout:12];'
        'way["natural"="coastline"](around:10000,$latitude,$longitude);'
        'out geom;';
    final response = await http
        .post(
          _endpoint,
          headers: const {
            'User-Agent': 'TidePath fishing app (coast wind direction)',
          },
          body: {'data': query},
        )
        .timeout(const Duration(seconds: 15));
    if (response.statusCode != 200) {
      throw StateError('Coastline lookup failed: ${response.statusCode}');
    }
    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final elements = decoded['elements'] as List<dynamic>? ?? const [];
    return [
      for (final element in elements)
        if (element is Map<String, dynamic> &&
            element['geometry'] is List<dynamic>)
          [
            for (final node in element['geometry'] as List<dynamic>)
              if (node is Map<String, dynamic> &&
                  node['lat'] is num &&
                  node['lon'] is num)
                LatLng(
                  (node['lat'] as num).toDouble(),
                  (node['lon'] as num).toDouble(),
                ),
          ],
    ];
  }
}

class CoastOrientationService {
  CoastOrientationService({CoastlineSource? source, DateTime Function()? now})
    : _source = source ?? const OverpassCoastlineSource(),
      _now = now ?? DateTime.now;

  static CoastOrientationService shared = CoastOrientationService();

  final CoastlineSource _source;
  final DateTime Function() _now;
  final Map<String, _CoastCacheEntry> _cache = {};
  final Map<String, Future<CoastOrientation?>> _pending = {};

  CoastOrientation? cachedFor(FishingLocation location) =>
      _cache[_key(location)]?.value;

  Future<CoastOrientation?> lookup(FishingLocation location) {
    final key = _key(location);
    final cached = _cache[key];
    if (cached != null &&
        _now().difference(cached.fetchedAt) <
            (cached.value == null
                ? const Duration(minutes: 20)
                : const Duration(days: 1))) {
      return Future.value(cached.value);
    }
    final inFlight = _pending[key];
    if (inFlight != null) return inFlight;
    final request = _source
        .fetch(location)
        .then((ways) => _nearestCoast(location.point, ways))
        .catchError((Object _) => null)
        .then((value) {
          _cache[key] = _CoastCacheEntry(value, _now());
          return value;
        })
        .whenComplete(() {
          _pending.remove(key);
        });
    _pending[key] = request;
    return request;
  }

  static String _key(FishingLocation location) => location.coordinates;

  static CoastOrientation? _nearestCoast(
    LatLng point,
    List<List<LatLng>> ways,
  ) {
    final latitudeScale = math.cos(point.latitude * math.pi / 180);
    final candidates = <_CoastSegment>[];
    for (final way in ways) {
      for (var index = 1; index < way.length; index++) {
        final from = way[index - 1];
        final to = way[index];
        final ax = (from.longitude - point.longitude) * 111320 * latitudeScale;
        final ay = (from.latitude - point.latitude) * 111320;
        final bx = (to.longitude - point.longitude) * 111320 * latitudeScale;
        final by = (to.latitude - point.latitude) * 111320;
        final dx = bx - ax;
        final dy = by - ay;
        final lengthSquared = dx * dx + dy * dy;
        if (lengthSquared < 1) continue;
        final t = (-(ax * dx + ay * dy) / lengthSquared).clamp(0.0, 1.0);
        final nearestX = ax + t * dx;
        final nearestY = ay + t * dy;
        final distance = math.sqrt(nearestX * nearestX + nearestY * nearestY);
        final tangent = math.atan2(dx, dy) * 180 / math.pi;
        candidates.add(_CoastSegment(distance, (tangent + 90 + 360) % 360));
      }
    }
    if (candidates.isEmpty) return null;
    candidates.sort((a, b) => a.distanceM.compareTo(b.distanceM));
    final nearest = candidates.first.distanceM;
    if (nearest > 10000) return null;

    // Average a few nearby directed segments to avoid single-node zigzags.
    var east = 0.0;
    var north = 0.0;
    for (final segment
        in candidates
            .where((segment) => segment.distanceM <= nearest + 400)
            .take(8)) {
      final weight = 1 / math.max(segment.distanceM, 100);
      final radians = segment.seaBearingDegrees * math.pi / 180;
      east += math.sin(radians) * weight;
      north += math.cos(radians) * weight;
    }
    if (math.sqrt(east * east + north * north) < .00001) return null;
    return CoastOrientation(
      seaBearingDegrees: (math.atan2(east, north) * 180 / math.pi + 360) % 360,
      distanceKm: nearest / 1000,
    );
  }
}

class _CoastSegment {
  const _CoastSegment(this.distanceM, this.seaBearingDegrees);
  final double distanceM, seaBearingDegrees;
}

class _CoastCacheEntry {
  const _CoastCacheEntry(this.value, this.fetchedAt);
  final CoastOrientation? value;
  final DateTime fetchedAt;
}
