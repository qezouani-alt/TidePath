import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../models/fishing_forecast.dart';
import '../../../widgets/premium_widgets.dart';

class TideDetailsCard extends StatelessWidget {
  const TideDetailsCard({
    super.key,
    required this.days,
    required this.selectedDay,
    required this.selectedHour,
  });

  final List<FishingForecastDay> days;
  final int selectedDay, selectedHour;

  @override
  Widget build(BuildContext context) {
    final day = days[selectedDay];
    final hour = day.hours[selectedHour];
    final upcoming = days
        .skip(selectedDay)
        .expand((forecast) => forecast.hours)
        .toList();
    final nextHigh = _nextTurningPoint(upcoming, hour.timeUtc, high: true);
    final nextLow = _nextTurningPoint(upcoming, hour.timeUtc, high: false);
    final nextEvent = [nextHigh, nextLow]
        .whereType<FishingForecastHour>()
        .fold<FishingForecastHour?>(null, (earliest, candidate) {
          if (earliest == null ||
              candidate.timeUtc.isBefore(earliest.timeUtc)) {
            return candidate;
          }
          return earliest;
        });
    final measured = day.hours.where((point) => point.tideHeightM != null);
    final hasCurve = measured.length >= 2;
    final heights = hasCurve
        ? day.hours.map((point) => point.tideHeightM ?? 0).toList()
        : <double>[];
    final tideSource = hasCurve ? 'Modeled sea level' : 'Data unavailable';

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
                'TIDE WATCH',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 13),
              Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: .14),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      hour.tidePhase == 'Falling'
                          ? Icons.south_rounded
                          : Icons.north_rounded,
                      color: AppColors.glow,
                      size: 29,
                    ),
                  ),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          hour.usesSampleTide
                              ? 'Tide unavailable'
                              : '${hour.tidePhase} sea level',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 23,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          hour.tideHeightM == null
                              ? 'Height unavailable · $tideSource'
                              : '${hour.tideHeightM!.toStringAsFixed(2)} m · $tideSource',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              Text(
                nextEvent == null
                    ? 'Next tide change is unavailable'
                    : 'Next ${nextEvent == nextHigh ? 'high' : 'low'} tide in ${_duration(nextEvent.timeUtc.difference(hour.timeUtc))}',
                style: const TextStyle(
                  color: AppColors.glow,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _EventTile(
                label: 'NEXT HIGH',
                time: _clock(nextHigh?.localTime),
                height: nextHigh?.tideHeightM,
                icon: Icons.arrow_upward_rounded,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _EventTile(
                label: 'NEXT LOW',
                time: _clock(nextLow?.localTime),
                height: nextLow?.tideHeightM,
                icon: Icons.arrow_downward_rounded,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '24-hour tide curve',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  Text(
                    hasCurve ? 'MODELED' : 'UNAVAILABLE',
                    style: const TextStyle(
                      color: AppColors.blue,
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              SizedBox(
                height: 150,
                width: double.infinity,
                child: hasCurve
                    ? CustomPaint(
                        painter: _TideCurvePainter(heights, selectedHour),
                      )
                    : const Center(
                        child: Text('Sea-level forecast unavailable'),
                      ),
              ),
              const SizedBox(height: 8),
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('0h', style: _axisStyle),
                  Text('6h', style: _axisStyle),
                  Text('12h', style: _axisStyle),
                  Text('18h', style: _axisStyle),
                  Text('0h', style: _axisStyle),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        AppCard(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.info_outline_rounded, color: AppColors.blue),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Modeled sea level can help show water movement, but it is not a local tide table. At this hour, waves are ${hour.waveM.toStringAsFixed(1)} m with a ${hour.wavePeriodSeconds} s period.',
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
        const SizedBox(height: 8),
        const Text(
          'Modeled sea level is an estimate, not a navigation-grade tide table.',
          style: TextStyle(color: AppColors.muted, fontSize: 10),
        ),
      ],
    );
  }

  static FishingForecastHour? _nextTurningPoint(
    List<FishingForecastHour> hours,
    DateTime selectedUtc, {
    required bool high,
  }) {
    for (var index = 1; index < hours.length - 1; index++) {
      final previous = hours[index - 1].tideHeightM;
      final current = hours[index].tideHeightM;
      final next = hours[index + 1].tideHeightM;
      if (previous == null || current == null || next == null) continue;
      if (!hours[index].timeUtc.isAfter(selectedUtc)) continue;
      if (high && current >= previous && current > next) return hours[index];
      if (!high && current <= previous && current < next) return hours[index];
    }
    return null;
  }

  static String _clock(DateTime? date) {
    if (date == null) return '—';
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  static String _duration(Duration duration) {
    if (duration.isNegative) return '—';
    return '${duration.inHours}h ${duration.inMinutes.remainder(60)}m';
  }
}

const _axisStyle = TextStyle(
  color: AppColors.muted,
  fontSize: 10,
  fontWeight: FontWeight.w700,
);

class _EventTile extends StatelessWidget {
  const _EventTile({
    required this.label,
    required this.time,
    required this.height,
    required this.icon,
  });

  final String label, time;
  final double? height;
  final IconData icon;

  @override
  Widget build(BuildContext context) => AppCard(
    padding: const EdgeInsets.all(14),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.aqua, size: 22),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.muted,
            fontSize: 9,
            fontWeight: FontWeight.w900,
            letterSpacing: .6,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          time,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 17,
            fontWeight: FontWeight.w900,
          ),
        ),
        if (height != null)
          Text(
            '${height!.toStringAsFixed(2)} m',
            style: const TextStyle(color: AppColors.muted, fontSize: 11),
          ),
      ],
    ),
  );
}

class _TideCurvePainter extends CustomPainter {
  const _TideCurvePainter(this.heights, this.selectedHour);

  final List<double> heights;
  final int selectedHour;

  @override
  void paint(Canvas canvas, Size size) {
    if (heights.length < 2) return;
    final minHeight = heights.reduce(math.min);
    final maxHeight = heights.reduce(math.max);
    final span = (maxHeight - minHeight).abs() < .01
        ? 1.0
        : maxHeight - minHeight;
    Offset point(int index) => Offset(
      index / (heights.length - 1) * size.width,
      size.height -
          12 -
          (heights[index] - minHeight) / span * (size.height - 26),
    );
    final path = Path()..moveTo(point(0).dx, point(0).dy);
    for (var index = 1; index < heights.length; index++) {
      path.lineTo(point(index).dx, point(index).dy);
    }
    final fill = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(
      fill,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0x5522BFCA), Color(0x0016B8C4)],
        ).createShader(Offset.zero & size),
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = AppColors.aqua
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke,
    );
    final selected = point(selectedHour.clamp(0, heights.length - 1));
    canvas.drawCircle(
      selected,
      7,
      Paint()..color = AppColors.aqua.withValues(alpha: .18),
    );
    canvas.drawCircle(selected, 4, Paint()..color = AppColors.blue);
  }

  @override
  bool shouldRepaint(covariant _TideCurvePainter oldDelegate) =>
      oldDelegate.selectedHour != selectedHour ||
      oldDelegate.heights != heights;
}
