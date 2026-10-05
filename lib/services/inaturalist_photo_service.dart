import 'dart:convert';

import 'package:http/http.dart' as http;

class LicensedFishPhoto {
  const LicensedFishPhoto({
    required this.url,
    required this.credit,
    required this.license,
    required this.sourceUrl,
  });

  final String url;
  final String credit;
  final String license;
  final String sourceUrl;
}

LicensedFishPhoto? parseLicensedFishPhoto(Object? value) {
  if (value is! Map<String, dynamic>) return null;
  final code = value['license_code']?.toString().toLowerCase();
  final license = switch (code) {
    'cc0' => 'CC0',
    'cc-by' => 'CC BY',
    'cc-by-sa' => 'CC BY-SA',
    _ => null,
  };
  if (license == null) return null;
  final url =
      value['medium_url']?.toString() ??
      value['url']?.toString().replaceFirst('/square.', '/medium.');
  final uri = url == null ? null : Uri.tryParse(url);
  if (uri == null || !uri.isScheme('https')) return null;
  final credit = value['attribution_name']?.toString().trim().isNotEmpty == true
      ? value['attribution_name'].toString().trim()
      : value['attribution']?.toString().trim();
  if (code != 'cc0' && (credit == null || credit.isEmpty)) return null;
  final id = value['id'];
  final source =
      value['native_page_url']?.toString() ??
      (id is num ? 'https://www.inaturalist.org/photos/${id.toInt()}' : null);
  final sourceUri = source == null ? null : Uri.tryParse(source);
  if (sourceUri == null || !sourceUri.isScheme('https')) return null;
  return LicensedFishPhoto(
    url: uri.toString(),
    credit: credit == null || credit.isEmpty
        ? 'iNaturalist contributor'
        : credit,
    license: license,
    sourceUrl: sourceUri.toString(),
  );
}

/// Finds reusable species photos in at most two batched requests.
class INaturalistPhotoLookup {
  const INaturalistPhotoLookup({
    required this.client,
    required this.beforeRequest,
  });

  final http.Client client;
  final Future<void> Function() beforeRequest;

  Future<Map<int, LicensedFishPhoto>> findFor(Iterable<int> taxonIds) async {
    final ids = taxonIds.toSet();
    if (ids.isEmpty) return const {};
    final photos = <int, LicensedFishPhoto>{};
    try {
      photos.addAll(await _taxonPhotos(ids));
    } catch (_) {
      // A failed photo lookup must not hide fish catalog entries.
    }
    final remaining = ids.difference(photos.keys.toSet());
    if (remaining.isNotEmpty) {
      try {
        photos.addAll(await _observationPhotos(remaining));
      } catch (_) {
        // The icon remains available if no licensed photo can be found.
      }
    }
    return photos;
  }

  Future<Map<int, LicensedFishPhoto>> _taxonPhotos(Set<int> ids) async {
    await beforeRequest();
    final uri = Uri.https('api.inaturalist.org', '/v1/taxa/${ids.join(',')}', {
      'locale': 'en',
    });
    final response = await client
        .get(uri, headers: const {'Accept': 'application/json'})
        .timeout(const Duration(seconds: 4));
    if (response.statusCode != 200) return const {};
    final data = jsonDecode(response.body);
    if (data is! Map<String, dynamic> || data['results'] is! List) {
      return const {};
    }
    final photos = <int, LicensedFishPhoto>{};
    for (final taxon
        in (data['results'] as List).whereType<Map<String, dynamic>>()) {
      final id = taxon['id'];
      final candidates = taxon['taxon_photos'];
      if (id is! num || !ids.contains(id.toInt()) || candidates is! List) {
        continue;
      }
      for (final item in candidates.whereType<Map<String, dynamic>>()) {
        final photo = parseLicensedFishPhoto(item['photo']);
        if (photo != null) {
          photos[id.toInt()] = photo;
          break;
        }
      }
    }
    return photos;
  }

  Future<Map<int, LicensedFishPhoto>> _observationPhotos(Set<int> ids) async {
    await beforeRequest();
    final uri = Uri.https('api.inaturalist.org', '/v1/observations', {
      'taxon_ids': ids.join(','),
      'quality_grade': 'research',
      'photos': 'true',
      'photo_license': 'cc0,cc-by,cc-by-sa',
      'per_page': '50',
      'order_by': 'votes',
    });
    final response = await client
        .get(uri, headers: const {'Accept': 'application/json'})
        .timeout(const Duration(seconds: 4));
    if (response.statusCode != 200) return const {};
    final data = jsonDecode(response.body);
    if (data is! Map<String, dynamic> || data['results'] is! List) {
      return const {};
    }
    final photos = <int, LicensedFishPhoto>{};
    for (final observation
        in (data['results'] as List).whereType<Map<String, dynamic>>()) {
      final taxon = observation['taxon'];
      final id = taxon is Map<String, dynamic> ? taxon['id'] : null;
      final candidates = observation['photos'];
      if (id is! num ||
          !ids.contains(id.toInt()) ||
          photos.containsKey(id.toInt()) ||
          candidates is! List) {
        continue;
      }
      for (final candidate in candidates) {
        final photo = parseLicensedFishPhoto(candidate);
        if (photo != null) {
          photos[id.toInt()] = photo;
          break;
        }
      }
      if (photos.length == ids.length) break;
    }
    return photos;
  }
}
