import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import 'premium_widgets.dart';

class WindDirectionIndicator extends StatelessWidget {
  const WindDirectionIndicator({
    super.key,
    required this.degrees,
    this.size = 21,
  });

  final int degrees;
  final double size;

  @override
  Widget build(BuildContext context) => AnimatedRotation(
    turns: (degrees % 360) / 360,
    duration: const Duration(milliseconds: 350),
    curve: Curves.easeOutCubic,
    child: Icon(Icons.navigation_rounded, size: size, color: AppColors.glow),
  );
}

class TideDirectionIndicator extends StatelessWidget {
  const TideDirectionIndicator({super.key, required this.phase});

  final String phase;

  @override
  Widget build(BuildContext context) => AnimatedRotation(
    turns: phase == 'Falling' ? .5 : 0,
    duration: const Duration(milliseconds: 350),
    curve: Curves.easeOutCubic,
    child: const Icon(
      Icons.arrow_upward_rounded,
      size: 20,
      color: AppColors.glow,
    ),
  );
}

class FishingMetricItem extends StatelessWidget {
  const FishingMetricItem({
    super.key,
    required this.label,
    required this.value,
    required this.detail,
    this.indicator,
    this.loading = false,
  });

  final String label, value, detail;
  final Widget? indicator;
  final bool loading;

  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(minHeight: 77),
    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 10),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: .085),
      borderRadius: BorderRadius.circular(15),
      border: Border.all(color: Colors.white.withValues(alpha: .10)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 9,
            fontWeight: FontWeight.w800,
            letterSpacing: .6,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            if (indicator != null) ...[indicator!, const SizedBox(width: 4)],
            Expanded(
              child: loading
                  ? const LoadingLine(width: 75, height: 15, light: true)
                  : FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        value,
                        maxLines: 1,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          detail,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: Colors.white70, fontSize: 10),
        ),
      ],
    ),
  );
}
