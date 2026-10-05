import 'dart:math' as math;

import '../models/fish_activity_level.dart';
import '../models/fishing_forecast.dart';

/// An indicative conditions index, calculated only from forecast inputs.
/// It does not predict catches or detect fish.
class FishingScoreInput {
  const FishingScoreInput({
    required this.timeUtc,
    required this.windKmh,
    required this.gustKmh,
    required this.rainChance,
    required this.waveM,
    required this.tideHeightM,
    required this.sunriseUtc,
    required this.sunsetUtc,
    required this.pressureHpa,
    required this.temperatureC,
    required this.wavePeriodSeconds,
  });

  final DateTime timeUtc, sunriseUtc, sunsetUtc;
  final double windKmh, gustKmh, waveM, pressureHpa, temperatureC;
  final double? tideHeightM;
  final int wavePeriodSeconds, rainChance;
}

class FishingScoreService {
  const FishingScoreService();

  FishingScoreResult forHour(FishingScoreInput input) {
    var score = 50;
    final reasons = <String>[];

    if (input.windKmh <= 12) {
      score += 14;
      reasons.add('Light wind');
    } else if (input.windKmh <= 25) {
      score += 6;
      reasons.add('Moderate wind');
    } else if (input.windKmh > 35) {
      score -= 18;
      reasons.add('Strong wind');
    }

    if (input.gustKmh <= 20) {
      score += 6;
    } else if (input.gustKmh > 40) {
      score -= 12;
      reasons.add('Strong gusts');
    }

    if (input.waveM <= .8) {
      score += 12;
      reasons.add('Small waves');
    } else if (input.waveM <= 1.5) {
      score += 5;
    } else if (input.waveM > 2.5) {
      score -= 20;
      reasons.add('Large waves');
    }

    if (input.wavePeriodSeconds >= 7 && input.wavePeriodSeconds <= 13) {
      score += 5;
    }
    if (input.rainChance <= 20) {
      score += 5;
    } else if (input.rainChance >= 70) {
      score -= 8;
      reasons.add('Rain likely');
    }

    final minutesFromSunrise = input.timeUtc
        .difference(input.sunriseUtc)
        .inMinutes
        .abs();
    final minutesFromSunset = input.timeUtc
        .difference(input.sunsetUtc)
        .inMinutes
        .abs();
    if (math.min(minutesFromSunrise, minutesFromSunset) <= 90) {
      score += 8;
      reasons.add('Near dawn or dusk');
    }

    // Modeled mean sea level is not a local tide table. Height alone does
    // not describe tide movement, so it does not affect the index.
    final value = score.clamp(0, 100);
    return FishingScoreResult(
      score: value,
      level: FishActivityLevel.fromScore(value),
      reasons: reasons.isEmpty ? const ['Mixed forecast conditions'] : reasons,
    );
  }

  FishingScoreResult forDay(List<FishingScoreResult> hours) {
    final value = hours.isEmpty
        ? 0
        : (hours.map((hour) => hour.score).reduce(math.max) +
                  hours.map((hour) => hour.score).reduce((a, b) => a + b) /
                      hours.length) ~/
              2;
    return FishingScoreResult(
      score: value,
      level: FishActivityLevel.fromScore(value),
      reasons: const ['Based on the day’s weather and marine forecast'],
    );
  }
}
