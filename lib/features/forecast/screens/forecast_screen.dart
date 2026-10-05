import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../models/fishing_conditions.dart';
import '../../../widgets/premium_widgets.dart';
import '../../conditions/conditions_scope.dart';
import '../../conditions/screens/conditions_screen.dart';
import '../../location/location_scope.dart';
import '../../location/screens/location_picker_screen.dart';

class ForecastScreen extends StatelessWidget {
  const ForecastScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final controller = FishingConditionsScope.controllerOf(context);
    final conditions = controller.current;
    final loading = controller.showSkeleton;
    final scoreHours = conditions.hourly.take(6).toList();
    final weatherHours = conditions.upcomingWeatherHours.take(6).toList();
    final daily = _dailyScores(conditions);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fishing Forecast'),
        actions: [
          IconButton(
            onPressed: () => pushPage(context, const ConditionsScreen()),
            icon: const Icon(Icons.water_rounded),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => controller.refresh(forceRefresh: true),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ScreenPadding(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InkWell(
                  onTap: () => pushPage(context, const LocationPickerScreen()),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.location_on_rounded,
                        color: AppColors.blue,
                        size: 17,
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          '${FishingLocationScope.of(context).selected.label} · ${loading ? 'Loading conditions…' : conditions.sourceLabel}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.muted,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: AppColors.muted,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: oceanGradient,
                    borderRadius: BorderRadius.circular(27),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "TODAY'S FISHING SCORE",
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1,
                              ),
                            ),
                            const SizedBox(height: 11),
                            Text(
                              'Excellent',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 26,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 7),
                            const Text(
                              'Fishing score is sample while weather updates live.',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                                height: 1.35,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const ScoreRing(score: 86, size: 105),
                    ],
                  ),
                ),
                const SizedBox(height: 27),
                const SectionHeader('Current weather and sea'),
                AppCard(
                  child: Column(
                    children: [
                      _Reason(
                        '${conditions.weather.windKmh.round()} km/h wind',
                      ),
                      _Reason(
                        '${conditions.marine.waveM.toStringAsFixed(1)} m waves',
                      ),
                      _Reason(
                        '${conditions.weather.precipitationMm.toStringAsFixed(1)} mm precipitation',
                      ),
                      _Reason('${conditions.tide.phase} tide'),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                const SectionHeader('Hourly weather outlook'),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'DEMO ACTIVITY SCORE',
                        style: TextStyle(
                          color: AppColors.muted,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: .8,
                        ),
                      ),
                      const SizedBox(height: 13),
                      SizedBox(
                        height: 115,
                        width: double.infinity,
                        child: TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0, end: 1),
                          duration: const Duration(milliseconds: 800),
                          curve: Curves.easeOutCubic,
                          builder: (context, value, _) => CustomPaint(
                            painter: _ForecastPainter(
                              value,
                              scoreHours
                                  .map((point) => point.score / 100)
                                  .toList(),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 9),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: scoreHours
                            .map(
                              (point) => Text(
                                conditions.clock(point.timeUtc),
                                style: TextStyle(
                                  color: AppColors.muted,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 13),
                SizedBox(
                  height: 135,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: weatherHours.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 8),
                    itemBuilder: (_, i) => ForecastHourlyCard(
                      time: conditions.clock(weatherHours[i].timeUtc),
                      label: WeatherModel.descriptionFor(
                        weatherHours[i].weatherCode,
                      ),
                      icon: weatherIconFor(weatherHours[i].weatherCode),
                      score: 86,
                      displayValue: '${weatherHours[i].temperatureC.round()}°',
                      labelColor: AppColors.blue,
                      loading: loading,
                    ),
                  ),
                ),
                const SizedBox(height: 29),
                const SectionHeader('5-day forecast'),
                ...List.generate(daily.length, (i) {
                  final score = daily[i].value;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: AppCard(
                      child: Row(
                        children: [
                          Container(
                            width: 39,
                            height: 39,
                            decoration: BoxDecoration(
                              color: AppColors.mist,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              conditions.weather.dailyWeatherCodes.length > i &&
                                      conditions.weather.dailyWeatherCodes[i] >=
                                          3
                                  ? Icons.cloud_outlined
                                  : Icons.wb_sunny_outlined,
                              color: AppColors.blue,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 13),
                          Expanded(
                            child: Text(
                              _dayName(daily[i].key.weekday),
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          Text(
                            '$score',
                            style: const TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(width: 9),
                          SizedBox(
                            width: 64,
                            child: Text(
                              FishingConditions.ratingFor(score),
                              style: TextStyle(
                                color: score >= 80
                                    ? AppColors.good
                                    : score >= 65
                                    ? AppColors.blue
                                    : AppColors.warning,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<MapEntry<DateTime, int>> _dailyScores(FishingConditions conditions) {
    final buckets = <DateTime, List<int>>{};
    for (final point in conditions.hourly) {
      final local = conditions.localTime(point.timeUtc);
      final date = DateTime.utc(local.year, local.month, local.day);
      buckets.putIfAbsent(date, () => []).add(point.score);
    }
    return buckets.entries.take(5).map((entry) {
      final values = entry.value;
      return MapEntry(
        entry.key,
        (values.reduce((a, b) => a + b) / values.length).round(),
      );
    }).toList();
  }

  String _dayName(int weekday) => const [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ][weekday - 1];
}

class _Reason extends StatelessWidget {
  const _Reason(this.label);
  final String label;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 7),
    child: Row(
      children: [
        const Icon(Icons.check_circle_rounded, color: AppColors.good, size: 19),
        const SizedBox(width: 11),
        Text(
          label,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
        ),
      ],
    ),
  );
}

class _ForecastPainter extends CustomPainter {
  _ForecastPainter(this.progress, this.values);
  final double progress;
  final List<double> values;
  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;
    final points = List.generate(
      values.length,
      (i) => Offset(
        size.width * i / (values.length - 1),
        size.height * (1 - values[i]) * .85 + 5,
      ),
    );
    final grid = Paint()
      ..color = AppColors.mist
      ..strokeWidth = 1;
    for (var i = 1; i <= 3; i++) {
      final y = size.height * i / 4;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }
    canvas.save();
    canvas.clipRect(Rect.fromLTWH(0, 0, size.width * progress, size.height));
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 1; i < points.length; i++) {
      final p = points[i - 1], q = points[i];
      path.cubicTo(
        (p.dx + q.dx) / 2,
        p.dy,
        (p.dx + q.dx) / 2,
        q.dy,
        q.dx,
        q.dy,
      );
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
          colors: [Color(0x6621B7C0), Color(0x0016B8C4)],
        ).createShader(Offset.zero & size),
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = AppColors.aqua
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );
    for (final p in points) {
      canvas.drawCircle(p, 4, Paint()..color = Colors.white);
      canvas.drawCircle(p, 3, Paint()..color = AppColors.aqua);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _ForecastPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.values != values;
}
