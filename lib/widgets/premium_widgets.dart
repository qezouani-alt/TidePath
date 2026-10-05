import 'dart:async';

import '../services/navigation_ad_service.dart';
import '../models/fish_activity_level.dart';

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../models/demo_data.dart';

const oceanGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [Color(0xFF087DAB), AppColors.ocean, AppColors.deep],
);

BoxDecoration premiumCard(BuildContext context, {double radius = 23}) =>
    BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(radius),
      boxShadow: [
        BoxShadow(
          color: const Color(0xFF17465C).withValues(alpha: .07),
          blurRadius: 24,
          offset: const Offset(0, 9),
        ),
      ],
    );

class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.onTap,
    this.color,
  });
  final Widget child;
  final EdgeInsets padding;
  final VoidCallback? onTap;
  final Color? color;
  @override
  Widget build(BuildContext context) => Container(
    decoration: color == null
        ? premiumCard(context)
        : premiumCard(context).copyWith(color: color),
    child: Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(23),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(23),
        child: Padding(padding: padding, child: child),
      ),
    ),
  );
}

class EntryReveal extends StatelessWidget {
  const EntryReveal({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween(begin: 0, end: 1),
    duration: const Duration(milliseconds: 360),
    curve: Curves.easeOutCubic,
    builder: (context, value, child) => Opacity(
      opacity: value,
      child: Transform.translate(
        offset: Offset(0, 10 * (1 - value)),
        child: child,
      ),
    ),
    child: child,
  );
}

class SkeletonCard extends StatefulWidget {
  const SkeletonCard({super.key, required this.height});
  final double height;
  @override
  State<SkeletonCard> createState() => _SkeletonCardState();
}

class _SkeletonCardState extends State<SkeletonCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);
  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: controller,
    builder: (context, _) => Container(
      height: widget.height,
      decoration: BoxDecoration(
        color: Color.lerp(
          AppColors.mist,
          const Color(0xFFDCECF2),
          controller.value,
        ),
        borderRadius: BorderRadius.circular(23),
      ),
    ),
  );
}

class SectionHeader extends StatelessWidget {
  const SectionHeader(
    this.title, {
    super.key,
    this.action,
    this.onAction,
    this.stackOnNarrow = false,
  });
  final String title;
  final String? action;
  final VoidCallback? onAction;
  final bool stackOnNarrow;

  Widget? _actionWidget() {
    if (action == null) return null;
    if (onAction == null) {
      return Text(
        action!,
        style: const TextStyle(
          color: AppColors.muted,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      );
    }
    return GestureDetector(
      onTap: onAction,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            action!,
            style: const TextStyle(
              color: AppColors.blue,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 3),
          const Icon(
            Icons.arrow_forward_ios_rounded,
            size: 12,
            color: AppColors.blue,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final titleWidget = Text(
        title,
        style: Theme.of(context).textTheme.titleLarge,
      );
      final actionWidget = _actionWidget();
      return Padding(
        padding: const EdgeInsets.only(bottom: 15),
        child:
            stackOnNarrow && constraints.maxWidth < 430 && actionWidget != null
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  titleWidget,
                  const SizedBox(height: 7),
                  Align(alignment: Alignment.centerRight, child: actionWidget),
                ],
              )
            : Row(
                children: [
                  Expanded(child: titleWidget),
                  ?actionWidget,
                ],
              ),
      );
    },
  );
}

class SeaPhoto extends StatelessWidget {
  const SeaPhoto({
    super.key,
    this.height,
    this.borderRadius = 0,
    this.alignment = Alignment.center,
    this.asset = 'assets/images/coast.png',
  });
  final double? height;
  final double borderRadius;
  final Alignment alignment;
  final String asset;
  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(borderRadius),
    child: SizedBox(
      height: height,
      width: double.infinity,
      child: Image.asset(
        asset,
        fit: BoxFit.cover,
        alignment: alignment,
        errorBuilder: (_, _, _) => DecoratedBox(
          decoration: const BoxDecoration(gradient: oceanGradient),
          child: const Center(
            child: Icon(Icons.waves_rounded, size: 76, color: Colors.white54),
          ),
        ),
      ),
    ),
  );
}

class ScoreRing extends StatefulWidget {
  const ScoreRing({
    super.key,
    this.score = 86,
    this.size = 116,
    this.dark = true,
  });
  final int score;
  final double size;
  final bool dark;
  @override
  State<ScoreRing> createState() => _ScoreRingState();
}

class _ScoreRingState extends State<ScoreRing>
    with SingleTickerProviderStateMixin {
  late final AnimationController controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..forward();
  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: controller,
    builder: (_, _) => SizedBox(
      width: widget.size,
      height: widget.size,
      child: CustomPaint(
        painter: _RingPainter(
          widget.score / 100 * Curves.easeOutCubic.transform(controller.value),
          widget.dark,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${(widget.score * controller.value).round()}',
              style: TextStyle(
                fontSize: widget.size * .31,
                color: widget.dark ? Colors.white : AppColors.ink,
                fontWeight: FontWeight.w800,
                height: 1,
              ),
            ),
            Text(
              '/ 100',
              style: TextStyle(
                fontSize: widget.size * .105,
                color: widget.dark ? Colors.white70 : AppColors.muted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _RingPainter extends CustomPainter {
  _RingPainter(this.value, this.dark);
  final double value;
  final bool dark;
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(8, 8, size.width - 16, size.height - 16);
    final base = Paint()
      ..color = dark ? Colors.white24 : AppColors.mist
      ..strokeWidth = 8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final active = Paint()
      ..color = dark ? const Color(0xFF70E5DE) : AppColors.aqua
      ..strokeWidth = 8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, -math.pi / 2, math.pi * 2, false, base);
    canvas.drawArc(rect, -math.pi / 2, math.pi * 2 * value, false, active);
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) =>
      oldDelegate.value != value || oldDelegate.dark != dark;
}

class FishingScoreCard extends StatelessWidget {
  const FishingScoreCard({
    super.key,
    this.onTap,
    this.score = 86,
    this.rating = 'Excellent',
    this.description = 'The ocean is on your side today.',
    this.bestTime = '06:15 – 09:30',
    this.airTemperature = '22°',
    this.airTemperatureLoading = false,
  });
  final VoidCallback? onTap;
  final int score;
  final String rating, description, bestTime, airTemperature;
  final bool airTemperatureLoading;
  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      gradient: oceanGradient,
      borderRadius: BorderRadius.circular(28),
      boxShadow: [
        BoxShadow(
          color: AppColors.blue.withValues(alpha: .23),
          blurRadius: 27,
          offset: const Offset(0, 13),
        ),
      ],
    ),
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(28),
        onTap: onTap,
        child: Stack(
          children: [
            Positioned(
              top: -54,
              right: -48,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: .08),
                    width: 32,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(23),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.auto_awesome_rounded,
                        color: Color(0xFFBDF8ED),
                        size: 18,
                      ),
                      const SizedBox(width: 7),
                      const Expanded(
                        child: Text(
                          'FISHING CONDITIONS TODAY',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.1,
                          ),
                        ),
                      ),
                      const Icon(
                        Icons.arrow_outward_rounded,
                        color: Colors.white70,
                        size: 18,
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$rating\nFishing',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 27,
                                fontWeight: FontWeight.w800,
                                height: 1.11,
                                letterSpacing: -.6,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              description,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: .73),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      ScoreRing(score: score),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 15,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: .13),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.wb_twilight_rounded,
                          color: Color(0xFFBDF8ED),
                          size: 22,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'BEST TIME TO FISH',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: .8,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                bestTime,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.wb_sunny_outlined,
                          color: Colors.white,
                          size: 19,
                        ),
                        const SizedBox(width: 5),
                        airTemperatureLoading
                            ? const LoadingLine(
                                width: 35,
                                height: 18,
                                light: true,
                              )
                            : Text(
                                airTemperature,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class LoadingLine extends StatelessWidget {
  const LoadingLine({
    super.key,
    required this.width,
    required this.height,
    this.light = false,
  });
  final double width, height;
  final bool light;

  @override
  Widget build(BuildContext context) => Container(
    width: width,
    height: height,
    decoration: BoxDecoration(
      color: light ? Colors.white30 : AppColors.mist,
      borderRadius: BorderRadius.circular(height / 2),
    ),
  );
}

class ConditionCard extends StatelessWidget {
  const ConditionCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.detail,
    this.onTap,
    this.loading = false,
  });
  final String label, value, detail;
  final IconData icon;
  final VoidCallback? onTap;
  final bool loading;
  @override
  Widget build(BuildContext context) => AppCard(
    onTap: onTap,
    padding: const EdgeInsets.all(15),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 35,
              height: 35,
              decoration: BoxDecoration(
                color: AppColors.mist,
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(icon, color: AppColors.blue, size: 19),
            ),
            const Spacer(),
            const Icon(
              Icons.arrow_outward_rounded,
              size: 14,
              color: AppColors.muted,
            ),
          ],
        ),
        const SizedBox(height: 13),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.muted,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 3),
        loading
            ? const LoadingLine(width: 88, height: 23)
            : Text(value, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 3),
        loading
            ? const LoadingLine(width: 112, height: 12)
            : Text(
                detail,
                style: const TextStyle(
                  color: AppColors.good,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
      ],
    ),
  );
}

class WindCard extends StatelessWidget {
  const WindCard({
    super.key,
    this.onTap,
    this.value = '14 km/h',
    this.detail = 'NW · gentle',
    this.loading = false,
  });
  final VoidCallback? onTap;
  final String value, detail;
  final bool loading;
  @override
  Widget build(BuildContext context) => ConditionCard(
    label: 'Wind',
    value: value,
    icon: Icons.air_rounded,
    detail: detail,
    loading: loading,
    onTap: onTap,
  );
}

class WaveCard extends StatelessWidget {
  const WaveCard({
    super.key,
    this.onTap,
    this.value = '1.2 m',
    this.detail = 'Clean swell',
    this.loading = false,
  });
  final VoidCallback? onTap;
  final String value, detail;
  final bool loading;
  @override
  Widget build(BuildContext context) => ConditionCard(
    label: 'Waves',
    value: value,
    icon: Icons.waves_rounded,
    detail: detail,
    loading: loading,
    onTap: onTap,
  );
}

class TideCard extends StatelessWidget {
  const TideCard({
    super.key,
    this.onTap,
    this.value = 'Rising',
    this.detail = 'High at 10:42',
    this.loading = false,
  });
  final VoidCallback? onTap;
  final String value, detail;
  final bool loading;
  @override
  Widget build(BuildContext context) => ConditionCard(
    label: 'Tide',
    value: value,
    icon: Icons.water_rounded,
    detail: detail,
    loading: loading,
    onTap: onTap,
  );
}

class ForecastHourlyCard extends StatelessWidget {
  const ForecastHourlyCard({
    super.key,
    required this.time,
    required this.label,
    required this.icon,
    required this.score,
    this.displayValue,
    this.loading = false,
    this.labelColor,
  });
  final String time, label;
  final IconData icon;
  final int score;
  final String? displayValue;
  final bool loading;
  final Color? labelColor;
  @override
  Widget build(BuildContext context) {
    final color = score >= 80
        ? AppColors.good
        : score >= 65
        ? AppColors.blue
        : AppColors.warning;
    return SizedBox(
      width: 89,
      child: AppCard(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        child: Column(
          children: [
            Text(
              time,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.muted,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 7),
            Icon(icon, size: 24, color: AppColors.blue),
            const SizedBox(height: 6),
            loading
                ? const LoadingLine(width: 37, height: 19)
                : Text(
                    displayValue ?? '$score',
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
            const SizedBox(height: 3),
            loading
                ? const LoadingLine(width: 55, height: 10)
                : Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: labelColor ?? color,
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}

IconData weatherIconFor(int code) {
  if (code >= 51) return Icons.water_drop_outlined;
  if (code == 3 || code == 45 || code == 48) return Icons.cloud_outlined;
  return Icons.wb_sunny_outlined;
}

class FishingSpotCard extends StatelessWidget {
  const FishingSpotCard({
    super.key,
    required this.spot,
    this.onTap,
    this.compact = false,
  });
  final FishingSpot spot;
  final VoidCallback? onTap;
  final bool compact;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: compact ? 250 : null,
    child: AppCard(
      padding: const EdgeInsets.all(16),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.mist,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(_iconForType(spot.type), color: AppColors.blue),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  spot.name,
                  style: Theme.of(context).textTheme.titleMedium,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
            ],
          ),
          const SizedBox(height: 9),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.mist,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              spot.mapped ? 'MAPPED PLACE' : 'SAMPLE SPOT',
              style: const TextStyle(
                color: AppColors.blue,
                fontSize: 9,
                fontWeight: FontWeight.w800,
                letterSpacing: .5,
              ),
            ),
          ),
          const SizedBox(height: 11),
          _SpotInfoLine(Icons.location_on_outlined, spot.distance),
          const SizedBox(height: 6),
          _SpotInfoLine(Icons.terrain_rounded, spot.type),
          if (!compact && spot.hasForecast) ...[
            const SizedBox(height: 10),
            Text(
              '${FishActivityLevel.fromScore(spot.score).label} · ${spot.score}/100',
              style: TextStyle(
                color: spot.score >= 70 ? AppColors.good : AppColors.blue,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            _SpotInfoLine(
              Icons.air_rounded,
              'Wind ${spot.wind} · Waves ${spot.waves}',
            ),
            Text(
              spot.forecastCached
                  ? 'Last available forecast'
                  : 'Current forecast · indicative fishing conditions',
              style: const TextStyle(color: AppColors.muted, fontSize: 11),
            ),
          ],
          if (!compact && spot.mapped) ...[
            const SizedBox(height: 8),
            Text(
              'Fishing access not verified${spot.hasForecast ? '' : ' · forecast unavailable'}',
              style: TextStyle(color: AppColors.muted, fontSize: 11),
            ),
          ],
          if (!compact && !spot.mapped) ...[
            const SizedBox(height: 8),
            const Text(
              'Sample details for Agadir',
              style: TextStyle(color: AppColors.muted, fontSize: 11),
            ),
          ],
        ],
      ),
    ),
  );

  static IconData _iconForType(String type) => switch (type) {
    'Beach' => Icons.beach_access_rounded,
    'Marina' || 'Harbor' => Icons.sailing_rounded,
    'Pier' => Icons.water_rounded,
    'Fishing area' => Icons.phishing_rounded,
    _ => Icons.waves_rounded,
  };
}

class _SpotInfoLine extends StatelessWidget {
  const _SpotInfoLine(this.icon, this.text);
  final IconData icon;
  final String text;
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, color: AppColors.aqua, size: 14),
      const SizedBox(width: 4),
      Flexible(
        child: Text(
          text,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: AppColors.muted,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    ],
  );
}

class FishPortrait extends StatelessWidget {
  const FishPortrait({super.key, required this.fish, this.size = 76});
  final FishSpecies fish;
  final double size;
  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [fish.color.withValues(alpha: .7), fish.color, AppColors.mist],
      ),
      borderRadius: BorderRadius.circular(size * .27),
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(size * .27),
      child: Image.asset(
        fish.imagePath,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) =>
            Icon(fish.icon, size: size * .5, color: AppColors.ocean),
      ),
    ),
  );
}

class FishCard extends StatelessWidget {
  const FishCard({
    super.key,
    required this.fish,
    this.onTap,
    this.compact = false,
    this.subtitle,
  });
  final FishSpecies fish;
  final VoidCallback? onTap;
  final bool compact;
  final String? subtitle;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: compact ? 180 : null,
    child: AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(13),
      child: compact
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FishPortrait(fish: fish, size: 70),
                const SizedBox(height: 11),
                Text(
                  fish.name,
                  style: Theme.of(context).textTheme.titleMedium,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 5),
                Text(
                  subtitle ?? '${fish.probability} chance today',
                  style: const TextStyle(
                    color: AppColors.good,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            )
          : Row(
              children: [
                FishPortrait(fish: fish),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        fish.name,
                        style: Theme.of(context).textTheme.titleMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        fish.scientific,
                        style: const TextStyle(
                          fontStyle: FontStyle.italic,
                          fontSize: 11,
                          color: AppColors.muted,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 5,
                        runSpacing: 4,
                        children: [
                          LabelPill(
                            fish.habitat,
                            color: AppColors.mist,
                            textColor: AppColors.blue,
                          ),
                          LabelPill(
                            fish.difficulty,
                            color: const Color(0xFFE9F8F1),
                            textColor: AppColors.good,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
              ],
            ),
    ),
  );
}

class LabelPill extends StatelessWidget {
  const LabelPill(
    this.text, {
    super.key,
    this.color = AppColors.mist,
    this.textColor = AppColors.blue,
  });
  final String text;
  final Color color, textColor;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(100),
    ),
    child: Text(
      text,
      style: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w800,
        color: textColor,
      ),
    ),
  );
}

class LessonCard extends StatelessWidget {
  const LessonCard({
    super.key,
    required this.lesson,
    this.onTap,
    this.completed = false,
  });
  final Lesson lesson;
  final VoidCallback? onTap;
  final bool completed;
  @override
  Widget build(BuildContext context) => AppCard(
    onTap: onTap,
    child: Row(
      children: [
        Container(
          width: 68,
          height: 68,
          decoration: BoxDecoration(
            gradient: oceanGradient,
            borderRadius: BorderRadius.circular(17),
          ),
          child: Icon(lesson.icon, color: Colors.white, size: 29),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                lesson.category.toUpperCase(),
                style: const TextStyle(
                  color: AppColors.aqua,
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  letterSpacing: .8,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                lesson.title,
                style: Theme.of(context).textTheme.titleMedium,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 7),
              Text(
                '${lesson.difficulty}  ·  ${lesson.duration}',
                style: const TextStyle(color: AppColors.muted, fontSize: 11),
              ),
              if (lesson.progress > 0) ...[
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(5),
                  child: LinearProgressIndicator(
                    value: lesson.progress,
                    minHeight: 4,
                    color: AppColors.aqua,
                    backgroundColor: AppColors.mist,
                  ),
                ),
              ],
            ],
          ),
        ),
        Icon(
          completed ? Icons.check_circle_rounded : Icons.chevron_right_rounded,
          color: completed ? AppColors.aqua : AppColors.muted,
        ),
      ],
    ),
  );
}

class CatchCard extends StatelessWidget {
  const CatchCard({
    super.key,
    required this.fish,
    required this.weight,
    required this.length,
    required this.spot,
    required this.date,
    this.onTap,
  });
  final FishSpecies fish;
  final String weight, length, spot, date;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => AppCard(
    onTap: onTap,
    child: Row(
      children: [
        FishPortrait(fish: fish, size: 78),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(fish.name, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 5),
              Text(
                '$weight  ·  $length',
                style: const TextStyle(
                  color: AppColors.blue,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                '$spot  ·  $date',
                style: const TextStyle(color: AppColors.muted, fontSize: 11),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class WeatherMetricCard extends StatelessWidget {
  const WeatherMetricCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.subtitle,
  });
  final String title, value, subtitle;
  final IconData icon;
  @override
  Widget build(BuildContext context) => AppCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.blue, size: 25),
        const SizedBox(height: 17),
        Text(
          title,
          style: const TextStyle(
            color: AppColors.muted,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(value, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 5),
        Text(
          subtitle,
          style: const TextStyle(
            color: AppColors.good,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );
}

class PremiumSearchBar extends StatelessWidget {
  const PremiumSearchBar({
    super.key,
    required this.hint,
    this.onChanged,
    this.controller,
    this.onFilter,
  });
  final String hint;
  final ValueChanged<String>? onChanged;
  final TextEditingController? controller;
  final VoidCallback? onFilter;
  @override
  Widget build(BuildContext context) => TextField(
    controller: controller,
    onChanged: onChanged,
    decoration: InputDecoration(
      hintText: hint,
      prefixIcon: const Icon(Icons.search_rounded, color: AppColors.blue),
      suffixIcon: onFilter == null
          ? null
          : IconButton(
              onPressed: onFilter,
              icon: const Icon(Icons.tune_rounded, color: AppColors.blue),
            ),
    ),
  );
}

class GradientButton extends StatelessWidget {
  const GradientButton(
    this.label, {
    super.key,
    required this.onPressed,
    this.icon,
  });
  final String label;
  final VoidCallback onPressed;
  final IconData? icon;
  @override
  Widget build(BuildContext context) => Container(
    height: 54,
    decoration: BoxDecoration(
      gradient: oceanGradient,
      borderRadius: BorderRadius.circular(17),
      boxShadow: [
        BoxShadow(
          color: AppColors.blue.withValues(alpha: .2),
          blurRadius: 15,
          offset: const Offset(0, 7),
        ),
      ],
    ),
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(17),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 19, color: Colors.white),
                const SizedBox(width: 8),
              ],
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class FishingBottomNavigationBar extends StatelessWidget {
  const FishingBottomNavigationBar({
    super.key,
    required this.index,
    required this.onTap,
  });
  final int index;
  final ValueChanged<int> onTap;
  static const icons = [
    Icons.home_rounded,
    Icons.explore_rounded,
    Icons.phishing_rounded,
    Icons.menu_book_rounded,
    Icons.person_rounded,
  ];
  static const labels = ['Home', 'Explore', 'Fish', 'Learn', 'Profile'];
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 7),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(23),
      boxShadow: [
        BoxShadow(
          color: AppColors.deep.withValues(alpha: .16),
          blurRadius: 30,
          offset: const Offset(0, 9),
        ),
      ],
    ),
    child: Row(
      children: List.generate(5, (i) {
        final selected = index == i;
        return Expanded(
          child: GestureDetector(
            onTap: () => onTap(i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOut,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: selected ? AppColors.mist : Colors.transparent,
                borderRadius: BorderRadius.circular(17),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icons[i],
                    size: 23,
                    color: selected ? AppColors.blue : AppColors.muted,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    labels[i],
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                      color: selected ? AppColors.blue : AppColors.muted,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    ),
  );
}

void pushPage(BuildContext context, Widget page) {
  unawaited(
    NavigationAdService.navigate(() {
      if (!context.mounted) return;
      Navigator.of(context).push(
        PageRouteBuilder(
          pageBuilder: (_, animation, _) => page,
          transitionsBuilder: (_, animation, _, child) => SlideTransition(
            position: Tween(begin: const Offset(.07, 0), end: Offset.zero)
                .animate(
                  CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  ),
                ),
            child: FadeTransition(opacity: animation, child: child),
          ),
          transitionDuration: const Duration(milliseconds: 280),
        ),
      );
    }),
  );
}

class ScreenPadding extends StatelessWidget {
  const ScreenPadding({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 650),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: child,
      ),
    ),
  );
}
