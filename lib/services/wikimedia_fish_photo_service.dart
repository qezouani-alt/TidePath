import 'dart:convert';

import 'package:http/http.dart' as http;

import 'inaturalist_photo_service.dart';

/// Looks up Commons photos linked to exact scientific names in Wikidata.
/// Only freely reusable photos with readable credit are returned.
class WikimediaFishPhotoLookup {
  const WikimediaFishPhotoLookup({required this.client});

  final http.Client client;
  static final Map<String, LicensedFishPhoto> _photoCache = {};

  Future<Map<int, LicensedFishPhoto>> findFor(
    Map<int, String> scientificNames,
  ) async {
    final names = <int, String>{
      for (final entry in scientificNames.entries)
        if (RegExp(r'^[A-Za-z][A-Za-z .-]{2,100}$').hasMatch(entry.value))
          entry.key: entry.value.trim(),
    };
    if (names.isEmpty) return const {};
    final found = <int, LicensedFishPhoto>{};
    final missing = <int, String>{};
    for (final entry in names.entries) {
      final cached = _photoCache[entry.value];
      if (cached == null) {
        missing[entry.key] = entry.value;
      } else {
        found[entry.key] = cached;
      }
    }
    if (missing.isEmpty) return found;
    try {
      final filesByName = await _wikidataFiles(missing.values.toSet());
      if (filesByName.isEmpty) return found;
      final photosByFile = await _commonsPhotos(
        filesByName.values.expand((files) => files).toSet(),
      );
      for (final entry in missing.entries) {
        for (final file in filesByName[entry.value] ?? const <String>[]) {
          final photo = photosByFile[_normalizeFile(file)];
          if (photo == null) continue;
          found[entry.key] = photo;
          _photoCache[entry.value] = photo;
          if (_photoCache.length > 200) {
            _photoCache.remove(_photoCache.keys.first);
          }
          break;
        }
      }
      return found;
    } catch (_) {
      // The fish list remains usable when the optional photo source is down.
      return found;
    }
  }

  Future<Map<String, List<String>>> _wikidataFiles(Set<String> names) async {
    final values = names.map((name) => '"$name"').join(' ');
    final query =
        'SELECT ?name ?image WHERE {'
        ' VALUES ?name { $values }'
        ' ?taxon wdt:P225 ?name; wdt:P18 ?image.'
        '}';
    final uri = Uri.https('query.wikidata.org', '/sparql', {
      'format': 'json',
      'query': query,
    });
    final response = await client
        .get(
          uri,
          headers: const {
            'Accept': 'application/sparql-results+json',
            'User-Agent': 'TidePathFishing/1.0 (fish photo lookup)',
          },
        )
        .timeout(const Duration(seconds: 5));
    if (response.statusCode != 200) return const {};
    final json = jsonDecode(response.body);
    if (json is! Map<String, dynamic>) return const {};
    final results = json['results'];
    final bindings = results is Map<String, dynamic>
        ? results['bindings']
        : null;
    if (bindings is! List) return const {};
    final files = <String, List<String>>{};
    for (final binding in bindings.whereType<Map<String, dynamic>>()) {
      final name = _binding(binding['name']);
      final image = _binding(binding['image']);
      final imageUri = image == null ? null : Uri.tryParse(image);
      if (name == null || imageUri == null || imageUri.pathSegments.isEmpty) {
        continue;
      }
      final file = imageUri.pathSegments.last;
      if (file.isNotEmpty) {
        final candidates = files.putIfAbsent(name, () => <String>[]);
        if (candidates.length < 3) {
          candidates.add(file.startsWith('File:') ? file : 'File:$file');
        }
      }
    }
    return files;
  }

  Future<Map<String, LicensedFishPhoto>> _commonsPhotos(
    Set<String> files,
  ) async {
    final photos = <String, LicensedFishPhoto>{};
    final titles = files.toList();
    for (var offset = 0; offset < titles.length; offset += 40) {
      final batch = titles.skip(offset).take(40).toList();
      final uri = Uri.https('commons.wikimedia.org', '/w/api.php', {
        'action': 'query',
        'format': 'json',
        'prop': 'imageinfo',
        'iiprop': 'url|extmetadata|mime',
        'iiextmetadatafilter': 'Artist|LicenseShortName',
        'iiurlwidth': '600',
        'titles': batch.join('|'),
      });
      http.Response response;
      try {
        response = await client
            .get(
              uri,
              headers: const {
                'Accept': 'application/json',
                'User-Agent': 'TidePathFishing/1.0 (fish photo lookup)',
              },
            )
            .timeout(const Duration(seconds: 5));
      } catch (_) {
        continue;
      }
      if (response.statusCode != 200) continue;
      Object? json;
      try {
        json = jsonDecode(response.body);
      } catch (_) {
        continue;
      }
      if (json is! Map<String, dynamic>) continue;
      final query = json['query'];
      final pages = query is Map<String, dynamic> ? query['pages'] : null;
      if (pages is! Map<String, dynamic>) continue;
      for (final page in pages.values.whereType<Map<String, dynamic>>()) {
        final title = page['title']?.toString();
        final imageInfo = page['imageinfo'];
        if (title == null || imageInfo is! List || imageInfo.isEmpty) {
          continue;
        }
        final info = imageInfo.first;
        if (info is! Map<String, dynamic>) continue;
        final mime = info['mime']?.toString();
        if (mime != 'image/jpeg' &&
            mime != 'image/png' &&
            mime != 'image/webp') {
          continue;
        }
        final metadata = info['extmetadata'];
        if (metadata is! Map<String, dynamic>) continue;
        final license = _metadata(metadata, 'LicenseShortName');
        if (license == null || !_reusable(license)) continue;
        final artist = _plainText(_metadata(metadata, 'Artist'));
        if (!_publicDomain(license) && artist.isEmpty) continue;
        final imageUrl =
            info['thumburl']?.toString() ?? info['url']?.toString();
        final sourceUrl = info['descriptionurl']?.toString();
        final imageUri = imageUrl == null ? null : Uri.tryParse(imageUrl);
        final sourceUri = sourceUrl == null ? null : Uri.tryParse(sourceUrl);
        if (imageUri == null ||
            !imageUri.isScheme('https') ||
            sourceUri == null ||
            !sourceUri.isScheme('https')) {
          continue;
        }
        photos[_normalizeFile(title)] = LicensedFishPhoto(
          url: imageUri.toString(),
          credit: artist.isEmpty ? 'Wikimedia Commons' : artist,
          license: license,
          sourceUrl: sourceUri.toString(),
        );
      }
    }
    return photos;
  }

  static String? _binding(Object? value) =>
      value is Map<String, dynamic> ? value['value']?.toString() : null;

  static String? _metadata(Map<String, dynamic> metadata, String key) {
    final value = metadata[key];
    return value is Map<String, dynamic> ? value['value']?.toString() : null;
  }

  static String _normalizeFile(String title) =>
      title.replaceAll('_', ' ').toLowerCase();

  static bool _publicDomain(String license) {
    final value = license.toUpperCase();
    return value.startsWith('CC0') ||
        value.startsWith('PUBLIC DOMAIN') ||
        value.startsWith('PD-');
  }

  static bool _reusable(String license) {
    if (_publicDomain(license)) return true;
    final value = license.toUpperCase().replaceAll('-', ' ');
    return value.startsWith('CC BY') &&
        !value.contains(' NC') &&
        !value.contains(' ND');
  }

  static String _plainText(String? html) {
    if (html == null) return '';
    return html
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('&amp;', '&')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&nbsp;', ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}
