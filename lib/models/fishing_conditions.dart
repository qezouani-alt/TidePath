import 'data_origin.dart';
import 'fishing_location.dart';
import 'marine_model.dart';
import 'weather_model.dart';
import '../utils/wind_direction.dart';

export 'data_origin.dart';
export 'marine_model.dart';
export 'weather_model.dart';

class TideConditions {
  const TideConditions({
    required this.phase,
    required this.highUtc,
    required this.lowUtc,
    required this.nextUtc,
    required this.origin,
  });
  final String phase;
  final DateTime? highUtc, lowUtc, nextUtc;
  final DataOrigin origin;
}

class FishingOutlook {
  const FishingOutlook(this.timeUtc, this.score);
  final DateTime timeUtc;
  final int score;
}

class FishingConditions {
  const FishingConditions({
    required this.location,
    required this.weather,
    required this.marine,
    required this.tide,
    required this.hourly,
    this.updateFailed = false,
  });
  final FishingLocation location;
  final WeatherModel weather;
  final MarineModel marine;
  final TideConditions tide;
  final List<FishingOutlook> hourly;
  final bool updateFailed;

  FishingConditions withUpdateFailed(bool failed) => FishingConditions(
    location: location,
    weather: weather,
    marine: marine,
    tide: tide,
    hourly: hourly,
    updateFailed: failed,
  );

  List<WeatherHour> get upcomingWeatherHours => weather.hours
      .where(
        (hour) => !hour.timeUtc.isBefore(
          DateTime.now().toUtc().subtract(const Duration(hours: 1)),
        ),
      )
      .toList();

  bool get isAllSample =>
      weather.origin == DataOrigin.sample &&
      marine.origin == DataOrigin.sample &&
      tide.origin == DataOrigin.sample;

  bool get hasLiveForecast =>
      weather.origin == DataOrigin.live && marine.origin == DataOrigin.live;

  String get sourceLabel {
    final sample = <String>[
      if (weather.origin == DataOrigin.sample) 'weather',
      if (marine.origin == DataOrigin.sample) 'marine',
      if (tide.origin == DataOrigin.sample) 'tide',
    ];
    if (hasLiveForecast) {
      return updateFailed
          ? 'Using the last available Open-Meteo forecast. Pull down to retry.'
          : 'Open-Meteo weather & marine · ${tide.origin == DataOrigin.live ? 'modeled sea level' : 'tide unavailable'} · indicative conditions index';
    }
    if (updateFailed) {
      if (isAllSample) {
        return 'Unable to update conditions. Weather, sea, tide and fishing score are sample values.';
      }
      return 'Unable to update conditions. Showing available values'
          '${sample.isEmpty ? '' : ' · sample ${sample.join(', ')}'}.'
          ' Fishing score is a sample, not based on these conditions.';
    }
    if (isAllSample) {
      return 'Weather, sea and tide are sample values. Fishing score is also a sample.';
    }
    if (sample.isEmpty) {
      return 'Weather and sea: Open-Meteo forecast. Fishing score is a sample, not based on these conditions.';
    }
    return 'Open-Meteo forecast · sample ${sample.join(', ')}.'
        ' Fishing score is a sample, not based on these conditions.';
  }

  // Fishing scores remain explicit demo values until a validated algorithm exists.
  int get score => 86;

  String get rating => 'Excellent';

  static String ratingFor(int value) => value >= 80
      ? 'Excellent'
      : value >= 65
      ? 'Good'
      : value >= 45
      ? 'Average'
      : 'Poor';

  DateTime localTime(DateTime utc) =>
      utc.add(Duration(seconds: weather.utcOffsetSeconds));

  String clock(DateTime? utc) {
    if (utc == null) return '--:--';
    final local = localTime(utc);
    return '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  }

  String get windDirection => WindDirection.fromDegrees(weather.windDegrees);
  String get waveDirection => compass(marine.waveDegrees);
  String get swellDirection => compass(marine.swellDegrees);

  static String compass(int degrees) {
    const directions = ['N', 'NE', 'E', 'SE', 'S', 'SW', 'W', 'NW'];
    return directions[((degrees % 360) / 45).round() % 8];
  }
}
