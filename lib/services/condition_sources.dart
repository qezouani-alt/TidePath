import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/fishing_conditions.dart';
import '../models/fishing_location.dart';

abstract class WeatherSource {
  Future<WeatherModel> fetch(FishingLocation location);
}

abstract class MarineSource {
  Future<MarineModel> fetch(FishingLocation location);
}

abstract class TideSource {
  Future<TideConditions> fetch(FishingLocation location, MarineModel marine);
}

class OpenMeteoClient {
  OpenMeteoClient({http.Client? client})
    : _client = client ?? http.Client(),
      _ownsClient = client == null;

  final http.Client _client;
  final bool _ownsClient;

  static const weatherBase = 'https://api.open-meteo.com/v1/forecast';
  static const marineBase = 'https://marine-api.open-meteo.com/v1/marine';

  Future<Map<String, dynamic>> get(
    String base,
    FishingLocation location,
    Map<String, String> parameters,
  ) async {
    final uri = Uri.parse(base).replace(
      queryParameters: {
        'latitude': location.point.latitude.toString(),
        'longitude': location.point.longitude.toString(),
        'timezone': 'auto',
        'timeformat': 'unixtime',
        'forecast_days': '7',
        ...parameters,
      },
    );
    final response = await _client
        .get(uri)
        .timeout(const Duration(seconds: 10));
    if (response.statusCode != 200) {
      throw ConditionServiceException('Open-Meteo HTTP ${response.statusCode}');
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic> || decoded['error'] == true) {
      throw const ConditionServiceException('Invalid Open-Meteo response');
    }
    return decoded;
  }

  void close() {
    if (_ownsClient) _client.close();
  }
}

class EstimatedTideSource implements TideSource {
  const EstimatedTideSource();

  @override
  Future<TideConditions> fetch(
    FishingLocation location,
    MarineModel marine,
  ) async {
    if (marine.origin != DataOrigin.live) {
      throw const ConditionServiceException('No live sea level data');
    }
    final now = DateTime.now().toUtc();
    final levels = marine.hours
        .where((hour) => hour.seaLevelM != null)
        .toList();
    if (levels.length < 4) {
      throw const ConditionServiceException('Insufficient sea level data');
    }
    final next = levels.indexWhere((hour) => hour.timeUtc.isAfter(now));
    if (next < 1 || next >= levels.length - 1) {
      throw const ConditionServiceException('No current tide estimate');
    }
    final rising = levels[next].seaLevelM! > levels[next - 1].seaLevelM!;
    DateTime? high, low;
    for (
      var i = next;
      i < levels.length - 1 && (high == null || low == null);
      i++
    ) {
      final before = levels[i - 1].seaLevelM!;
      final value = levels[i].seaLevelM!;
      final after = levels[i + 1].seaLevelM!;
      if (high == null && value >= before && value > after) {
        high = levels[i].timeUtc;
      }
      if (low == null && value <= before && value < after) {
        low = levels[i].timeUtc;
      }
    }
    if (high == null || low == null) {
      throw const ConditionServiceException('No tide turning points');
    }
    return TideConditions(
      phase: rising ? 'Rising' : 'Falling',
      highUtc: high,
      lowUtc: low,
      nextUtc: high.isBefore(low) ? high : low,
      origin: DataOrigin.live,
    );
  }
}

class ConditionServiceException implements Exception {
  const ConditionServiceException(this.message);
  final String message;
  @override
  String toString() => message;
}

abstract final class OpenMeteoJson {
  static Map<String, dynamic> object(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is Map<String, dynamic>) return value;
    throw ConditionServiceException('Missing $key');
  }

  static List<dynamic> list(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is List<dynamic>) return value;
    throw ConditionServiceException('Missing $key');
  }

  static List<dynamic>? optionalList(Map<String, dynamic> json, String key) {
    final value = json[key];
    return value is List<dynamic> ? value : null;
  }

  static double? optionalAt(List<dynamic>? values, int index) =>
      values != null && index < values.length ? optional(values[index]) : null;

  static double number(Map<String, dynamic> json, String key) =>
      value(json[key]);

  static double value(dynamic input) {
    if (input is num && input.isFinite) return input.toDouble();
    throw const ConditionServiceException('Missing numeric forecast value');
  }

  static double? optional(dynamic input) =>
      input is num && input.isFinite ? input.toDouble() : null;

  static DateTime time(dynamic input) => DateTime.fromMillisecondsSinceEpoch(
    value(input).round() * 1000,
    isUtc: true,
  );
}
