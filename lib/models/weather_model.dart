import 'data_origin.dart';

class WeatherHour {
  const WeatherHour(
    this.timeUtc,
    this.windKmh,
    this.rainChance, {
    required this.temperatureC,
    required this.weatherCode,
    required this.precipitationMm,
    this.feelsLikeC,
    this.gustKmh,
    this.windDegrees,
    this.humidity,
    this.pressureHpa,
    this.cloudCover,
  });

  final DateTime timeUtc;
  final double windKmh, temperatureC, precipitationMm;
  final int rainChance, weatherCode;
  final double? feelsLikeC, gustKmh, pressureHpa;
  final int? windDegrees, humidity, cloudCover;
}

class WeatherDay {
  const WeatherDay({
    required this.dateLocal,
    required this.weatherCode,
    required this.sunriseUtc,
    required this.sunsetUtc,
  });

  final DateTime dateLocal, sunriseUtc, sunsetUtc;
  final int weatherCode;
}

class WeatherModel {
  const WeatherModel({
    required this.airC,
    required this.feelsLikeC,
    required this.weatherCode,
    required this.windKmh,
    required this.gustKmh,
    required this.windDegrees,
    required this.precipitationMm,
    required this.rainChance,
    required this.cloudCover,
    required this.pressureHpa,
    required this.humidity,
    required this.uvIndex,
    required this.visibilityKm,
    required this.pressureChangeHpa,
    required this.sunriseUtc,
    required this.sunsetUtc,
    required this.hours,
    required this.dailyWeatherCodes,
    this.days = const [],
    required this.utcOffsetSeconds,
    required this.origin,
  });

  final double airC, feelsLikeC, windKmh, gustKmh, precipitationMm;
  final int weatherCode, windDegrees, rainChance, cloudCover, pressureHpa;
  final int? humidity;
  final double? uvIndex, visibilityKm, pressureChangeHpa;
  final int utcOffsetSeconds;
  final DateTime sunriseUtc, sunsetUtc;
  final List<WeatherHour> hours;
  final List<int> dailyWeatherCodes;
  final List<WeatherDay> days;
  final DataOrigin origin;

  String get condition => descriptionFor(weatherCode);

  static String descriptionFor(int code) {
    if (code == 0) return 'Clear';
    if (code <= 2) return 'Partly cloudy';
    if (code == 3) return 'Cloudy';
    if (code == 45 || code == 48) return 'Fog';
    if (code >= 95) return 'Thunderstorm';
    if (code >= 71 && code <= 86) return 'Snow';
    if (code >= 51 && code <= 67 || code >= 80 && code <= 82) return 'Rain';
    return 'Mixed weather';
  }
}
