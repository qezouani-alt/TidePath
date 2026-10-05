import 'dart:math' as math;

import '../models/fishing_conditions.dart';
import '../models/fishing_location.dart';

abstract final class DemoConditionData {
  static DateTime get _hour {
    final now = DateTime.now().toUtc();
    return DateTime.utc(now.year, now.month, now.day);
  }

  static WeatherModel weather() => WeatherModel(
    airC: 22,
    feelsLikeC: 23,
    weatherCode: 1,
    windKmh: 14,
    gustKmh: 21,
    windDegrees: 315,
    precipitationMm: 0,
    rainChance: 8,
    cloudCover: 18,
    pressureHpa: 1018,
    humidity: 68,
    uvIndex: 5,
    visibilityKm: 16,
    pressureChangeHpa: .4,
    sunriseUtc: DateTime.utc(_hour.year, _hour.month, _hour.day, 7, 24),
    sunsetUtc: DateTime.utc(_hour.year, _hour.month, _hour.day, 19, 33),
    utcOffsetSeconds: 0,
    hours: List.generate(168, (i) {
      final hour = i % 24;
      final warmth = math.sin((hour - 6) * math.pi / 12);
      return WeatherHour(
        _hour.add(Duration(hours: i)),
        10 + (hour % 5).toDouble(),
        hour >= 15 && hour <= 18 ? 22 : 8,
        temperatureC: 20 + 4 * warmth,
        weatherCode: i ~/ 24 == 3 ? 3 : 1,
        precipitationMm: 0,
        feelsLikeC: 20 + 4 * warmth,
        gustKmh: 16 + (hour % 5).toDouble(),
        windDegrees: 315,
        humidity: 68,
        pressureHpa: 1018,
        cloudCover: i ~/ 24 == 3 ? 65 : 18,
      );
    }),
    dailyWeatherCodes: const [1, 1, 1, 3, 1, 1, 2],
    days: List.generate(7, (i) {
      final date = _hour.add(Duration(days: i));
      return WeatherDay(
        dateLocal: date,
        weatherCode: const [1, 1, 1, 3, 1, 1, 2][i],
        sunriseUtc: DateTime.utc(date.year, date.month, date.day, 7, 24),
        sunsetUtc: DateTime.utc(date.year, date.month, date.day, 19, 33),
      );
    }),
    origin: DataOrigin.sample,
  );

  static MarineModel marine() => MarineModel(
    waveM: 1.2,
    wavePeriodSeconds: 8,
    waveDegrees: 315,
    swellM: .8,
    swellPeriodSeconds: 11,
    swellDegrees: 270,
    waterC: 19,
    seaLevelM: null,
    oceanCurrentKmh: null,
    oceanCurrentDegrees: null,
    hours: List.generate(168, (i) {
      final level = .75 * math.sin((i - 2) * math.pi / 6);
      return MarineHour(
        _hour.add(Duration(hours: i)),
        1.0 + .2 * math.sin(i * math.pi / 12),
        level,
        waveDegrees: 315,
        wavePeriodSeconds: 8,
        swellM: .8,
        swellDegrees: 270,
        swellPeriodSeconds: 11,
        waterC: 19,
      );
    }),
    origin: DataOrigin.sample,
  );

  static TideConditions tide() {
    final today = _hour;
    return TideConditions(
      phase: 'Rising',
      highUtc: DateTime.utc(today.year, today.month, today.day, 10, 42),
      lowUtc: DateTime.utc(today.year, today.month, today.day, 16, 58),
      nextUtc: DateTime.utc(today.year, today.month, today.day, 22, 49),
      origin: DataOrigin.sample,
    );
  }

  static FishingConditions forLocation(FishingLocation location) =>
      FishingConditions(
        location: location,
        weather: weather(),
        marine: marine(),
        tide: tide(),
        hourly: List.generate(
          168,
          (i) =>
              FishingOutlook(_hour.add(Duration(hours: i)), outlookScoreAt(i)),
        ),
      );

  static int outlookScoreAt(int index) =>
      const [86, 88, 75, 62, 48, 82, 76, 91, 64, 88][index % 10];
}
