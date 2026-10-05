import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../models/fishing_forecast.dart';

/// A compact tide curve that shows the water rising and falling through the day.
class TideTimelineBar extends StatelessWidget {
  const TideTimelineBar({
    super.key,
    required this.hours,
    required this.selectedHour,
  });

  final List<FishingForecastHour> hours;
  final int selectedHour;

  @override
  Widget build(BuildContext context) {
    final selected = hours[selectedHour];
    if (selected.tideHeightM == null) {
      return const SizedBox(
        key: Key('circle-tide-bar'),
        height: 39,
        child: Center(
          child: Text(
            'TIDE DATA UNAVAILABLE',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 9,
              fontWeight: FontWeight.w800,
              letterSpacing: .5,
            ),
          ),
        ),
      );
    }
    final falling = selected.tidePhase == 'Falling';
    final available = <int>[
      for (var index = 0; index < hours.length; index++)
        if (hours[index].tideHeightM != null) index,
    ];
    final high = available.isEmpty
        ? null
        : available.reduce(
            (a, b) => hours[a].tideHeightM! >= hours[b].tideHeightM! ? a : b,
          );
    final low = available.isEmpty
        ? null
        : available.reduce(
            (a, b) => hours[a].tideHeightM! <= hours[b].tideHeightM! ? a : b,
          );
    final levels = hours.map((hour) => hour.tideHeightM ?? 0).toList();
    return Semantics(
      label:
          '${falling ? 'Falling' : 'Rising'} tide, selected hour $selectedHour, '
          'high tide around ${high ?? 'unknown'} hours, '
          'low tide around ${low ?? 'unknown'} hours',
      child: SizedBox(
        key: const Key('circle-tide-bar'),
        height: 39,
        width: double.infinity,
        child: Column(
          children: [
            Row(
              children: [
                Icon(
                  falling ? Icons.south_rounded : Icons.north_rounded,
                  color: AppColors.glow,
                  size: 11,
                ),
                const SizedBox(width: 2),
                Text(
                  falling ? 'FALLING TIDE' : 'RISING TIDE',
                  style: const TextStyle(
                    color: AppColors.glow,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    letterSpacing: .55,
                  ),
                ),
                const Spacer(),
                if (selected.tideHeightM != null)
                  Text(
                    '${selected.tideHeightM!.toStringAsFixed(1)} m',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 1),
            Expanded(
              child: CustomPaint(
                size: Size.infinite,
                painter: _TideTimelinePainter(
                  selectedHour: selectedHour,
                  highHour: high,
                  lowHour: low,
                  levels: levels,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TideTimelinePainter extends CustomPainter {
  const _TideTimelinePainter({
    required this.selectedHour,
    required this.highHour,
    required this.lowHour,
    required this.levels,
  });

  final int selectedHour;
  final int? highHour, lowHour;
  final List<double> levels;

  @override
  void paint(Canvas canvas, Size size) {
    if (levels.length < 2) return;
    final lowest = levels.reduce(math.min);
    final highest = levels.reduce(math.max);
    final span = (highest - lowest).abs() < .01 ? 1.0 : highest - lowest;
    Offset point(int index) => Offset(
      5 + index / (levels.length - 1) * (size.width - 10),
      size.height - 3 - (levels[index] - lowest) / span * (size.height - 6),
    );
    final curve = Path()..moveTo(point(0).dx, point(0).dy);
    for (var index = 1; index < levels.length; index++) {
      curve.lineTo(point(index).dx, point(index).dy);
    }
    canvas.drawPath(
      curve,
      Paint()
        ..color = Colors.white.withValues(alpha: .33)
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke,
    );
    final activeStart = (selectedHour - 3).clamp(0, levels.length - 1);
    final activeEnd = (selectedHour + 1).clamp(0, levels.length - 1);
    final trend = Path()..moveTo(point(activeStart).dx, point(activeStart).dy);
    for (var index = activeStart + 1; index <= activeEnd; index++) {
      trend.lineTo(point(index).dx, point(index).dy);
    }
    canvas.drawPath(
      trend,
      Paint()
        ..color = AppColors.glow
        ..strokeWidth = 3.5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke,
    );
    if (highHour != null) {
      canvas.drawCircle(point(highHour!), 2.5, Paint()..color = AppColors.aqua);
    }
    if (lowHour != null) {
      canvas.drawCircle(point(lowHour!), 2.5, Paint()..color = Colors.white70);
    }
    final selected = point(selectedHour.clamp(0, levels.length - 1));
    canvas.drawCircle(
      selected,
      5.5,
      Paint()..color = AppColors.glow.withValues(alpha: .28),
    );
    canvas.drawCircle(selected, 3, Paint()..color = AppColors.glow);
  }

  @override
  bool shouldRepaint(covariant _TideTimelinePainter oldDelegate) =>
      oldDelegate.selectedHour != selectedHour ||
      oldDelegate.highHour != highHour ||
      oldDelegate.lowHour != lowHour ||
      oldDelegate.levels != levels;
}
