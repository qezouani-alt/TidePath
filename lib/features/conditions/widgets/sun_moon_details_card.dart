import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../models/fishing_conditions.dart';
import '../../../models/fishing_forecast.dart';
import '../../../widgets/premium_widgets.dart';

class SunMoonDetailsCard extends StatelessWidget {
  const SunMoonDetailsCard({
    super.key,
    required this.conditions,
    required this.day,
    required this.hour,
    required this.dayOffset,
  });

  final FishingConditions conditions;
  final FishingForecastDay day;
  final FishingForecastHour hour;
  final int dayOffset;

  @override
  Widget build(BuildContext context) {
    final sourceDay = _sourceDay();
    final sunrise =
        sourceDay?.sunriseUtc ??
        conditions.weather.sunriseUtc.add(Duration(days: dayOffset));
    final sunset =
        sourceDay?.sunsetUtc ??
        conditions.weather.sunsetUtc.add(Duration(days: dayOffset));
    final goldenStart = sunset.subtract(const Duration(hours: 1));
    final daylight = sunset.difference(sunrise).inSeconds;
    final elapsed = hour.timeUtc.difference(sunrise).inSeconds;
    final progress = daylight <= 0 ? 0.0 : (elapsed / daylight).clamp(0.0, 1.0);
    final nearSunrise =
        hour.timeUtc.difference(sunrise).abs() <= const Duration(hours: 1);
    final nearSunset =
        hour.timeUtc.difference(sunset).abs() <= const Duration(hours: 1);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: oceanGradient,
            borderRadius: BorderRadius.circular(27),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'SUN & LIGHT',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 5),
              const Text(
                'Find the softer light',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 22),
              SizedBox(
                height: 105,
                width: double.infinity,
                child: CustomPaint(painter: _SunArcPainter(progress)),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _SunTime(
                      label: 'SUNRISE',
                      value: conditions.clock(sunrise),
                      icon: Icons.wb_twilight_rounded,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _SunTime(
                      label: 'SUNSET',
                      value: conditions.clock(sunset),
                      icon: Icons.nights_stay_outlined,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        AppCard(
          child: Row(
            children: [
              Container(
                width: 43,
                height: 43,
                decoration: BoxDecoration(
                  color: AppColors.mist,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(
                  Icons.wb_sunny_outlined,
                  color: AppColors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Golden hour',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${conditions.clock(goldenStart)} – ${conditions.clock(sunset)}',
                      style: const TextStyle(
                        color: AppColors.blue,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const Text(
                      'Approximate hour before sunset',
                      style: TextStyle(color: AppColors.muted, fontSize: 10),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Moon conditions',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 19,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Sample lunar values until a moon data source is connected.',
          style: TextStyle(color: AppColors.muted, fontSize: 11),
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final width = (constraints.maxWidth - 10) / 2;
            return Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                SizedBox(
                  width: width,
                  child: const _MoonTile(
                    'PHASE',
                    'Waxing gibbous',
                    Icons.brightness_2_outlined,
                  ),
                ),
                SizedBox(
                  width: width,
                  child: const _MoonTile(
                    'ILLUMINATION',
                    '62%',
                    Icons.brightness_4_outlined,
                  ),
                ),
                SizedBox(
                  width: width,
                  child: const _MoonTile(
                    'MOONRISE',
                    '15:42',
                    Icons.arrow_upward_rounded,
                  ),
                ),
                SizedBox(
                  width: width,
                  child: const _MoonTile(
                    'MOONSET',
                    '04:18',
                    Icons.arrow_downward_rounded,
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 14),
        AppCard(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.auto_awesome_outlined, color: AppColors.blue),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  nearSunrise || nearSunset
                      ? 'Your selected hour is near softer light. Dawn and dusk contribute to the indicative conditions index.'
                      : 'Sunrise and sunset help plan low-light fishing. The conditions index is based on the forecast, not on observed fish.',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 12,
                    height: 1.45,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  WeatherDay? _sourceDay() {
    for (final candidate in conditions.weather.days) {
      if (candidate.dateLocal.year == day.dateLocal.year &&
          candidate.dateLocal.month == day.dateLocal.month &&
          candidate.dateLocal.day == day.dateLocal.day) {
        return candidate;
      }
    }
    return null;
  }
}

class _SunTime extends StatelessWidget {
  const _SunTime({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label, value;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, color: AppColors.glow, size: 22),
      const SizedBox(width: 7),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 9,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

class _MoonTile extends StatelessWidget {
  const _MoonTile(this.label, this.value, this.icon);

  final String label, value;
  final IconData icon;

  @override
  Widget build(BuildContext context) => AppCard(
    padding: const EdgeInsets.all(14),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.blue, size: 22),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.muted,
            fontSize: 9,
            fontWeight: FontWeight.w900,
            letterSpacing: .5,
          ),
        ),
        const SizedBox(height: 4),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    ),
  );
}

class _SunArcPainter extends CustomPainter {
  const _SunArcPainter(this.progress);

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final left = Offset(10, size.height - 8);
    final right = Offset(size.width - 10, size.height - 8);
    final center = Offset(size.width / 2, -size.height * .18);
    final path = Path()
      ..moveTo(left.dx, left.dy)
      ..quadraticBezierTo(center.dx, center.dy, right.dx, right.dy);
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.white.withValues(alpha: .38)
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke,
    );
    canvas.drawLine(
      left,
      right,
      Paint()
        ..color = Colors.white.withValues(alpha: .2)
        ..strokeWidth = 1,
    );
    final t = progress.clamp(0.0, 1.0);
    final oneMinus = 1 - t;
    final sun = Offset(
      oneMinus * oneMinus * left.dx +
          2 * oneMinus * t * center.dx +
          t * t * right.dx,
      oneMinus * oneMinus * left.dy +
          2 * oneMinus * t * center.dy +
          t * t * right.dy,
    );
    canvas.drawCircle(
      sun,
      17,
      Paint()
        ..color = AppColors.glow.withValues(alpha: .18)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
    );
    canvas.drawCircle(sun, 8, Paint()..color = AppColors.glow);
    canvas.drawCircle(left, 3, Paint()..color = Colors.white70);
    canvas.drawCircle(right, 3, Paint()..color = Colors.white70);
  }

  @override
  bool shouldRepaint(covariant _SunArcPainter oldDelegate) =>
      (oldDelegate.progress - progress).abs() > 1 / math.pow(10, 3);
}
