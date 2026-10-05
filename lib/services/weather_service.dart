import '../models/fishing_location.dart';
import '../models/weather_model.dart';
import '../models/data_origin.dart';
import 'condition_sources.dart';

class WeatherService implements WeatherSource {
  const WeatherService(this.client);
  final OpenMeteoClient client;

  @override
  Future<WeatherModel> fetch(FishingLocation location) async {
    final json = await client.get(OpenMeteoClient.weatherBase, location, {
      'current':
          'temperature_2m,apparent_temperature,weather_code,'
          'wind_speed_10m,wind_direction_10m,wind_gusts_10m,cloud_cover,'
          'precipitation,precipitation_probability,pressure_msl,'
          'surface_pressure,relative_humidity_2m,uv_index,visibility',
      'hourly':
          'temperature_2m,apparent_temperature,weather_code,wind_speed_10m,'
          'wind_direction_10m,wind_gusts_10m,relative_humidity_2m,'
          'cloud_cover,precipitation,precipitation_probability,'
          'pressure_msl,surface_pressure',
      'daily': 'sunrise,sunset,weather_code',
    });
    final current = OpenMeteoJson.object(json, 'current');
    final hourly = OpenMeteoJson.object(json, 'hourly');
    final daily = OpenMeteoJson.object(json, 'daily');
    final times = OpenMeteoJson.list(hourly, 'time');
    final temperatures = OpenMeteoJson.list(hourly, 'temperature_2m');
    final codes = OpenMeteoJson.list(hourly, 'weather_code');
    final winds = OpenMeteoJson.list(hourly, 'wind_speed_10m');
    final precipitation = OpenMeteoJson.list(hourly, 'precipitation');
    final rainChances = OpenMeteoJson.list(hourly, 'precipitation_probability');
    final hourlyPressure =
        OpenMeteoJson.optionalList(hourly, 'surface_pressure') ??
        OpenMeteoJson.list(hourly, 'pressure_msl');
    final currentPressure =
        OpenMeteoJson.optional(current['surface_pressure']) ??
        OpenMeteoJson.number(current, 'pressure_msl');
    final hourlyFeels = OpenMeteoJson.optionalList(
      hourly,
      'apparent_temperature',
    );
    final hourlyGusts = OpenMeteoJson.optionalList(hourly, 'wind_gusts_10m');
    final hourlyDirections = OpenMeteoJson.optionalList(
      hourly,
      'wind_direction_10m',
    );
    final hourlyHumidity = OpenMeteoJson.optionalList(
      hourly,
      'relative_humidity_2m',
    );
    final hourlyCloud = OpenMeteoJson.optionalList(hourly, 'cloud_cover');
    final sunrises = OpenMeteoJson.list(daily, 'sunrise');
    final sunsets = OpenMeteoJson.list(daily, 'sunset');
    final dailyCodes = OpenMeteoJson.list(daily, 'weather_code');
    final utcOffsetSeconds = OpenMeteoJson.number(
      json,
      'utc_offset_seconds',
    ).round();
    final currentTime = OpenMeteoJson.time(current['time']);
    final previousIndex = times.lastIndexWhere(
      (value) =>
          !OpenMeteoJson.time(value)
              .isAfter(currentTime.subtract(const Duration(hours: 1))),
    );
    final pressureChange =
        previousIndex < 0 || previousIndex >= hourlyPressure.length
        ? null
        : currentPressure - OpenMeteoJson.value(hourlyPressure[previousIndex]);
    final length = [
      times.length,
      temperatures.length,
      codes.length,
      winds.length,
      precipitation.length,
      rainChances.length,
    ].reduce((a, b) => a < b ? a : b);
    if (length == 0) {
      throw const ConditionServiceException('No hourly weather');
    }
    return WeatherModel(
      airC: OpenMeteoJson.number(current, 'temperature_2m'),
      feelsLikeC: OpenMeteoJson.number(current, 'apparent_temperature'),
      weatherCode: OpenMeteoJson.number(current, 'weather_code').round(),
      windKmh: OpenMeteoJson.number(current, 'wind_speed_10m'),
      windDegrees: OpenMeteoJson.number(current, 'wind_direction_10m').round(),
      gustKmh: OpenMeteoJson.number(current, 'wind_gusts_10m'),
      cloudCover: OpenMeteoJson.number(current, 'cloud_cover').round(),
      precipitationMm: OpenMeteoJson.number(current, 'precipitation'),
      rainChance: OpenMeteoJson.number(
        current,
        'precipitation_probability',
      ).round(),
      pressureHpa: currentPressure.round(),
      humidity: OpenMeteoJson.optional(current['relative_humidity_2m'])
          ?.round(),
      uvIndex: OpenMeteoJson.optional(current['uv_index']),
      visibilityKm: OpenMeteoJson.optional(current['visibility']) == null
          ? null
          : OpenMeteoJson.value(current['visibility']) / 1000,
      pressureChangeHpa: pressureChange,
      sunriseUtc: OpenMeteoJson.time(sunrises.first),
      sunsetUtc: OpenMeteoJson.time(sunsets.first),
      utcOffsetSeconds: utcOffsetSeconds,
      hours: List.generate(
        length,
        (i) => WeatherHour(
          OpenMeteoJson.time(times[i]),
          OpenMeteoJson.value(winds[i]),
          OpenMeteoJson.value(rainChances[i]).round(),
          temperatureC: OpenMeteoJson.value(temperatures[i]),
          weatherCode: OpenMeteoJson.value(codes[i]).round(),
          precipitationMm: OpenMeteoJson.value(precipitation[i]),
          feelsLikeC: OpenMeteoJson.optionalAt(hourlyFeels, i),
          gustKmh: OpenMeteoJson.optionalAt(hourlyGusts, i),
          windDegrees: OpenMeteoJson.optionalAt(hourlyDirections, i)?.round(),
          humidity: OpenMeteoJson.optionalAt(hourlyHumidity, i)?.round(),
          cloudCover: OpenMeteoJson.optionalAt(hourlyCloud, i)?.round(),
          pressureHpa: OpenMeteoJson.optionalAt(hourlyPressure, i),
        ),
      ),
      dailyWeatherCodes: dailyCodes
          .map((value) => OpenMeteoJson.value(value).round())
          .toList(),
      days: List.generate(
        [
          sunrises.length,
          sunsets.length,
          dailyCodes.length,
        ].reduce((a, b) => a < b ? a : b),
        (i) {
          final sunriseUtc = OpenMeteoJson.time(sunrises[i]);
          final local = sunriseUtc.add(Duration(seconds: utcOffsetSeconds));
          return WeatherDay(
            dateLocal: DateTime.utc(local.year, local.month, local.day),
            weatherCode: OpenMeteoJson.value(dailyCodes[i]).round(),
            sunriseUtc: sunriseUtc,
            sunsetUtc: OpenMeteoJson.time(sunsets[i]),
          );
        },
      ),
      origin: DataOrigin.live,
    );
  }
}
