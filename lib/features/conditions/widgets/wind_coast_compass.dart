import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

/// Points toward the compass bearing that the wind comes from.
class WindCoastCompass extends StatelessWidget {
  const WindCoastCompass({
    super.key,
    required this.windFromDegrees,
    this.size = 19,
  });

  final int windFromDegrees;
  final double size;

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Wind comes from $windFromDegrees degrees',
    child: SizedBox.square(
      dimension: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.glow.withValues(alpha: .10),
              border: Border.all(color: AppColors.glow.withValues(alpha: .70)),
            ),
          ),
          AnimatedRotation(
            turns: (windFromDegrees % 360) / 360,
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeOutCubic,
            child: Icon(
              Icons.navigation_rounded,
              size: size * .67,
              color: AppColors.glow,
            ),
          ),
        ],
      ),
    ),
  );
}
