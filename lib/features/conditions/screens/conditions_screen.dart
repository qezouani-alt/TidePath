import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../models/fishing_conditions.dart';
import '../../../widgets/premium_widgets.dart';
import '../conditions_scope.dart';
import '../../location/location_scope.dart';
import '../../location/screens/location_picker_screen.dart';

class ConditionsScreen extends StatelessWidget {
  const ConditionsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final conditions = FishingConditionsScope.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Sea Conditions')),
      body: SingleChildScrollView(
        child: ScreenPadding(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InkWell(
                onTap: () => pushPage(context, const LocationPickerScreen()),
                child: Row(
                  children: [
                    const Icon(
                      Icons.location_on_rounded,
                      color: AppColors.blue,
                      size: 17,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        '${FishingLocationScope.of(context).selected.label} · ${conditions.sourceLabel}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  gradient: oceanGradient,
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.waves_rounded,
                      color: Colors.white,
                      size: 42,
                    ),
                    const SizedBox(width: 17),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            conditions.rating == 'Poor'
                                ? 'Challenging conditions'
                                : 'Calm & fishable',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Check wind, waves, and tide before heading out.',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              const SectionHeader('Wind & water'),
              _grid(context, [
                WeatherMetricCard(
                  title: 'Wind speed',
                  value: '${conditions.weather.windKmh.round()} km/h',
                  subtitle:
                      '${conditions.windDirection} · gusts ${conditions.weather.gustKmh.round()} km/h',
                  icon: Icons.air_rounded,
                ),
                WeatherMetricCard(
                  title: 'Wave height',
                  value: '${conditions.marine.waveM.toStringAsFixed(1)} m',
                  subtitle:
                      '${conditions.waveDirection} · ${conditions.marine.wavePeriodSeconds} sec period',
                  icon: Icons.waves_rounded,
                ),
                WeatherMetricCard(
                  title: 'Swell',
                  value: '${conditions.marine.swellM.toStringAsFixed(1)} m',
                  subtitle:
                      '${conditions.swellDirection} · ${conditions.marine.swellPeriodSeconds} sec period',
                  icon: Icons.water_rounded,
                ),
                WeatherMetricCard(
                  title: 'Water temp',
                  value: '${conditions.marine.waterC.round()}°C',
                  subtitle: 'Sea surface temperature',
                  icon: Icons.thermostat_rounded,
                ),
              ]),
              const SizedBox(height: 27),
              const SectionHeader('Tides'),
              AppCard(
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(
                          conditions.tide.phase == 'Rising'
                              ? Icons.trending_up_rounded
                              : Icons.trending_down_rounded,
                          color: AppColors.good,
                        ),
                        const SizedBox(width: 9),
                        Expanded(
                          child: Text(
                            '${conditions.tide.phase} tide',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        LabelPill(
                          conditions.tide.origin == DataOrigin.live
                              ? 'MODEL ESTIMATE'
                              : 'SAMPLE',
                          color: Color(0xFFE9F8F1),
                          textColor: AppColors.good,
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: _TideTime(
                            'HIGH TIDE',
                            conditions.clock(conditions.tide.highUtc),
                            Icons.arrow_upward_rounded,
                          ),
                        ),
                        Expanded(
                          child: _TideTime(
                            'LOW TIDE',
                            conditions.clock(conditions.tide.lowUtc),
                            Icons.arrow_downward_rounded,
                          ),
                        ),
                        Expanded(
                          child: _TideTime(
                            'NEXT TIDE',
                            conditions.clock(conditions.tide.nextUtc),
                            Icons.schedule_rounded,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 27),
              const SectionHeader('Weather & sky'),
              _grid(context, [
                WeatherMetricCard(
                  title: 'Air temp',
                  value: '${conditions.weather.airC.round()}°C',
                  subtitle:
                      'Feels like ${conditions.weather.feelsLikeC.round()}°C',
                  icon: Icons.wb_sunny_outlined,
                ),
                WeatherMetricCard(
                  title: 'Rain chance',
                  value: '${conditions.weather.rainChance}%',
                  subtitle: 'Precipitation chance',
                  icon: Icons.water_drop_outlined,
                ),
                WeatherMetricCard(
                  title: 'Cloud cover',
                  value: '${conditions.weather.cloudCover}%',
                  subtitle: 'Current cloud cover',
                  icon: Icons.cloud_outlined,
                ),
                WeatherMetricCard(
                  title: 'Pressure',
                  value: '${conditions.weather.pressureHpa} hPa',
                  subtitle: 'Sea level pressure',
                  icon: Icons.speed_rounded,
                ),
              ]),
              const SizedBox(height: 27),
              const SectionHeader('Sun & moon'),
              _grid(context, [
                WeatherMetricCard(
                  title: 'Sunrise',
                  value: conditions.clock(conditions.weather.sunriseUtc),
                  subtitle: 'Morning bite',
                  icon: Icons.wb_twilight_rounded,
                ),
                WeatherMetricCard(
                  title: 'Sunset',
                  value: conditions.clock(conditions.weather.sunsetUtc),
                  subtitle: 'Evening bite',
                  icon: Icons.nights_stay_outlined,
                ),
                WeatherMetricCard(
                  title: 'Moon phase',
                  value: 'Waxing',
                  subtitle: 'Gibbous · sample',
                  icon: Icons.brightness_2_outlined,
                ),
                WeatherMetricCard(
                  title: 'Illumination',
                  value: '62%',
                  subtitle: 'Brightening · sample',
                  icon: Icons.brightness_4_outlined,
                ),
              ]),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _grid(BuildContext context, List<Widget> children) => LayoutBuilder(
    builder: (context, constraints) => GridView.count(
      crossAxisCount: 2,
      childAspectRatio: constraints.maxWidth > 520 ? 1.65 : 1.0,
      mainAxisSpacing: 11,
      crossAxisSpacing: 11,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: children,
    ),
  );
}

class _TideTime extends StatelessWidget {
  const _TideTime(this.label, this.time, this.icon);
  final String label, time;
  final IconData icon;
  @override
  Widget build(BuildContext context) => Column(
    children: [
      Icon(icon, color: AppColors.aqua, size: 18),
      const SizedBox(height: 5),
      Text(
        label,
        style: const TextStyle(
          color: AppColors.muted,
          fontSize: 9,
          fontWeight: FontWeight.w800,
        ),
      ),
      const SizedBox(height: 3),
      Text(
        time,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
      ),
    ],
  );
}
