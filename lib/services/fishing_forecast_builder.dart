import '../models/fishing_conditions.dart';
import '../models/fishing_forecast.dart';
import 'fishing_score_service.dart';

/// Combines the shared cached weather and marine response into selectable days
/// and hours. Building this view model never starts a network request.
class FishingForecastBuilder {
  const FishingForecastBuilder({
    this.scoreService = const FishingScoreService(),
  });

  final FishingScoreService scoreService;

  List<FishingForecastDay> build(
    FishingConditions conditions, {
    DateTime? nowUtc,
  }) {
    final now = (nowUtc ?? DateTime.now()).toUtc();
    final localNow = conditions.localTime(now);
    final today = DateTime.utc(localNow.year, localNow.month, localNow.day);
    final offset = Duration(seconds: conditions.weather.utcOffsetSeconds);
    final weatherHours = {
      for (final hour in conditions.weather.hours)
        hour.timeUtc.millisecondsSinceEpoch: hour,
    };
    final marineHours = {
      for (final hour in conditions.marine.hours)
        hour.timeUtc.millisecondsSinceEpoch: hour,
    };
    final weatherDays = {
      for (final day in conditions.weather.days)
        day.dateLocal.millisecondsSinceEpoch: day,
    };

    return List.generate(7, (dayIndex) {
      final date = today.add(Duration(days: dayIndex));
      final sourceDay = weatherDays[date.millisecondsSinceEpoch];
      final sunrise =
          sourceDay?.sunriseUtc ??
          conditions.weather.sunriseUtc.add(Duration(days: dayIndex));
      final sunset =
          sourceDay?.sunsetUtc ??
          conditions.weather.sunsetUtc.add(Duration(days: dayIndex));
      final sunriseLocal = conditions.localTime(sunrise);
      final sunsetLocal = conditions.localTime(sunset);
      int minuteOfDay(DateTime time) => time.hour * 60 + time.minute;
      final windows = <BestFishingWindow>[
        BestFishingWindow(
          'Around sunrise',
          (minuteOfDay(sunriseLocal) - 60).clamp(0, 1439),
          (minuteOfDay(sunriseLocal) + 60).clamp(0, 1439),
        ),
        BestFishingWindow(
          'Around sunset',
          (minuteOfDay(sunsetLocal) - 60).clamp(0, 1439),
          (minuteOfDay(sunsetLocal) + 60).clamp(0, 1439),
        ),
      ];
      final hours = List.generate(24, (hourIndex) {
        final localTime = date.add(Duration(hours: hourIndex));
        final timeUtc = localTime.subtract(offset);
        final key = timeUtc.millisecondsSinceEpoch;
        final weather = weatherHours[key];
        final marine = marineHours[key];
        final previousWeather =
            weatherHours[timeUtc
                .subtract(const Duration(hours: 1))
                .millisecondsSinceEpoch];
        final previousMarine =
            marineHours[timeUtc
                .subtract(const Duration(hours: 1))
                .millisecondsSinceEpoch];
        final isCurrent = dayIndex == 0 && hourIndex == localNow.hour;
        final temperatureC = isCurrent
            ? conditions.weather.airC
            : weather?.temperatureC ?? conditions.weather.airC;
        final windKmh = isCurrent
            ? conditions.weather.windKmh
            : weather?.windKmh ?? conditions.weather.windKmh;
        final waveM = isCurrent
            ? conditions.marine.waveM
            : marine?.waveM ?? conditions.marine.waveM;
        final wavePeriod = isCurrent
            ? conditions.marine.wavePeriodSeconds
            : marine?.wavePeriodSeconds ?? conditions.marine.wavePeriodSeconds;
        final modeledSeaLevel = isCurrent
            ? conditions.marine.seaLevelM ?? marine?.seaLevelM
            : marine?.seaLevelM;
        final usesSampleTide =
            modeledSeaLevel == null ||
            conditions.marine.origin == DataOrigin.sample ||
            marine == null;
        final seaLevel = usesSampleTide ? null : modeledSeaLevel;
        final pressure = isCurrent
            ? conditions.weather.pressureHpa.toDouble()
            : weather?.pressureHpa ?? conditions.weather.pressureHpa.toDouble();
        final pressureChange = isCurrent
            ? conditions.weather.pressureChangeHpa
            : weather?.pressureHpa == null ||
                  previousWeather?.pressureHpa == null
            ? null
            : weather!.pressureHpa! - previousWeather!.pressureHpa!;
        final tidePhase = usesSampleTide
            ? 'Unavailable'
            : isCurrent && conditions.tide.origin == DataOrigin.live
            ? conditions.tide.phase
            : _tidePhase(marine, previousMarine, conditions.tide.phase);
        final score = scoreService.forHour(
          FishingScoreInput(
            timeUtc: timeUtc,
            windKmh: windKmh,
            gustKmh: isCurrent
                ? conditions.weather.gustKmh
                : weather?.gustKmh ?? conditions.weather.gustKmh,
            rainChance: isCurrent
                ? conditions.weather.rainChance
                : weather?.rainChance ?? conditions.weather.rainChance,
            waveM: waveM,
            tideHeightM: seaLevel,
            sunriseUtc: sunrise,
            sunsetUtc: sunset,
            pressureHpa: pressure,
            temperatureC: temperatureC,
            wavePeriodSeconds: wavePeriod,
          ),
        );
        return FishingForecastHour(
          timeUtc: timeUtc,
          localTime: localTime,
          weatherCode: isCurrent
              ? conditions.weather.weatherCode
              : weather?.weatherCode ??
                    sourceDay?.weatherCode ??
                    conditions.weather.weatherCode,
          temperatureC: temperatureC,
          feelsLikeC: isCurrent
              ? conditions.weather.feelsLikeC
              : weather?.feelsLikeC ?? conditions.weather.feelsLikeC,
          precipitationMm: isCurrent
              ? conditions.weather.precipitationMm
              : weather?.precipitationMm ?? conditions.weather.precipitationMm,
          rainChance: isCurrent
              ? conditions.weather.rainChance
              : weather?.rainChance ?? conditions.weather.rainChance,
          cloudCover: isCurrent
              ? conditions.weather.cloudCover
              : weather?.cloudCover ?? conditions.weather.cloudCover,
          windKmh: windKmh,
          gustKmh: isCurrent
              ? conditions.weather.gustKmh
              : weather?.gustKmh ?? conditions.weather.gustKmh,
          windDegrees: isCurrent
              ? conditions.weather.windDegrees
              : weather?.windDegrees ?? conditions.weather.windDegrees,
          waveM: waveM,
          wavePeriodSeconds: wavePeriod,
          waveDegrees: isCurrent
              ? conditions.marine.waveDegrees
              : marine?.waveDegrees ?? conditions.marine.waveDegrees,
          swellM: isCurrent
              ? conditions.marine.swellM
              : marine?.swellM ?? conditions.marine.swellM,
          swellDegrees: isCurrent
              ? conditions.marine.swellDegrees
              : marine?.swellDegrees ?? conditions.marine.swellDegrees,
          humidity: isCurrent
              ? conditions.weather.humidity
              : weather?.humidity ?? conditions.weather.humidity,
          pressureHpa: pressure,
          pressureTrend: _pressureTrend(pressureChange),
          tideHeightM: seaLevel,
          tidePhase: tidePhase,
          waterC: isCurrent
              ? conditions.marine.waterC
              : marine?.waterC ?? conditions.marine.waterC,
          score: score,
          isCurrent: isCurrent,
          isBestHour: windows.any((window) => window.overlapsHour(hourIndex)),
          usesSampleWeather:
              conditions.weather.origin == DataOrigin.sample || weather == null,
          usesSampleMarine:
              conditions.marine.origin == DataOrigin.sample || marine == null,
          usesSampleTide: usesSampleTide,
        );
      });
      return FishingForecastDay(
        dateLocal: date,
        weatherCode:
            sourceDay?.weatherCode ??
            conditions.weather.dailyWeatherCodes[dayIndex <
                    conditions.weather.dailyWeatherCodes.length
                ? dayIndex
                : 0],
        score: scoreService.forDay(hours.map((hour) => hour.score).toList()),
        hours: hours,
        bestWindows: windows,
      );
    });
  }

  static String _pressureTrend(double? change) {
    if (change == null || change.abs() < .2) return 'Stable';
    return change > 0 ? 'Rising' : 'Falling';
  }

  static String _tidePhase(
    MarineHour? current,
    MarineHour? previous,
    String fallback,
  ) {
    final level = current?.seaLevelM;
    final before = previous?.seaLevelM;
    if (level == null || before == null) return fallback;
    return level >= before ? 'Rising' : 'Falling';
  }
}
