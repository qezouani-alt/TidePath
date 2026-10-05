import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../models/coast_orientation.dart';
import '../../../models/fishing_forecast.dart';
import '../../../models/weather_model.dart';
import '../../../utils/wind_direction.dart';
import '../../../widgets/fish_activity_indicator.dart';
import '../../../widgets/premium_widgets.dart';
import 'tide_timeline_bar.dart';
import 'wind_coast_compass.dart';

/// The Summary's compact instrument. All readings come from the selected hour.
class CircularFishingDashboard extends StatelessWidget {
  const CircularFishingDashboard({
    super.key,
    required this.hour,
    required this.dayHours,
    this.coast,
    this.loading = false,
  });

  final FishingForecastHour hour;
  final List<FishingForecastHour> dayHours;
  final CoastOrientation? coast;
  final bool loading;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final diameter = math.min(constraints.maxWidth, 430.0);
      return Center(
        child: SizedBox.square(
          dimension: diameter,
          child: Stack(
            alignment: Alignment.center,
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween(end: hour.score.score / 100),
                duration: const Duration(milliseconds: 650),
                curve: Curves.easeOutCubic,
                builder: (context, progress, child) => CustomPaint(
                  size: Size.square(diameter),
                  painter: _DashboardRingPainter(progress: progress),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(diameter * .105),
                child: FittedBox(
                  fit: BoxFit.contain,
                  child: SizedBox(
                    width: 284,
                    height: 348,
                    child: loading ? _loadingContent() : _content(),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );

  Widget _content() => Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _metricTap(
            'air',
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  weatherIconFor(hour.weatherCode),
                  color: AppColors.glow,
                  size: 26,
                ),
                const SizedBox(width: 8),
                Text(
                  '${hour.temperatureC.round()}°',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    height: 1,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 13),
          _metricTap(
            'feels',
            Text(
              'Feels ${hour.feelsLikeC.round()}°',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: 8),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _reading(
            Icons.water_drop_rounded,
            'Rain',
            '${hour.rainChance}%',
            'rain',
          ),
          _reading(
            Icons.cloud_rounded,
            'Cloud',
            '${hour.cloudCover}%',
            'cloud',
          ),
          _reading(
            Icons.speed_rounded,
            'Pressure',
            '${hour.pressureHpa.round()}${hour.pressureTrend == 'Rising'
                ? '↑'
                : hour.pressureTrend == 'Falling'
                ? '↓'
                : '→'}',
            'pressure',
          ),
        ],
      ),
      const SizedBox(height: 8),
      Divider(color: Colors.white.withValues(alpha: .18), height: 1),
      const SizedBox(height: 7),
      Row(
        children: [
          Expanded(
            child: _primaryReading(
              Icons.air_rounded,
              'WIND',
              '${hour.windKmh.round()} km/h',
              WindDirection.fromDegrees(hour.windDegrees),
              'wind',
              leading: WindCoastCompass(
                windFromDegrees: hour.windDegrees,
                size: 17,
              ),
              extra: coast == null
                  ? 'COAST —'
                  : coast!
                        .relationForWind(hour.windDegrees)
                        .label
                        .toUpperCase(),
            ),
          ),
          _metricTap('time', _timePill(hour.localTime)),
          Expanded(
            child: _primaryReading(
              Icons.waves_rounded,
              'WAVES',
              '${hour.waveM.toStringAsFixed(1)} m',
              WindDirection.fromDegrees(hour.waveDegrees),
              'waves',
            ),
          ),
        ],
      ),
      const SizedBox(height: 3),
      _metricTap(
        'tide',
        TideTimelineBar(hours: dayHours, selectedHour: hour.localTime.hour),
        keySuffix: 'tide-bar',
      ),
      const SizedBox(height: 3),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _reading(
            Icons.swap_vert_rounded,
            'Tide',
            hour.tideHeightM == null
                ? '—'
                : '${hour.tideHeightM!.toStringAsFixed(1)} m',
            'tide',
          ),
          _reading(
            Icons.waves_rounded,
            'Period',
            '${hour.wavePeriodSeconds} s',
            'period',
          ),
          _reading(
            Icons.water_rounded,
            'Swell',
            '${hour.swellM.toStringAsFixed(1)} m',
            'swell',
          ),
          _reading(
            Icons.thermostat_rounded,
            'Sea',
            '${hour.waterC.round()}°',
            'sea',
          ),
        ],
      ),
      const SizedBox(height: 3),
      Divider(color: Colors.white.withValues(alpha: .18), height: 1),
      const SizedBox(height: 7),
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _metricTap(
            'score',
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${hour.score.score}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 31,
                    height: 1,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const Text(
                  '/100',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(width: 1, height: 28, color: Colors.white24),
          const SizedBox(width: 12),
          _metricTap(
            'activity',
            FishActivityIndicator(
              fishingScore: hour.score.score,
              isBestTime: hour.isBestHour,
              compact: true,
            ),
          ),
        ],
      ),
    ],
  );

  Widget _loadingContent() => Column(
    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
    children: const [
      LoadingLine(width: 130, height: 27, light: true),
      LoadingLine(width: 220, height: 16, light: true),
      LoadingLine(width: 245, height: 45, light: true),
      LoadingLine(width: 215, height: 16, light: true),
      LoadingLine(width: 155, height: 30, light: true),
    ],
  );

  Widget _reading(IconData icon, String label, String value, String metric) =>
      _metricTap(
        metric,
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppColors.glow, size: 17),
            const SizedBox(height: 2),
            Text(
              value,
              maxLines: 1,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              label.toUpperCase(),
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 8,
                fontWeight: FontWeight.w800,
                letterSpacing: .45,
              ),
            ),
          ],
        ),
      );

  Widget _primaryReading(
    IconData icon,
    String label,
    String value,
    String direction,
    String metric, {
    Widget? leading,
    String? extra,
  }) => _metricTap(
    metric,
    Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            leading ?? Icon(icon, size: 16, color: AppColors.glow),
            const SizedBox(width: 3),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 9,
                fontWeight: FontWeight.w900,
                letterSpacing: .4,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w900,
          ),
        ),
        Text(
          direction,
          style: const TextStyle(color: AppColors.glow, fontSize: 10),
        ),
        if (extra != null)
          Text(
            extra,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: coast == null ? Colors.white54 : AppColors.glow,
              fontSize: 8,
              fontWeight: FontWeight.w900,
              letterSpacing: .4,
            ),
          ),
      ],
    ),
  );

  Widget _timePill(DateTime localTime) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
    decoration: BoxDecoration(
      color: AppColors.aqua,
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(color: AppColors.aqua.withValues(alpha: .26), blurRadius: 14),
      ],
    ),
    child: Text(
      '${localTime.hour.toString().padLeft(2, '0')}:${localTime.minute.toString().padLeft(2, '0')}',
      style: const TextStyle(
        color: AppColors.deep,
        fontSize: 19,
        fontWeight: FontWeight.w900,
      ),
    ),
  );

  Widget _metricTap(String metric, Widget child, {String? keySuffix}) =>
      Builder(
        builder: (context) => Semantics(
          button: true,
          child: GestureDetector(
            key: Key('circle-metric-${keySuffix ?? metric}'),
            behavior: HitTestBehavior.opaque,
            onTap: () => _showExplanation(context, metric),
            child: child,
          ),
        ),
      );

  void _showExplanation(BuildContext context, String metric) {
    final info = _explanation(metric);
    showDialog<void>(
      context: context,
      barrierColor: Colors.black54,
      builder: (dialogContext) => Dialog(
        key: const Key('circle-info-popup'),
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 28),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 340),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: oceanGradient,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: AppColors.glow.withValues(alpha: .32)),
              boxShadow: [
                BoxShadow(
                  color: AppColors.deep.withValues(alpha: .27),
                  blurRadius: 24,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(info.icon, color: AppColors.glow, size: 22),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Text(
                        info.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Close explanation',
                      onPressed: () => Navigator.of(dialogContext).pop(),
                      icon: const Icon(
                        Icons.close_rounded,
                        color: Colors.white70,
                      ),
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  info.value,
                  style: const TextStyle(
                    color: AppColors.glow,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  info.description,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String get _coastWindDescription {
    final orientation = coast;
    if (orientation == null) {
      return 'Coast relation is unavailable because no nearby shoreline direction was found.';
    }
    final relation = orientation.relationForWind(hour.windDegrees);
    final meaning = switch (relation) {
      CoastWindRelation.onshore =>
        'Onshore means wind travels from sea toward land.',
      CoastWindRelation.offshore =>
        'Offshore means wind travels from land toward sea.',
      CoastWindRelation.alongshore =>
        'Alongshore means wind travels mostly parallel to the coast.',
    };
    final source = orientation.approximate
        ? 'The coast direction here is approximate.'
        : 'Coast direction uses nearby OpenStreetMap shoreline data (© OpenStreetMap contributors).';
    return '$meaning $source';
  }

  ({String title, String value, String description, IconData icon})
  _explanation(String metric) => switch (metric) {
    'air' => (
      title: 'Air temperature',
      value: '${hour.temperatureC.round()}°C',
      description:
          '${WeatherModel.descriptionFor(hour.weatherCode)} at the selected hour. Air temperature helps you plan clothing and comfort by the water.',
      icon: weatherIconFor(hour.weatherCode),
    ),
    'feels' => (
      title: 'Feels like',
      value: '${hour.feelsLikeC.round()}°C',
      description: 'How warm or cool the air feels after wind and humidity are considered.',
      icon: Icons.thermostat_rounded,
    ),
    'rain' => (
      title: 'Rain',
      value: '${hour.rainChance}% chance',
      description:
          'Chance of precipitation during this hour. Expected amount: ${hour.precipitationMm.toStringAsFixed(1)} mm.',
      icon: Icons.water_drop_rounded,
    ),
    'cloud' => (
      title: 'Cloud cover',
      value: '${hour.cloudCover}%',
      description: 'The share of sky covered by clouds. More cloud can soften bright light over the water.',
      icon: Icons.cloud_rounded,
    ),
    'pressure' => (
      title: 'Atmospheric pressure',
      value: '${hour.pressureHpa.round()} hPa',
      description:
          'Pressure is ${hour.pressureTrend.toLowerCase()}. Changes in pressure can accompany changing weather.',
      icon: Icons.speed_rounded,
    ),
    'wind' => (
      title: 'Wind',
      value:
          '${hour.windKmh.round()} km/h · ${WindDirection.fromDegrees(hour.windDegrees)}${coast == null ? '' : ' · ${coast!.relationForWind(hour.windDegrees).label}'}',
      description:
          'The compass points where wind comes from. Gusts may reach ${hour.gustKmh.round()} km/h. $_coastWindDescription',
      icon: Icons.explore_rounded,
    ),
    'time' => (
      title: 'Selected time',
      value:
          '${hour.localTime.hour.toString().padLeft(2, '0')}:${hour.localTime.minute.toString().padLeft(2, '0')}',
      description: 'The readings in the circle are for this local hour. Move the time slider to explore the rest of the day.',
      icon: Icons.schedule_rounded,
    ),
    'waves' => (
      title: 'Waves',
      value: '${hour.waveM.toStringAsFixed(1)} m',
      description:
          'Significant wave height, traveling from ${WindDirection.fromDegrees(hour.waveDegrees)}. Check local surf and safety conditions before entering the water.',
      icon: Icons.waves_rounded,
    ),
    'tide' => (
      title: 'Tide',
      value:
          '${hour.tidePhase}${hour.tideHeightM == null ? '' : ' · ${hour.tideHeightM!.toStringAsFixed(2)} m'}',
      description: hour.usesSampleTide
          ? 'A sea-level forecast is unavailable for this hour. Check a local tide table before fishing.'
          : 'Modeled sea level is ${hour.tidePhase.toLowerCase()} at this hour. The line shows the forecast trend; it is not a local tide table.',
      icon: Icons.swap_vert_rounded,
    ),
    'period' => (
      title: 'Wave period',
      value: '${hour.wavePeriodSeconds} s',
      description: 'Time between wave crests. A longer period can mean more energy in each wave, even when wave height looks modest.',
      icon: Icons.waves_rounded,
    ),
    'swell' => (
      title: 'Swell',
      value: '${hour.swellM.toStringAsFixed(1)} m',
      description:
          'Longer-traveling waves coming from ${WindDirection.fromDegrees(hour.swellDegrees)}. Swell can differ from locally wind-made waves.',
      icon: Icons.water_rounded,
    ),
    'sea' => (
      title: 'Sea temperature',
      value: '${hour.waterC.round()}°C',
      description: 'Temperature at the sea surface. It can influence where fish are comfortable and active.',
      icon: Icons.thermostat_rounded,
    ),
    'score' => (
      title: 'Conditions index',
      value: '${hour.score.score}/100 · ${hour.score.label}',
      description: 'An indicative rating calculated from forecast wind, gusts, waves, rain and dawn or dusk. It does not predict catches or replace local safety checks.',
      icon: Icons.insights_rounded,
    ),
    _ => (
      title: 'Conditions indicator',
      value: '${hour.score.activeFishCount} of 4 fish active',
      description: 'The fish icons visualize the conditions index. They do not detect fish or predict a catch.',
      icon: Icons.set_meal_rounded,
    ),
  };
}

class _DashboardRingPainter extends CustomPainter {
  const _DashboardRingPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2 - 12;
    final rect = Rect.fromCircle(center: center, radius: radius);
    canvas.drawCircle(
      center,
      radius + 9,
      Paint()
        ..color = Colors.white.withValues(alpha: .14)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
    canvas.drawArc(
      rect,
      -math.pi / 2,
      2 * math.pi,
      false,
      Paint()
        ..color = Colors.white.withValues(alpha: .20)
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 11,
    );
    canvas.drawArc(
      rect,
      -math.pi / 2,
      2 * math.pi * progress.clamp(0, 1),
      false,
      Paint()
        ..shader = const SweepGradient(
          startAngle: -math.pi / 2,
          endAngle: math.pi * 3 / 2,
          colors: [
            AppColors.blue,
            AppColors.aqua,
            AppColors.glow,
            AppColors.aqua,
          ],
        ).createShader(rect)
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 11,
    );
    for (var i = 0; i < 4; i++) {
      final angle = -math.pi / 2 + i * math.pi / 2;
      final point = center + Offset(math.cos(angle), math.sin(angle)) * radius;
      canvas.drawCircle(point, 3.3, Paint()..color = AppColors.deep);
      canvas.drawCircle(point, 1.5, Paint()..color = AppColors.glow);
    }
  }

  @override
  bool shouldRepaint(covariant _DashboardRingPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
