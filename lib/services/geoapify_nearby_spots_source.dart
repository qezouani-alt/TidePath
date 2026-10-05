import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/fishing_location.dart';
import 'nearby_spots_service.dart';

/// A keyed places source. Keep the key out of source control and pass it with
/// --dart-define=GEOAPIFY_PLACES_API_KEY=... when running the app.
class GeoapifyNearbySpotsSource implements NearbySpotsSource {
  GeoapifyNearbySpotsSource({required this.apiKey, http.Client? client})
    : _client = client ?? http.Client();

  final String apiKey;
  final http.Client _client;

  Uri requestFor(FishingLocation location) {
    final lat = location.point.latitude;
    final lon = location.point.longitude;
    return Uri.https('api.geoapify.com', '/v2/places', {
      'categories': 'sport.fishing,beach,natural.coastal,natural.water.bay,maritime.marina,man_made.pier',
      'filter': 'circle:$lon,$lat,${NearbySpotsService.radiusKm * 1000}',
      'bias': 'proximity:$lon,$lat',
      'limit': '80',
      'apiKey': apiKey,
    });
  }

  @override
  Future<List<Map<String, dynamic>>> fetch(FishingLocation location) async {
    final response = await _client
        .get(
          requestFor(location),
          headers: const {'Accept': 'application/json'},
        )
        .timeout(const Duration(seconds: 8));
    if (response.statusCode != 200) {
      throw StateError('Places lookup failed: ${response.statusCode}');
    }
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final features = json['features'];
    if (features is! List) throw const FormatException('Missing places');
    return features
        .whereType<Map<String, dynamic>>()
        .map((feature) {
          final properties = feature['properties'];
          if (properties is! Map<String, dynamic>) return <String, dynamic>{};
          final categories =
              (properties['categories'] as List?)
                  ?.whereType<String>()
                  .toSet() ??
              <String>{};
          final geometry = feature['geometry'];
          final coordinates = geometry is Map ? geometry['coordinates'] : null;
          final lon =
              properties['lon'] ??
              (coordinates is List && coordinates.length > 1
                  ? coordinates[0]
                  : null);
          final lat =
              properties['lat'] ??
              (coordinates is List && coordinates.length > 1
                  ? coordinates[1]
                  : null);
          final tags = <String, dynamic>{'name': properties['name']};
          if (categories.contains('sport.fishing')) {
            tags['leisure'] = 'fishing';
          } else if (categories.contains('beach') ||
              categories.any((category) => category.startsWith('beach.'))) {
            tags['natural'] = 'beach';
          } else if (categories.contains('maritime.marina')) {
            tags['leisure'] = 'marina';
          } else if (categories.contains('man_made.pier')) {
            tags['man_made'] = 'pier';
          } else if (categories.contains('natural.water.bay')) {
            tags['natural'] = 'bay';
          } else if (categories.contains('natural.coastal')) {
            tags['natural'] = 'coast';
          }
          return <String, dynamic>{
            'type': 'place',
            'id': properties['place_id'],
            'lat': lat,
            'lon': lon,
            'tags': tags,
          };
        })
        .where((element) => element.isNotEmpty)
        .toList();
  }
}

class FallbackNearbySpotsSource implements NearbySpotsSource {
  FallbackNearbySpotsSource(this.primary, this.fallback);

  final NearbySpotsSource primary;
  final NearbySpotsSource fallback;

  @override
  Future<List<Map<String, dynamic>>> fetch(FishingLocation location) async {
    try {
      final places = await primary.fetch(location);
      if (places.isNotEmpty) return places;
    } catch (_) {
      // The existing public OpenStreetMap lookup remains available as a fallback.
    }
    return fallback.fetch(location);
  }
}
