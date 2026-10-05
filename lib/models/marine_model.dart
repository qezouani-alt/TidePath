import 'data_origin.dart';

class MarineHour {
  const MarineHour(
    this.timeUtc,
    this.waveM,
    this.seaLevelM, {
    this.waveDegrees,
    this.wavePeriodSeconds,
    this.swellM,
    this.swellDegrees,
    this.swellPeriodSeconds,
    this.waterC,
  });
  final DateTime timeUtc;
  final double? waveM, seaLevelM;
  final int? waveDegrees, wavePeriodSeconds, swellDegrees, swellPeriodSeconds;
  final double? swellM, waterC;
}

class MarineModel {
  const MarineModel({
    required this.waveM,
    required this.wavePeriodSeconds,
    required this.waveDegrees,
    required this.swellM,
    required this.swellPeriodSeconds,
    required this.swellDegrees,
    required this.waterC,
    required this.seaLevelM,
    required this.oceanCurrentKmh,
    required this.oceanCurrentDegrees,
    required this.hours,
    required this.origin,
  });

  final double waveM, swellM, waterC;
  final int wavePeriodSeconds, waveDegrees, swellPeriodSeconds, swellDegrees;
  final double? seaLevelM, oceanCurrentKmh;
  final int? oceanCurrentDegrees;
  final List<MarineHour> hours;
  final DataOrigin origin;
}
