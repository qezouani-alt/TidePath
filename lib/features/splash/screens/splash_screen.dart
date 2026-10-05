import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const splashNavy = Color(0xFF071E2B);
const splashGold = Color(0xFFE3C99A);
const splashSea = Color(0xFF48BAC1);

class SplashScreen extends StatefulWidget {
  const SplashScreen({
    super.key,
    required this.ready,
    required this.onComplete,
  });

  final Future<void> ready;
  final VoidCallback onComplete;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  final int _fishSeed = math.Random().nextInt(1 << 30);
  late final AnimationController _progress = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3000),
  );

  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    // Attach immediately so initialization errors cannot escape unhandled.
    final ready = widget.ready.then<void>(
      (_) {},
      onError: (Object _, StackTrace _) {},
    );
    try {
      await _progress.animateTo(
        .9,
        duration: const Duration(milliseconds: 2200),
        curve: Curves.easeInOut,
      );
      await ready;
      if (!mounted) return;
      // Finish the final wave of jumps once startup is ready.
      await _progress.animateTo(
        1,
        duration: const Duration(milliseconds: 1100),
        curve: Curves.linear,
      );
      if (mounted) widget.onComplete();
    } on TickerCanceled {
      // Leaving the screen cancels its animation.
    }
  }

  @override
  void dispose() {
    _progress.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnnotatedRegion<SystemUiOverlayStyle>(
    value: SystemUiOverlayStyle.light.copyWith(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: splashNavy,
    ),
    child: Scaffold(
      backgroundColor: splashNavy,
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -.2),
            radius: .9,
            colors: [Color(0xFF123D4A), splashNavy],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 32),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 340),
                child: AnimatedBuilder(
                  animation: _progress,
                  builder: (context, _) {
                    final value = _progress.value;
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Semantics(
                          label: 'Fish jumping out of waves',
                          value: '${(value * 100).floor()} percent',
                          child: SizedBox(
                            width: double.infinity,
                            height: 210,
                            child: CustomPaint(
                              painter: WaveJumpPainter(value, seed: _fishSeed),
                            ),
                          ),
                        ),
                        const SizedBox(height: 28),
                        const Text(
                          'TidePath Fishing\nSpot Finder',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Color(0xFFF7F1E7),
                            fontSize: 30,
                            fontWeight: FontWeight.w300,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 46),
                        SizedBox(
                          width: 150,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(2),
                            child: LinearProgressIndicator(
                              value: value,
                              minHeight: 2,
                              backgroundColor: Color(0xFF23404C),
                              color: splashGold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 15),
                        Text(
                          value >= .9
                              ? 'A new horizon awaits'
                              : 'Finding your rhythm',
                          style: const TextStyle(
                            color: Color(0xFF9AB1B9),
                            fontSize: 11,
                            letterSpacing: .7,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${(value * 100).floor()}%',
                          style: const TextStyle(
                            color: Color(0xFF9AB1B9),
                            fontSize: 10,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

/// Seeded motion stays smooth between frames while each fish jumps independently.
class WaveJumpPainter extends CustomPainter {
  const WaveJumpPainter(this.progress, {this.seed = 42});
  final double progress;
  final int seed;
  static const fishCount = 5;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final surface = h * .69;
    final phase = progress * math.pi * 3;
    // Fine halo keeps the illustration soft against the midnight background.
    canvas.drawCircle(
      Offset(w * .5, h * .46),
      h * .42,
      Paint()
        ..shader =
            RadialGradient(
              colors: [
                splashSea.withValues(alpha: .09),
                splashSea.withValues(alpha: 0),
              ],
            ).createShader(
              Rect.fromCircle(center: Offset(w * .5, h * .46), radius: h * .42),
            ),
    );

    for (var layer = 2; layer >= 0; layer--) {
      final y = surface + layer * 13;
      final drift = math.sin(phase + layer) * 5;
      final wave = Path()
        ..moveTo(w * .08, y + 9)
        ..cubicTo(w * .24, y + 21, w * .35, y - 14 + drift, w * .5, y)
        ..cubicTo(w * .66, y + 15, w * .75, y - 20 - drift, w * .92, y - 3);
      canvas.drawPath(
        wave,
        Paint()
          ..color = splashSea.withValues(alpha: .18 + (2 - layer) * .2)
          ..style = PaintingStyle.stroke
          ..strokeWidth = layer == 0 ? 2 : 1
          ..strokeCap = StrokeCap.round,
      );
    }

    for (var fishIndex = 0; fishIndex < fishCount; fishIndex++) {
      // Keep randomness stable across frames; choose a new location per leap.
      final motion = math.Random(seed + fishIndex * 7919);
      final speed = 1.3 + motion.nextDouble() * 2.1;
      final clock = progress * speed + motion.nextDouble();
      final cycle = clock.floor();
      final phase = clock - cycle;
      final activeFraction = .55 + motion.nextDouble() * .25;
      final jump = (phase / activeFraction).clamp(0.0, 1.0);
      final lift = math.sin(jump * math.pi);
      final height = .22 + motion.nextDouble() * .25;
      final scale = .48 + motion.nextDouble() * .3;
      final leap = math.Random(seed + fishIndex * 7919 + cycle * 104729);
      final direction = leap.nextBool() ? 1.0 : -1.0;
      final travel = .09 + leap.nextDouble() * .12;
      final originX = w * (.23 + leap.nextDouble() * .54);
      final fishX = originX + w * travel * direction * jump;
      final fishY = surface + 26 - lift * h * height;
      canvas.save();
      canvas.clipRect(Rect.fromLTWH(0, 0, w, surface + 13));
      final droplets = Paint()
        ..color = splashGold.withValues(alpha: (1 - jump) * .8);
      for (var i = 0; i < 5; i++) {
        final angle = math.pi * (1.13 + i * .18);
        canvas.drawCircle(
          Offset(
            originX + math.cos(angle) * (8 + jump * 42),
            surface + math.sin(angle) * (10 + jump * 48),
          ),
          1.5,
          droplets,
        );
      }
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(originX, surface + 5),
          width: 18 + jump * 62,
          height: 5 + jump * 7,
        ),
        Paint()
          ..color = splashSea.withValues(alpha: (1 - jump) * .35)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );

      canvas.save();
      canvas.translate(fishX, fishY);
      canvas.scale(direction, 1);
      canvas.rotate(-.9 + jump * 1.8);
      canvas.scale(w / 300 * scale);
      final body = Path()
        ..moveTo(28, 0)
        ..cubicTo(11, -19, -8, -17, -22, -3)
        ..lineTo(-37, -13)
        ..quadraticBezierTo(-32, 0, -37, 13)
        ..lineTo(-22, 4)
        ..cubicTo(-4, 17, 16, 12, 28, 0)
        ..close();
      canvas.drawPath(
        body,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: fishIndex.isEven
                ? [Color(0xFFFFEBC6), splashGold, Color(0xFFB59868)]
                : [Color(0xFFB3ECE5), splashSea, Color(0xFF277E8A)],
          ).createShader(const Rect.fromLTWH(-37, -18, 65, 36)),
      );
      final fin = Path()
        ..moveTo(-9, -11)
        ..quadraticBezierTo(-2, -25, 7, -13)
        ..close();
      canvas.drawPath(
        fin,
        Paint()..color = fishIndex.isEven ? splashGold : splashSea,
      );
      canvas.drawPath(
        Path()
          ..moveTo(-1, 2)
          ..quadraticBezierTo(1, 12, -8, 13),
        Paint()
          ..color = splashNavy.withValues(alpha: .35)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2,
      );
      canvas.drawCircle(const Offset(17, -2), 1.6, Paint()..color = splashNavy);
      canvas.restore();
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(WaveJumpPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.seed != seed;
}
