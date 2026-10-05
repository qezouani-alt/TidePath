import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../models/coast_orientation.dart';
import '../../../models/fishing_forecast.dart';
import '../../../utils/wind_direction.dart';
import '../../../widgets/fishing_metric_item.dart';
import '../../../widgets/premium_widgets.dart';
import '../../home/widgets/fishing_forecast_selectors.dart';
import 'circular_fishing_dashboard.dart';
import 'summary_forecast_navigation.dart';

class FishingSummaryTab extends StatelessWidget {
  const FishingSummaryTab({
    super.key,
    required this.days,
    required this.selectedDay,
    required this.selectedHour,
    required this.hourController,
    required this.onDaySelected,
    required this.onHourSelected,
    required this.loading,
    this.coast,
  });

  final List<FishingForecastDay> days;
  final int selectedDay, selectedHour;
  final ScrollController hourController;
  final ValueChanged<int> onDaySelected, onHourSelected;
  final bool loading;
  final CoastOrientation? coast;

  @override
  Widget build(BuildContext context) {
    final day = days[selectedDay];
    final hour = day.hours[selectedHour];
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(17, 18, 17, 20),
      decoration: BoxDecoration(
        gradient: oceanGradient,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppColors.blue.withValues(alpha: .17),
            blurRadius: 25,
            offset: const Offset(0, 11),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${hour.score.label} Conditions',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -.45,
                  ),
                ),
              ),
              const Text('FORECAST INDEX', style: _sampleStyle),
            ],
          ),
          const SizedBox(height: 10),
          CircularFishingDashboard(
            hour: hour,
            dayHours: day.hours,
            coast: coast,
            loading: loading,
          ),
          const SizedBox(height: 13),
          Text(
            '${hour.score.activeFishCount} of 4 indicators highlighted · ${hour.isBestHour ? 'near dawn or dusk' : 'check local wind, waves and tide before heading out'}',
            style: const TextStyle(color: Colors.white70, fontSize: 11),
          ),
          const SizedBox(height: 18),
          SummaryTimeSlider(
            selectedHour: selectedHour,
            onSelected: onHourSelected,
          ),
          const SizedBox(height: 20),
          Divider(color: Colors.white.withValues(alpha: .16), height: 1),
          const SizedBox(height: 20),
          SummaryWeekSelector(
            days: days,
            selectedIndex: selectedDay,
            onSelected: onDaySelected,
          ),
          const SizedBox(height: 18),
          BestFishingTimeCard(windows: day.bestWindows),
          const SizedBox(height: 20),
          Divider(color: Colors.white.withValues(alpha: .16), height: 1),
          const SizedBox(height: 19),
          HourlyFishingSlider(
            hours: day.hours,
            selectedIndex: selectedHour,
            controller: hourController,
            onSelected: onHourSelected,
            loading: loading,
          ),
          const SizedBox(height: 20),
          const Text('MORE CONDITIONS', style: _sectionStyle),
          const SizedBox(height: 10),
          LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final columns = width >= 610 ? 4 : 2;
              final itemWidth = (width - (columns - 1) * 8) / columns;
              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _details(hour)
                    .map((item) => SizedBox(width: itemWidth, child: item))
                    .toList(),
              );
            },
          ),
          const SizedBox(height: 13),
          Text(
            'Indicative index from the weather and marine forecast; it does not predict catches. ${hour.usesSampleTide ? 'Tide unavailable.' : 'Sea level is modeled, not a local tide table.'}',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 10,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _details(FishingForecastHour hour) => [
    _item(
      'Rainfall',
      '${hour.precipitationMm.toStringAsFixed(1)} mm',
      '${hour.rainChance}% chance',
    ),
    _item(
      'Humidity',
      hour.humidity == null ? '—' : '${hour.humidity}%',
      'Air moisture',
    ),
    _item(
      'Pressure',
      '${hour.pressureHpa.round()} hPa',
      '${hour.pressureTrend} trend',
    ),
    _item(
      'Wind gusts',
      '${hour.gustKmh.round()} km/h',
      '${WindDirection.fromDegrees(hour.windDegrees)} direction',
    ),
    _item(
      'Wave direction',
      WindDirection.fromDegrees(hour.waveDegrees),
      '${hour.waveDegrees}° · ${hour.wavePeriodSeconds} s period',
    ),
    _item(
      'Swell',
      '${hour.swellM.toStringAsFixed(1)} m',
      '${WindDirection.fromDegrees(hour.swellDegrees)} direction',
    ),
    _item('Sea', '${hour.waterC.round()}°C', 'Surface temperature'),
    _item(
      'Tide',
      hour.tideHeightM == null
          ? hour.tidePhase
          : '${hour.tideHeightM!.toStringAsFixed(2)} m',
      hour.usesSampleTide ? 'No tide data' : hour.tidePhase,
    ),
  ];

  Widget _item(String label, String value, String detail) => FishingMetricItem(
    label: label,
    value: value,
    detail: detail,
    loading: loading,
  );
}

const _sampleStyle = TextStyle(
  color: AppColors.glow,
  fontSize: 9,
  fontWeight: FontWeight.w900,
);
const _sectionStyle = TextStyle(
  color: Colors.white,
  fontSize: 11,
  fontWeight: FontWeight.w900,
  letterSpacing: .85,
);
