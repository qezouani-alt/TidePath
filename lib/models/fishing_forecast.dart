import 'fish_activity_level.dart';

class FishingScoreResult {
  const FishingScoreResult({
    required this.score,
    required this.level,
    required this.reasons,
  });

  final int score;
  final FishActivityLevel level;
  final List<String> reasons;

  String get label => level.label;
  int get activeFishCount => level.activeFish;
}

class BestFishingWindow {
  const BestFishingWindow(this.label, this.startMinute, this.endMinute);

  final String label;
  final int startMinute, endMinute;

  bool contains(DateTime localTime) {
    final minute = localTime.hour * 60 + localTime.minute;
    return minute >= startMinute && minute <= endMinute;
  }

  bool overlapsHour(int hour) =>
      hour * 60 < endMinute && (hour + 1) * 60 > startMinute;

  String get clockRange => '${_clock(startMinute)} – ${_clock(endMinute)}';

  static String _clock(int minute) =>
      '${(minute ~/ 60).toString().padLeft(2, '0')}:${(minute % 60).toString().padLeft(2, '0')}';
}

class FishingForecastHour {
  const FishingForecastHour({
    required this.timeUtc,
    required this.localTime,
    required this.weatherCode,
    required this.temperatureC,
    required this.feelsLikeC,
    required this.precipitationMm,
    required this.rainChance,
    required this.cloudCover,
    required this.windKmh,
    required this.gustKmh,
    required this.windDegrees,
    required this.waveM,
    required this.wavePeriodSeconds,
    required this.waveDegrees,
    required this.swellM,
    required this.swellDegrees,
    required this.humidity,
    required this.pressureHpa,
    required this.pressureTrend,
    required this.tideHeightM,
    required this.tidePhase,
    required this.waterC,
    required this.score,
    required this.isCurrent,
    required this.isBestHour,
    required this.usesSampleWeather,
    required this.usesSampleMarine,
    required this.usesSampleTide,
  });

  final DateTime timeUtc, localTime;
  final int weatherCode,
      windDegrees,
      wavePeriodSeconds,
      waveDegrees,
      swellDegrees,
      rainChance,
      cloudCover;
  final int? humidity;
  final double temperatureC,
      feelsLikeC,
      precipitationMm,
      windKmh,
      gustKmh,
      waveM,
      swellM;
  final double pressureHpa, waterC;
  final double? tideHeightM;
  final String pressureTrend, tidePhase;
  final FishingScoreResult score;
  final bool isCurrent,
      isBestHour,
      usesSampleWeather,
      usesSampleMarine,
      usesSampleTide;
}

class FishingForecastDay {
  const FishingForecastDay({
    required this.dateLocal,
    required this.weatherCode,
    required this.score,
    required this.hours,
    required this.bestWindows,
  });

  final DateTime dateLocal;
  final int weatherCode;
  final FishingScoreResult score;
  final List<FishingForecastHour> hours;
  final List<BestFishingWindow> bestWindows;
}
