import '../models/fishing_conditions.dart';
import '../models/fishing_location.dart';
import 'condition_sources.dart';
import 'demo_condition_data.dart';
import 'marine_service.dart';
import 'weather_service.dart';

abstract class FishingConditionsRepository {
  Future<FishingConditions> load(
    FishingLocation location, {
    bool forceRefresh = false,
  });
  void dispose() {}
}

class LiveFishingConditionsRepository implements FishingConditionsRepository {
  LiveFishingConditionsRepository({
    WeatherSource? weather,
    MarineSource? marine,
    TideSource? tide,
    OpenMeteoClient? client,
    DateTime Function()? now,
  }) : _client = client ?? OpenMeteoClient(),
       _now = now ?? DateTime.now {
    _weather = weather ?? WeatherService(_client);
    _marine = marine ?? MarineService(_client);
    _tide = tide ?? const EstimatedTideSource();
  }

  final OpenMeteoClient _client;
  final DateTime Function() _now;
  late final WeatherSource _weather;
  late final MarineSource _marine;
  late final TideSource _tide;
  final Map<String, _CacheEntry> _cache = {};
  final Map<String, Future<FishingConditions>> _inFlight = {};

  @override
  Future<FishingConditions> load(
    FishingLocation location, {
    bool forceRefresh = false,
  }) {
    final key =
        '${location.point.latitude.toStringAsFixed(4)},'
        '${location.point.longitude.toStringAsFixed(4)}:${location.label}';
    final existing = _cache[key];
    if (!forceRefresh && existing != null) {
      final ttl = existing.value.isAllSample
          ? const Duration(minutes: 1)
          : const Duration(minutes: 15);
      if (_now().difference(existing.fetchedAt) < ttl) {
        return Future.value(existing.value);
      }
    }
    final pending = _inFlight[key];
    if (pending != null) return pending;

    final request = _loadFresh(location, existing?.value);
    _inFlight[key] = request;
    return request
        .then((value) {
          _cache[key] = _CacheEntry(value, _now());
          return value;
        })
        .whenComplete(() {
          _inFlight.remove(key);
        });
  }

  Future<FishingConditions> _loadFresh(
    FishingLocation location,
    FishingConditions? previous,
  ) async {
    // Start both independent API calls together. A failure in one does not
    // discard a successful response from the other.
    final weatherRequest = _attempt(() => _weather.fetch(location));
    final marineRequest = _attempt(() => _marine.fetch(location));
    final weatherResult = await weatherRequest;
    final marineResult = await marineRequest;
    if (weatherResult == null && marineResult == null) {
      return (previous ?? DemoConditionData.forLocation(location))
          .withUpdateFailed(true);
    }
    final weather =
        weatherResult ?? previous?.weather ?? DemoConditionData.weather();
    final marine =
        marineResult ?? previous?.marine ?? DemoConditionData.marine();
    final tide = marineResult == null && previous != null
        ? previous.tide
        : await _attempt(() => _tide.fetch(location, marine)) ??
              const TideConditions(
                phase: 'Unavailable',
                highUtc: null,
                lowUtc: null,
                nextUtc: null,
                origin: DataOrigin.unavailable,
              );
    final nowUtc = _now().toUtc();
    final hours = weather.hours
        .where(
          (hour) =>
              !hour.timeUtc.isBefore(nowUtc.subtract(const Duration(hours: 1))),
        )
        .toList();
    final outlook = List.generate(
      hours.length,
      (index) => FishingOutlook(
        hours[index].timeUtc,
        DemoConditionData.outlookScoreAt(index),
      ),
    );
    return FishingConditions(
      location: location,
      weather: weather,
      marine: marine,
      tide: tide,
      hourly: outlook,
      updateFailed: weatherResult == null || marineResult == null,
    );
  }

  Future<T?> _attempt<T>(Future<T> Function() action) async {
    try {
      return await action();
    } catch (_) {
      return null;
    }
  }

  @override
  void dispose() {
    _cache.clear();
    _client.close();
  }
}

class _CacheEntry {
  const _CacheEntry(this.value, this.fetchedAt);
  final FishingConditions value;
  final DateTime fetchedAt;
}
