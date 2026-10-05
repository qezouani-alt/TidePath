import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:fishing/features/conditions/conditions_scope.dart';
import 'package:fishing/models/fishing_conditions.dart';
import 'package:fishing/models/fishing_location.dart';
import 'package:fishing/services/condition_sources.dart';
import 'package:fishing/services/demo_condition_data.dart';
import 'package:fishing/services/fishing_conditions_repository.dart';
import 'package:fishing/services/location_service.dart';
import 'package:fishing/services/marine_service.dart';
import 'package:fishing/services/weather_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:latlong2/latlong.dart';

const _location = FishingLocation(
  label: 'Agadir, Morocco',
  point: LatLng(30.4278, -9.5981),
);

void main() {
  test(
    'device permission and reverse geocoding return a readable location',
    () async {
      final device = _FakePosition(
        LocationPermission.denied,
        LocationPermission.whileInUse,
      );
      final service = LocationService(
        position: device,
        places: _FakePlaces('Agadir, Morocco'),
      );
      final result = await service.detectDeviceLocation();
      expect(device.requested, isTrue);
      expect(result.label, 'Agadir, Morocco');
      expect(result.point.latitude, 30.4278);
      expect(result.point.longitude, -9.5981);
      expect(result.fromDevice, isTrue);
    },
  );

  test('denied device permission does not read coordinates', () async {
    final device = _FakePosition(
      LocationPermission.denied,
      LocationPermission.denied,
    );
    final service = LocationService(
      position: device,
      places: _FakePlaces(null),
    );
    await expectLater(
      service.detectDeviceLocation(),
      throwsA(isA<LocationServiceException>()),
    );
    expect(device.readPosition, isFalse);
  });

  test(
    'geocoder failure keeps GPS coordinates with a readable label',
    () async {
      final service = LocationService(
        position: _FakePosition(
          LocationPermission.whileInUse,
          LocationPermission.whileInUse,
        ),
        places: _FakePlaces(null),
      );
      final result = await service.detectDeviceLocation();
      expect(result.label, 'Current location');
      expect(result.coordinates, '30.4278, -9.5981');
      expect(result.fromDevice, isTrue);
    },
  );

  test('search keeps the entered place when reverse geocoding fails', () async {
    final service = LocationService(places: _FakePlaces(null));
    final result = await service.search('Valencia, Spain');
    expect(result.label, 'Valencia, Spain');
  });

  test('coordinate labels do not become spot section titles', () {
    const location = FishingLocation(
      label: '33.8947, -6.9050',
      point: LatLng(33.8947, -6.9050),
    );
    expect(location.shortName, 'this location');
  });

  test('Open-Meteo adapters parse typed weather and marine values', () async {
    final now = DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000;
    final client = OpenMeteoClient(
      client: MockClient((request) async {
        expect(request.url.queryParameters['latitude'], '30.4278');
        expect(request.url.queryParameters['timeformat'], 'unixtime');
        expect(request.url.queryParameters['forecast_days'], '7');
        if (request.url.path.endsWith('/marine')) {
          return http.Response(
            jsonEncode({
              'latitude': 30.45,
              'longitude': -9.62,
              'current': {
                'wave_height': 1.1,
                'wave_direction': 300,
                'wave_period': 8,
                'swell_wave_height': .7,
                'swell_wave_direction': 270,
                'swell_wave_period': 10,
                'sea_surface_temperature': 19.5,
                'sea_level_height_msl': .2,
                'ocean_current_velocity': .8,
                'ocean_current_direction': 135,
              },
              'hourly': {
                'time': [now, now + 3600],
                'wave_height': [1.1, 1.2],
                'sea_level_height_msl': [.2, .3],
                'wave_period': [8, 9],
                'swell_wave_height': [.7, .8],
              },
            }),
            200,
          );
        }
        return http.Response(
          jsonEncode({
            'utc_offset_seconds': 3600,
            'current': {
              'time': now,
              'temperature_2m': 22,
              'apparent_temperature': 23,
              'weather_code': 2,
              'wind_speed_10m': 14,
              'wind_direction_10m': 315,
              'wind_gusts_10m': 21,
              'precipitation': 0,
              'precipitation_probability': 5,
              'cloud_cover': 18,
              'pressure_msl': 1018,
              'surface_pressure': 1013,
              'relative_humidity_2m': 68,
              'uv_index': 5,
              'visibility': 16000,
            },
            'hourly': {
              'time': [now, now + 3600],
              'temperature_2m': [22, 23],
              'weather_code': [2, 3],
              'wind_speed_10m': [14, 16],
              'wind_direction_10m': [315, 135],
              'wind_gusts_10m': [21, 25],
              'relative_humidity_2m': [68, 64],
              'surface_pressure': [1012, 1013],
              'precipitation': [0, .2],
              'precipitation_probability': [5, 10],
              'pressure_msl': [1017, 1018],
            },
            'daily': {
              'sunrise': [now],
              'sunset': [now + 43200],
              'weather_code': [2],
            },
          }),
          200,
        );
      }),
    );
    final weather = await WeatherService(client).fetch(_location);
    final marine = await MarineService(client).fetch(_location);
    expect(weather.windKmh, 14);
    expect(weather.utcOffsetSeconds, 3600);
    expect(weather.hours, hasLength(2));
    expect(weather.pressureHpa, 1013);
    expect(weather.hours[1].windDegrees, 135);
    expect(weather.hours[1].gustKmh, 25);
    expect(marine.swellM, .7);
    expect(marine.hours.first.seaLevelM, .2);
    expect(marine.hours[1].wavePeriodSeconds, 9);
    expect(marine.hours[1].swellM, .8);
    client.close();
  });

  test(
    'weather failure preserves live marine and sample weather and tide',
    () async {
      final demo = DemoConditionData.marine();
      final liveMarine = MarineModel(
        waveM: .6,
        wavePeriodSeconds: demo.wavePeriodSeconds,
        waveDegrees: demo.waveDegrees,
        swellM: demo.swellM,
        swellPeriodSeconds: demo.swellPeriodSeconds,
        swellDegrees: demo.swellDegrees,
        waterC: demo.waterC,
        seaLevelM: null,
        oceanCurrentKmh: null,
        oceanCurrentDegrees: null,
        hours: demo.hours,
        origin: DataOrigin.live,
      );
      final repository = LiveFishingConditionsRepository(
        weather: _WeatherSource((_) async => throw Exception('offline')),
        marine: _MarineSource((_) async => liveMarine),
        tide: _TideSource((_, _) async => throw Exception('unavailable')),
      );
      addTearDown(repository.dispose);
      final conditions = await repository.load(_location);
      expect(conditions.weather.origin, DataOrigin.sample);
      expect(conditions.marine.origin, DataOrigin.live);
      expect(conditions.tide.origin, DataOrigin.unavailable);
      expect(conditions.marine.waveM, .6);
      expect(conditions.sourceLabel, contains('sample weather'));
    },
  );

  test(
    'condition controller reloads when the selected place changes',
    () async {
      final location = FishingLocationController();
      final repository = _RecordingRepository();
      final controller = FishingConditionsController(
        location: location,
        repository: repository,
      );
      const tokyo = FishingLocation(
        label: 'Tokyo, Japan',
        point: LatLng(35.6762, 139.6503),
      );
      location.select(tokyo);
      await controller.refresh();
      expect(controller.current.location.label, 'Tokyo, Japan');
      expect(repository.lastLocation?.point.latitude, 35.6762);
      controller.dispose();
      location.dispose();
    },
  );

  test('all failed sources restore the complete sample forecast', () async {
    final repository = LiveFishingConditionsRepository(
      weather: _WeatherSource((_) async => throw Exception('weather down')),
      marine: _MarineSource((_) async => throw Exception('marine down')),
    );
    addTearDown(repository.dispose);
    final conditions = await repository.load(_location);
    expect(conditions.isAllSample, isTrue);
    expect(conditions.score, 86);
    expect(conditions.hourly, isNotEmpty);
  });

  test(
    'repository reuses fresh values and refresh bypasses the cache',
    () async {
      var weatherCalls = 0;
      var marineCalls = 0;
      final repository = LiveFishingConditionsRepository(
        weather: _WeatherSource((_) async {
          weatherCalls++;
          return DemoConditionData.weather();
        }),
        marine: _MarineSource((_) async {
          marineCalls++;
          return DemoConditionData.marine();
        }),
      );
      addTearDown(repository.dispose);
      await repository.load(_location);
      await repository.load(_location);
      expect(weatherCalls, 1);
      expect(marineCalls, 1);
      await repository.load(_location, forceRefresh: true);
      expect(weatherCalls, 2);
      expect(marineCalls, 2);
    },
  );

  test('failed refresh preserves the previous marine snapshot', () async {
    var fail = false;
    final original = DemoConditionData.marine();
    final marine = MarineModel(
      waveM: .45,
      wavePeriodSeconds: original.wavePeriodSeconds,
      waveDegrees: original.waveDegrees,
      swellM: original.swellM,
      swellPeriodSeconds: original.swellPeriodSeconds,
      swellDegrees: original.swellDegrees,
      waterC: original.waterC,
      seaLevelM: original.seaLevelM,
      oceanCurrentKmh: original.oceanCurrentKmh,
      oceanCurrentDegrees: original.oceanCurrentDegrees,
      hours: original.hours,
      origin: DataOrigin.live,
    );
    final repository = LiveFishingConditionsRepository(
      weather: _WeatherSource((_) async {
        if (fail) throw Exception('weather offline');
        return DemoConditionData.weather();
      }),
      marine: _MarineSource((_) async {
        if (fail) throw Exception('marine offline');
        return marine;
      }),
    );
    addTearDown(repository.dispose);
    await repository.load(_location);
    fail = true;
    final preserved = await repository.load(_location, forceRefresh: true);
    expect(preserved.marine.waveM, .45);
    expect(preserved.marine.origin, DataOrigin.live);
    expect(preserved.updateFailed, isTrue);
    expect(preserved.sourceLabel, contains('Unable to update conditions.'));
  });

  test('estimated tide uses sea level turning points', () async {
    final start = DateTime.now().toUtc().subtract(const Duration(hours: 2));
    final levels = [0.0, 1, 2, 1, 0, -1, 0, 1, 2, 1];
    final demo = DemoConditionData.marine();
    final marine = MarineModel(
      waveM: demo.waveM,
      wavePeriodSeconds: demo.wavePeriodSeconds,
      waveDegrees: demo.waveDegrees,
      swellM: demo.swellM,
      swellPeriodSeconds: demo.swellPeriodSeconds,
      swellDegrees: demo.swellDegrees,
      waterC: demo.waterC,
      seaLevelM: null,
      oceanCurrentKmh: null,
      oceanCurrentDegrees: null,
      hours: List.generate(
        levels.length,
        (i) =>
            MarineHour(start.add(Duration(hours: i)), 1, levels[i].toDouble()),
      ),
      origin: DataOrigin.live,
    );
    final tide = await const EstimatedTideSource().fetch(_location, marine);
    expect(tide.phase, 'Falling');
    expect(tide.origin, DataOrigin.live);
    expect(tide.nextUtc, tide.lowUtc);
  });
}

class _FakePosition implements DevicePositionSource {
  _FakePosition(this.initialPermission, this.requestedPermission);
  final LocationPermission initialPermission, requestedPermission;
  bool requested = false;
  bool readPosition = false;

  @override
  Future<bool> isEnabled() async => true;
  @override
  Future<LocationPermission> checkPermission() async => initialPermission;
  @override
  Future<LocationPermission> requestPermission() async {
    requested = true;
    return requestedPermission;
  }

  @override
  Future<LatLng> currentPoint() async {
    readPosition = true;
    return const LatLng(30.4278, -9.5981);
  }
}

class _FakePlaces implements PlaceNameSource {
  _FakePlaces(this.label);
  final String? label;
  @override
  Future<LatLng?> search(String query) async => const LatLng(30.4278, -9.5981);
  @override
  Future<String?> describe(LatLng point) async => label;
}

class _WeatherSource implements WeatherSource {
  _WeatherSource(this.load);
  final Future<WeatherModel> Function(FishingLocation) load;
  @override
  Future<WeatherModel> fetch(FishingLocation location) => load(location);
}

class _MarineSource implements MarineSource {
  _MarineSource(this.load);
  final Future<MarineModel> Function(FishingLocation) load;
  @override
  Future<MarineModel> fetch(FishingLocation location) => load(location);
}

class _TideSource implements TideSource {
  _TideSource(this.load);
  final Future<TideConditions> Function(FishingLocation, MarineModel) load;
  @override
  Future<TideConditions> fetch(FishingLocation location, MarineModel marine) =>
      load(location, marine);
}

class _RecordingRepository implements FishingConditionsRepository {
  FishingLocation? lastLocation;

  @override
  Future<FishingConditions> load(
    FishingLocation location, {
    bool forceRefresh = false,
  }) async {
    lastLocation = location;
    return DemoConditionData.forLocation(location);
  }

  @override
  void dispose() {}
}
