import 'package:fishing/models/fishing_conditions.dart';
import 'package:fishing/models/fishing_location.dart';
import 'package:fishing/services/demo_condition_data.dart';

/// Test-only forecast fixture. No production screen reads this data.
FishingConditions liveConditionsFixture(FishingLocation location) {
  final fixture = DemoConditionData.forLocation(location);
  final weather = fixture.weather;
  final marine = fixture.marine;
  final tide = fixture.tide;
  return FishingConditions(
    location: location,
    weather: WeatherModel(
      airC: weather.airC,
      feelsLikeC: weather.feelsLikeC,
      weatherCode: weather.weatherCode,
      windKmh: weather.windKmh,
      gustKmh: weather.gustKmh,
      windDegrees: weather.windDegrees,
      precipitationMm: weather.precipitationMm,
      rainChance: weather.rainChance,
      cloudCover: weather.cloudCover,
      pressureHpa: weather.pressureHpa,
      humidity: weather.humidity,
      uvIndex: weather.uvIndex,
      visibilityKm: weather.visibilityKm,
      pressureChangeHpa: weather.pressureChangeHpa,
      sunriseUtc: weather.sunriseUtc,
      sunsetUtc: weather.sunsetUtc,
      hours: weather.hours,
      dailyWeatherCodes: weather.dailyWeatherCodes,
      days: weather.days,
      utcOffsetSeconds: weather.utcOffsetSeconds,
      origin: DataOrigin.live,
    ),
    marine: MarineModel(
      waveM: marine.waveM,
      wavePeriodSeconds: marine.wavePeriodSeconds,
      waveDegrees: marine.waveDegrees,
      swellM: marine.swellM,
      swellPeriodSeconds: marine.swellPeriodSeconds,
      swellDegrees: marine.swellDegrees,
      waterC: marine.waterC,
      seaLevelM: marine.seaLevelM,
      oceanCurrentKmh: marine.oceanCurrentKmh,
      oceanCurrentDegrees: marine.oceanCurrentDegrees,
      hours: marine.hours,
      origin: DataOrigin.live,
    ),
    tide: TideConditions(
      phase: tide.phase,
      highUtc: tide.highUtc,
      lowUtc: tide.lowUtc,
      nextUtc: tide.nextUtc,
      origin: DataOrigin.live,
    ),
    hourly: fixture.hourly,
  );
}
