import '../models/demo_data.dart';
import '../models/fishing_location.dart';
import 'fishing_conditions_repository.dart';
import 'fishing_forecast_builder.dart';

/// Forecast conditions at each mapped coordinate; never assigns demo ratings.
class SpotConditionsService {
  SpotConditionsService({FishingConditionsRepository? repository})
    : repository = repository ?? LiveFishingConditionsRepository();

  final FishingConditionsRepository repository;

  Future<List<FishingSpot>> load(
    List<FishingSpot> spots, {
    bool forceRefresh = false,
  }) async {
    final results = <FishingSpot>[];
    // Limit concurrent requests to avoid overwhelming the forecast provider.
    for (var start = 0; start < spots.length; start += 4) {
      results.addAll(
        await Future.wait(
          spots.skip(start).take(4).map((spot) async {
            if (spot.point == null) return spot;
            try {
              final conditions = await repository.load(
                FishingLocation(label: spot.name, point: spot.point!),
                forceRefresh: forceRefresh,
              );
              if (!conditions.hasLiveForecast) return spot;
              final hour = const FishingForecastBuilder()
                  .build(conditions)
                  .first
                  .hours
                  .firstWhere((hour) => hour.isCurrent);
              return FishingSpot(
                spot.name,
                spot.distance,
                hour.score.score,
                spot.type,
                '${hour.windKmh.toStringAsFixed(0)} km/h',
                '${hour.waveM.toStringAsFixed(1)} m',
                spot.fish,
                spot.image,
                point: spot.point,
                mapped: spot.mapped,
                sourceId: spot.sourceId,
                hasForecast: true,
                forecastCached: conditions.updateFailed,
              );
            } catch (_) {
              return spot;
            }
          }),
        ),
      );
    }
    return results;
  }

  void dispose() => repository.dispose();
}
