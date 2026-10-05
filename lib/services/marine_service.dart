import 'package:latlong2/latlong.dart';

import '../models/data_origin.dart';
import '../models/fishing_location.dart';
import '../models/marine_model.dart';
import 'condition_sources.dart';

class MarineService implements MarineSource {
  const MarineService(this.client);
  final OpenMeteoClient client;

  @override
  Future<MarineModel> fetch(FishingLocation location) async {
    final json = await client.get(OpenMeteoClient.marineBase, location, {
      'current':
          'wave_height,wave_direction,wave_period,swell_wave_height,'
          'swell_wave_direction,swell_wave_period,sea_surface_temperature,'
          'sea_level_height_msl,ocean_current_velocity,ocean_current_direction',
      'hourly':
          'wave_height,wave_direction,wave_period,swell_wave_height,'
          'swell_wave_direction,swell_wave_period,sea_surface_temperature,'
          'sea_level_height_msl',
    });
    final modelPoint = LatLng(
      OpenMeteoJson.number(json, 'latitude'),
      OpenMeteoJson.number(json, 'longitude'),
    );
    final distanceKm = const Distance().as(
      LengthUnit.Kilometer,
      location.point,
      modelPoint,
    );
    if (distanceKm > 50) {
      throw const ConditionServiceException('No nearby marine model cell');
    }
    final current = OpenMeteoJson.object(json, 'current');
    final hourly = OpenMeteoJson.object(json, 'hourly');
    final times = OpenMeteoJson.list(hourly, 'time');
    final waves = OpenMeteoJson.list(hourly, 'wave_height');
    final seaLevels = OpenMeteoJson.list(hourly, 'sea_level_height_msl');
    final waveDirections = OpenMeteoJson.optionalList(hourly, 'wave_direction');
    final wavePeriods = OpenMeteoJson.optionalList(hourly, 'wave_period');
    final swells = OpenMeteoJson.optionalList(hourly, 'swell_wave_height');
    final swellDirections = OpenMeteoJson.optionalList(
      hourly,
      'swell_wave_direction',
    );
    final swellPeriods = OpenMeteoJson.optionalList(
      hourly,
      'swell_wave_period',
    );
    final waterTemperatures = OpenMeteoJson.optionalList(
      hourly,
      'sea_surface_temperature',
    );
    final length = [
      times.length,
      waves.length,
      seaLevels.length,
    ].reduce((a, b) => a < b ? a : b);
    if (length == 0) {
      throw const ConditionServiceException('No marine forecast');
    }
    return MarineModel(
      waveM: OpenMeteoJson.number(current, 'wave_height'),
      waveDegrees: OpenMeteoJson.number(current, 'wave_direction').round(),
      wavePeriodSeconds: OpenMeteoJson.number(current, 'wave_period').round(),
      swellM: OpenMeteoJson.number(current, 'swell_wave_height'),
      swellDegrees: OpenMeteoJson.number(
        current,
        'swell_wave_direction',
      ).round(),
      swellPeriodSeconds: OpenMeteoJson.number(
        current,
        'swell_wave_period',
      ).round(),
      waterC: OpenMeteoJson.number(current, 'sea_surface_temperature'),
      seaLevelM: OpenMeteoJson.optional(current['sea_level_height_msl']),
      oceanCurrentKmh: OpenMeteoJson.optional(
        current['ocean_current_velocity'],
      ),
      oceanCurrentDegrees: OpenMeteoJson.optional(
        current['ocean_current_direction'],
      )?.round(),
      hours: List.generate(
        length,
        (i) => MarineHour(
          OpenMeteoJson.time(times[i]),
          OpenMeteoJson.optional(waves[i]),
          OpenMeteoJson.optional(seaLevels[i]),
          waveDegrees: OpenMeteoJson.optionalAt(waveDirections, i)?.round(),
          wavePeriodSeconds: OpenMeteoJson.optionalAt(wavePeriods, i)?.round(),
          swellM: OpenMeteoJson.optionalAt(swells, i),
          swellDegrees: OpenMeteoJson.optionalAt(swellDirections, i)?.round(),
          swellPeriodSeconds: OpenMeteoJson.optionalAt(
            swellPeriods,
            i,
          )?.round(),
          waterC: OpenMeteoJson.optionalAt(waterTemperatures, i),
        ),
      ),
      origin: DataOrigin.live,
    );
  }
}
