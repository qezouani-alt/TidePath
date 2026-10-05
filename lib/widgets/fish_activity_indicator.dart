import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../models/fish_activity_level.dart';

export '../models/fish_activity_level.dart';

/// A compact activity readout for a dark, ocean-blue summary card.
/// Best-time emphasis changes the presentation, never the score or fish count.
class FishActivityIndicator extends StatelessWidget {
  const FishActivityIndicator({
    super.key,
    required this.fishingScore,
    this.activityLabel = 'Fish Activity',
    this.isBestTime = false,
    this.compact = false,
  });

  final int fishingScore;
  final String activityLabel;
  final bool isBestTime;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final level = FishActivityLevel.fromScore(fishingScore);
    final lively = level.activeFish >= 3;
    final emphasized = isBestTime || level == FishActivityLevel.perfect;
    const activeColor = AppColors.glow;

    return Semantics(
      label:
          '$activityLabel: ${level.label}, ${level.activeFish} of 4 fish active'
          '${isBestTime ? ', best fishing time now' : ''}',
      child: ExcludeSemantics(
        child: compact
            ? _CompactFishActivity(level: level, isBestTime: isBestTime)
            : AnimatedContainer(
                duration: const Duration(milliseconds: 350),
                curve: Curves.easeOutCubic,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: emphasized ? .15 : .10),
                  borderRadius: BorderRadius.circular(17),
                  border: Border.all(
                    color: emphasized
                        ? activeColor.withValues(alpha: .48)
                        : Colors.white.withValues(alpha: .12),
                  ),
                  boxShadow: emphasized
                      ? [
                          BoxShadow(
                            color: AppColors.aqua.withValues(alpha: .16),
                            blurRadius: 18,
                            spreadRadius: 1,
                          ),
                        ]
                      : null,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            activityLabel.toUpperCase(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: .8,
                            ),
                          ),
                        ),
                        if (isBestTime)
                          const Text(
                            'BEST TIME NOW',
                            style: TextStyle(
                              color: activeColor,
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              letterSpacing: .5,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        for (var index = 0; index < 4; index++) ...[
                          if (index > 0) const SizedBox(width: 5),
                          TweenAnimationBuilder<double>(
                            key: ValueKey('$fishingScore-$index'),
                            tween: Tween(begin: .92, end: 1),
                            duration: Duration(milliseconds: 420 + index * 60),
                            curve: Curves.easeOutCubic,
                            builder: (context, scale, child) =>
                                Transform.translate(
                                  offset: Offset(0, (1 - scale) * 24),
                                  child: Transform.scale(
                                    scale: scale,
                                    child: child,
                                  ),
                                ),
                            child: AnimatedContainer(
                              key: Key('fish-activity-icon-$index'),
                              duration: const Duration(milliseconds: 350),
                              width: 31,
                              height: 31,
                              decoration: BoxDecoration(
                                color: index < level.activeFish
                                    ? activeColor.withValues(alpha: .16)
                                    : Colors.white.withValues(alpha: .05),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                Icons.set_meal_rounded,
                                size: 21,
                                color: index < level.activeFish
                                    ? activeColor
                                    : Colors.white.withValues(alpha: .30),
                                shadows: lively && index < level.activeFish
                                    ? [
                                        Shadow(
                                          color: activeColor.withValues(
                                            alpha: emphasized ? .65 : .28,
                                          ),
                                          blurRadius: emphasized ? 9 : 4,
                                        ),
                                      ]
                                    : null,
                              ),
                            ),
                          ),
                        ],
                        const Spacer(),
                        Text(
                          level.label,
                          style: TextStyle(
                            color: emphasized ? activeColor : Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

class _CompactFishActivity extends StatelessWidget {
  const _CompactFishActivity({required this.level, required this.isBestTime});

  final FishActivityLevel level;
  final bool isBestTime;

  @override
  Widget build(BuildContext context) {
    const active = AppColors.glow;
    final strong = isBestTime || level == FishActivityLevel.perfect;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'FISH ACTIVITY',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 8,
            fontWeight: FontWeight.w800,
            letterSpacing: .8,
          ),
        ),
        const SizedBox(height: 3),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(
            4,
            (index) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Icon(
                Icons.set_meal_rounded,
                size: 17,
                color: index < level.activeFish
                    ? active
                    : Colors.white.withValues(alpha: .3),
                shadows: strong && index < level.activeFish
                    ? [
                        Shadow(
                          color: active.withValues(alpha: .65),
                          blurRadius: 7,
                        ),
                      ]
                    : null,
              ),
            ),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          level.label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}
