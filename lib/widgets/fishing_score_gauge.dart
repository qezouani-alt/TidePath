import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import 'fish_activity_indicator.dart';
import 'premium_widgets.dart';

/// A segmented marine instrument for the selected forecast hour.
class FishingScoreGauge extends StatelessWidget {
  const FishingScoreGauge({
    super.key,
    required this.score,
    required this.label,
    required this.isBestTime,
    this.loading = false,
    this.size = 250,
  });

  final int score;
  final String label;
  final bool isBestTime, loading;
  final double size;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween(begin: 0, end: score.clamp(0, 100) / 100),
    duration: const Duration(milliseconds: 750),
    curve: Curves.easeOutCubic,
    builder: (context, progress, _) => SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _MarineGaugePainter(progress),
        child: Padding(
          padding: const EdgeInsets.all(36),
          child: DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  const Color(0xFF147C9C).withValues(alpha: .34),
                  const Color(0xFF063C59).withValues(alpha: .12),
                ],
              ),
              border: Border.all(color: Colors.white.withValues(alpha: .08)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (loading)
                  const LoadingLine(width: 53, height: 35, light: true)
                else
                  Text(
                    '${(progress * 100).round()}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 40,
                      height: 1,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -1.7,
                    ),
                  ),
                const Text(
                  '/ 100',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                FishActivityIndicator(
                  fishingScore: score,
                  isBestTime: isBestTime,
                  compact: true,
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class _MarineGaugePainter extends CustomPainter {
  const _MarineGaugePainter(this.progress);

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2 - 19;
    const segments = 32;
    const gap = .045;
    final sweep = math.pi * 2 / segments - gap;
    final track = Paint()
      ..color = Colors.white.withValues(alpha: .14)
      ..strokeWidth = 9
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final colors = [
      AppColors.aqua,
      const Color(0xFF4ED8DD),
      const Color(0xFF79E9DC),
      const Color(0xFFB2F3DD),
    ];
    for (var index = 0; index < segments; index++) {
      final start = -math.pi / 2 + index * math.pi * 2 / segments;
      final rect = Rect.fromCircle(center: center, radius: radius);
      canvas.drawArc(rect, start, sweep, false, track);
      if (index < (progress * segments).round()) {
        final paint = Paint()
          ..color = colors[(index ~/ 8).clamp(0, 3)]
          ..strokeWidth = 9
          ..strokeCap = StrokeCap.round
          ..style = PaintingStyle.stroke;
        canvas.drawArc(rect, start, sweep, false, paint);
      }
    }
    for (var index = 0; index < 48; index++) {
      final angle = -math.pi / 2 + index * math.pi * 2 / 48;
      final major = index % 4 == 0;
      final from = radius + (major ? 12 : 14);
      final to = radius + 18;
      final paint = Paint()
        ..color = Colors.white.withValues(alpha: major ? .58 : .20)
        ..strokeWidth = major ? 1.5 : .8;
      canvas.drawLine(
        center + Offset(math.cos(angle) * from, math.sin(angle) * from),
        center + Offset(math.cos(angle) * to, math.sin(angle) * to),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _MarineGaugePainter oldDelegate) =>
      oldDelegate.progress != progress;
}
