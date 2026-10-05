import 'package:flutter_test/flutter_test.dart';
import 'package:fishing/models/fishing_location.dart';
import 'package:fishing/services/fishing_forecast_builder.dart';
import 'package:fishing/utils/wind_direction.dart';
import 'package:latlong2/latlong.dart';

import 'support/live_conditions_fixture.dart';

void main() {
  test('sixteen-point wind directions follow meteorological degrees', () {
    expect(WindDirection.fromDegrees(0), 'N');
    expect(WindDirection.fromDegrees(22.5), 'NNE');
    expect(WindDirection.fromDegrees(45), 'NE');
    expect(WindDirection.fromDegrees(112.5), 'ESE');
    expect(WindDirection.fromDegrees(135), 'SE');
    expect(WindDirection.fromDegrees(270), 'W');
    expect(WindDirection.fromDegrees(337.5), 'NNW');
    expect(WindDirection.fromDegrees(360), 'N');
  });

  test('cached conditions compose seven selectable 24-hour days', () {
    const location = FishingLocation(
      label: 'Agadir, Morocco',
      point: LatLng(30.4278, -9.5981),
    );
    final conditions = liveConditionsFixture(location);
    final day = conditions.weather.hours.first.timeUtc;
    final now = day.add(const Duration(hours: 12));
    final forecast = const FishingForecastBuilder().build(
      conditions,
      nowUtc: now,
    );

    expect(forecast, hasLength(7));
    expect(forecast.every((day) => day.hours.length == 24), isTrue);
    expect(forecast.first.hours[12].isCurrent, isTrue);
    expect(forecast.first.hours[12].score.score, inInclusiveRange(0, 100));
    expect(
      forecast.first.hours[7].score.score,
      greaterThan(forecast.first.hours[12].score.score),
    );
    expect(forecast.first.hours[7].isBestHour, isTrue);
    expect(
      forecast[1].hours[7].score.score,
      forecast.first.hours[7].score.score,
    );
    expect(forecast[1].hours[7].localTime.day, forecast[1].dateLocal.day);
    expect(
      forecast[1].bestWindows.first.clockRange,
      forecast.first.bestWindows.first.clockRange,
    );
    expect(
      forecast.first.hours[18].waveM,
      isNot(forecast.first.hours[7].waveM),
    );
  });
}
