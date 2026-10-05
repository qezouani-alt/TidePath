import 'package:geocoding/geocoding.dart' as geo;
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../models/fishing_location.dart';

abstract class DevicePositionSource {
  Future<bool> isEnabled();
  Future<LocationPermission> checkPermission();
  Future<LocationPermission> requestPermission();
  Future<LatLng> currentPoint();
}

class GeolocatorPositionSource implements DevicePositionSource {
  const GeolocatorPositionSource();

  @override
  Future<bool> isEnabled() => Geolocator.isLocationServiceEnabled();

  @override
  Future<LocationPermission> checkPermission() => Geolocator.checkPermission();

  @override
  Future<LocationPermission> requestPermission() =>
      Geolocator.requestPermission();

  @override
  Future<LatLng> currentPoint() async {
    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 15),
      ),
    );
    return LatLng(position.latitude, position.longitude);
  }
}

abstract class PlaceNameSource {
  Future<LatLng?> search(String query);
  Future<String?> describe(LatLng point);
}

class PlatformPlaceNameSource implements PlaceNameSource {
  PlatformPlaceNameSource({geo.Geocoding? geocoding})
    : _providedGeocoding = geocoding;

  final geo.Geocoding? _providedGeocoding;
  late final geo.Geocoding _platformGeocoding = geo.Geocoding();
  geo.Geocoding get _geocoding => _providedGeocoding ?? _platformGeocoding;

  @override
  Future<LatLng?> search(String query) async {
    final results = await _geocoding.locationFromAddress(query);
    if (results.isEmpty) return null;
    return LatLng(results.first.latitude, results.first.longitude);
  }

  @override
  Future<String?> describe(LatLng point) async {
    final places = await _geocoding.placemarkFromCoordinates(
      point.latitude,
      point.longitude,
    );
    if (places.isEmpty) return null;
    final place = places.first;
    final city =
        [place.locality, place.subAdministrativeArea, place.administrativeArea]
            .whereType<String>()
            .firstWhere((part) => part.trim().isNotEmpty, orElse: () => '');
    final country = place.country?.trim() ?? '';
    final label = [
      if (city.isNotEmpty) city,
      if (country.isNotEmpty && country != city) country,
    ].join(', ');
    return label.isEmpty ? null : label;
  }
}

class LocationService {
  LocationService({DevicePositionSource? position, PlaceNameSource? places})
    : _position = position ?? const GeolocatorPositionSource(),
      _places = places ?? PlatformPlaceNameSource();

  final DevicePositionSource _position;
  final PlaceNameSource _places;

  Future<FishingLocation> detectDeviceLocation() async {
    if (!await _position.isEnabled()) {
      throw const LocationServiceException(
        'Location services are off. Turn them on and try again.',
      );
    }
    var permission = await _position.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await _position.requestPermission();
    }
    if (permission == LocationPermission.denied) {
      throw const LocationServiceException(
        'Location permission was denied. You can still search or pick on the map.',
      );
    }
    if (permission == LocationPermission.deniedForever) {
      throw const LocationServiceException(
        'Location access is blocked in settings. You can still pick on the map.',
      );
    }
    try {
      return await describePoint(
        await _position.currentPoint(),
        fromDevice: true,
      );
    } catch (error) {
      if (error is LocationServiceException) rethrow;
      throw const LocationServiceException(
        'Could not detect your location. Try the map instead.',
      );
    }
  }

  Future<FishingLocation> search(String query) async {
    final normalized = query.trim();
    if (normalized.isEmpty) {
      throw const LocationServiceException('Enter a city, region, or address.');
    }
    try {
      final point = await _places.search(normalized);
      if (point == null) {
        throw const LocationServiceException(
          'No location found. Try a city and country.',
        );
      }
      final resolved = await describePoint(point);
      return resolved.label == 'Selected location'
          ? FishingLocation(label: normalized, point: point)
          : resolved;
    } on LocationServiceException {
      rethrow;
    } catch (_) {
      throw const LocationServiceException(
        'Could not search that place. Check your connection and try again.',
      );
    }
  }

  Future<FishingLocation> describePoint(
    LatLng point, {
    bool fromDevice = false,
  }) async {
    String? label;
    try {
      label = await _places.describe(point).timeout(const Duration(seconds: 5));
    } catch (_) {
      // Coordinates remain usable when the platform geocoder is unavailable.
    }
    return FishingLocation(
      label: label == null || label.trim().isEmpty
          ? (fromDevice ? 'Current location' : 'Selected location')
          : label,
      point: point,
      fromDevice: fromDevice,
    );
  }
}

class LocationServiceException implements Exception {
  const LocationServiceException(this.message);
  final String message;

  @override
  String toString() => message;
}
