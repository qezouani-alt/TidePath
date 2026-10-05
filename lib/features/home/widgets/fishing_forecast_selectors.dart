import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../models/fishing_forecast.dart';
import '../../../utils/wind_direction.dart';
import '../../../widgets/premium_widgets.dart';

const _aqua = AppColors.glow;

class HourlyFishingSlider extends StatelessWidget {
  const HourlyFishingSlider({
    super.key,
    required this.hours,
    required this.selectedIndex,
    required this.controller,
    required this.onSelected,
    this.loading = false,
  });

  final List<FishingForecastHour> hours;
  final int selectedIndex;
  final ScrollController controller;
  final ValueChanged<int> onSelected;
  final bool loading;

  static const itemExtent = 106.0;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const _SectionHeading('HOURLY FORECAST', trailing: 'SWIPE TO EXPLORE'),
      const SizedBox(height: 10),
      SizedBox(
        height: 150,
        child: ListView.separated(
          controller: controller,
          scrollDirection: Axis.horizontal,
          itemCount: hours.length,
          separatorBuilder: (_, _) => const SizedBox(width: 8),
          itemBuilder: (context, index) {
            final hour = hours[index];
            final selected = index == selectedIndex;
            return Semantics(
              button: true,
              selected: selected,
              label:
                  '${_hourLabel(hour.localTime)}: ${hour.score.score} conditions index, ${hour.windKmh.round()} kilometers per hour wind, ${hour.waveM.toStringAsFixed(1)} meter waves',
              child: GestureDetector(
                key: Key('fishing-hour-$index'),
                onTap: () => onSelected(index),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 260),
                  width: 98,
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: selected ? .20 : .07),
                    borderRadius: BorderRadius.circular(17),
                    border: Border.all(
                      color: selected
                          ? _aqua.withValues(alpha: .84)
                          : Colors.white.withValues(alpha: .12),
                      width: selected ? 1.5 : 1,
                    ),
                    boxShadow: selected
                        ? [
                            BoxShadow(
                              color: _aqua.withValues(alpha: .14),
                              blurRadius: 13,
                            ),
                          ]
                        : null,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            _hourLabel(hour.localTime),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const Spacer(),
                          if (hour.isCurrent)
                            const CircleAvatar(
                              radius: 3,
                              backgroundColor: _aqua,
                            ),
                        ],
                      ),
                      const SizedBox(height: 7),
                      Row(
                        children: [
                          Icon(
                            weatherIconFor(hour.weatherCode),
                            color: _aqua,
                            size: 17,
                          ),
                          const SizedBox(width: 4),
                          loading
                              ? const LoadingLine(
                                  width: 32,
                                  height: 12,
                                  light: true,
                                )
                              : Text(
                                  '${hour.temperatureC.round()}°',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Text(
                        '${hour.score.score} · ${hour.score.label}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: _aqua,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${WindDirection.fromDegrees(hour.windDegrees)} ${hour.windKmh.round()} km/h',
                        maxLines: 1,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 9,
                        ),
                      ),
                      Text(
                        'Waves ${hour.waveM.toStringAsFixed(1)} m',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 9,
                        ),
                      ),
                      const Spacer(),
                      if (hour.isBestHour)
                        const Text(
                          '✦ BEST',
                          style: TextStyle(
                            color: _aqua,
                            fontSize: 8,
                            fontWeight: FontWeight.w900,
                            letterSpacing: .5,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    ],
  );
}

class SevenDayFishingForecast extends StatelessWidget {
  const SevenDayFishingForecast({
    super.key,
    required this.days,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<FishingForecastDay> days;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const _SectionHeading('7-DAY FORECAST', trailing: 'CONDITIONS INDEX'),
      const SizedBox(height: 10),
      SizedBox(
        height: 111,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: days.length,
          separatorBuilder: (_, _) => const SizedBox(width: 8),
          itemBuilder: (context, index) {
            final day = days[index];
            final selected = index == selectedIndex;
            return Semantics(
              button: true,
              selected: selected,
              label:
                  '${_dayLabel(day.dateLocal)}, ${day.score.score} conditions index',
              child: GestureDetector(
                key: Key('fishing-day-$index'),
                onTap: () => onSelected(index),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 260),
                  width: 79,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: selected ? .20 : .07),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: selected
                          ? _aqua.withValues(alpha: .86)
                          : Colors.white.withValues(alpha: .12),
                      width: selected ? 1.5 : 1,
                    ),
                    boxShadow: selected
                        ? [
                            BoxShadow(
                              color: _aqua.withValues(alpha: .14),
                              blurRadius: 13,
                            ),
                          ]
                        : null,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _dayLabel(day.dateLocal),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Icon(
                        weatherIconFor(day.weatherCode),
                        color: _aqua,
                        size: 21,
                      ),
                      Text(
                        '${day.score.score}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    ],
  );
}

class BestFishingTimeCard extends StatelessWidget {
  const BestFishingTimeCard({super.key, required this.windows});

  final List<BestFishingWindow> windows;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const _SectionHeading('DAWN & DUSK', trailing: 'SUN TIMES'),
      const SizedBox(height: 10),
      LayoutBuilder(
        builder: (context, constraints) {
          final narrow = constraints.maxWidth < 290;
          final cards = windows
              .map(
                (window) => Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 11,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: .10),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          window.label.toUpperCase(),
                          style: const TextStyle(
                            color: _aqua,
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            letterSpacing: .4,
                          ),
                        ),
                        const SizedBox(height: 4),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            window.clockRange,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
              .toList();
          if (narrow) {
            return Column(
              children: [
                Row(children: [cards[0]]),
                const SizedBox(height: 8),
                Row(children: [cards[1]]),
              ],
            );
          }
          return Row(children: [cards[0], const SizedBox(width: 8), cards[1]]);
        },
      ),
    ],
  );
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading(this.title, {required this.trailing});

  final String title, trailing;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.w900,
            letterSpacing: .85,
          ),
        ),
      ),
      Text(
        trailing,
        style: const TextStyle(
          color: Colors.white54,
          fontSize: 9,
          fontWeight: FontWeight.w800,
          letterSpacing: .45,
        ),
      ),
    ],
  );
}

String _hourLabel(DateTime local) {
  final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
  return '$hour ${local.hour < 12 ? 'AM' : 'PM'}';
}

String _dayLabel(DateTime date) {
  const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  return '${weekdays[date.weekday - 1]} ${date.day}';
}
