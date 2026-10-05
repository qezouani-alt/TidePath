import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../models/fishing_conditions.dart';
import '../../../widgets/fish_activity_indicator.dart';
import '../../../widgets/premium_widgets.dart';
import '../conditions_scope.dart';

/// A detailed view of the condition snapshot already held by the app.
/// Opening this page does not start another provider request.
class FishingConditionsDashboardScreen extends StatelessWidget {
  const FishingConditionsDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = FishingConditionsScope.controllerOf(context);
    final data = controller.current;
    final loading = controller.showSkeleton;
    return Scaffold(
      appBar: AppBar(title: const Text('Fishing Conditions')),
      body: RefreshIndicator(
        onRefresh: () => controller.refresh(forceRefresh: true),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 38),
          child: ScreenPadding(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 950),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_rounded,
                        size: 17,
                        color: AppColors.blue,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          data.location.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.muted,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    loading ? 'Loading conditions…' : data.sourceLabel,
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _summary(data),
                  _section('Weather', Icons.wb_sunny_outlined),
                  _weather(context, data, loading),
                  _section('Wind', Icons.air_rounded),
                  _wind(context, data, loading),
                  _section('Waves & swell', Icons.waves_rounded),
                  _waves(context, data, loading),
                  _section('Sea', Icons.water_rounded),
                  _sea(context, data, loading),
                  _section('Tides', Icons.water_drop_outlined),
                  _tides(context, data, loading),
                  _section('Sun & moon', Icons.wb_twilight_rounded),
                  _sunMoon(context, data, loading),
                  _section('Hourly Fishing Outlook', Icons.schedule_rounded),
                  _hourly(data, loading),
                  _section('Why this score?', Icons.info_outline_rounded),
                  _why(data),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _summary(FishingConditions data) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(22),
    decoration: BoxDecoration(
      gradient: oceanGradient,
      borderRadius: BorderRadius.circular(27),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'SUMMARY',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 11,
            fontWeight: FontWeight.w900,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 15),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data.rating,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 25,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Fishing score · demo',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
            ScoreRing(score: data.score, size: 100),
          ],
        ),
        const SizedBox(height: 16),
        FishActivityIndicator(
          fishingScore: data.score,
          isBestTime: _isBestTime(data),
        ),
        const SizedBox(height: 18),
        const Text(
          'Best period · 06:15–09:30 (sample)',
          style: TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 7),
        Text(
          'Wind ${data.weather.windKmh.round()} km/h, waves ${data.marine.waveM.toStringAsFixed(1)} m, and ${data.tide.phase.toLowerCase()} tide. Check these before deciding when to fish.',
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
            height: 1.4,
          ),
        ),
      ],
    ),
  );

  bool _isBestTime(FishingConditions data) {
    final local = data.localTime(DateTime.now().toUtc());
    final minuteOfDay = local.hour * 60 + local.minute;
    return minuteOfDay >= 6 * 60 + 15 && minuteOfDay <= 9 * 60 + 30;
  }

  Widget _section(String title, IconData icon) => Padding(
    padding: const EdgeInsets.fromLTRB(0, 28, 0, 12),
    child: Row(
      children: [
        Icon(icon, color: AppColors.blue, size: 21),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            maxLines: 2,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: AppColors.ink,
            ),
          ),
        ),
      ],
    ),
  );

  Widget _weather(BuildContext context, FishingConditions data, bool loading) {
    final weather = data.weather;
    final change = weather.pressureChangeHpa;
    final pressureTrend = change == null
        ? 'Trend unavailable'
        : change.abs() < .2
        ? 'Steady over 1 hour'
        : '${change > 0 ? 'Rising' : 'Falling'} ${change.abs().toStringAsFixed(1)} hPa / hour';
    return _metricGrid(context, [
      _Metric(
        'Air temperature',
        '${weather.airC.round()}°C',
        'At the surface',
        Icons.thermostat_rounded,
      ),
      _Metric(
        'Feels like',
        '${weather.feelsLikeC.round()}°C',
        'How it feels outside',
        Icons.person_outline_rounded,
      ),
      _Metric(
        'Condition',
        weather.condition,
        'Current sky',
        weatherIconFor(weather.weatherCode),
      ),
      _Metric(
        'Precipitation',
        '${weather.precipitationMm.toStringAsFixed(1)} mm',
        '${weather.rainChance}% chance',
        Icons.water_drop_outlined,
      ),
      _Metric(
        'Humidity',
        weather.humidity == null ? '—' : '${weather.humidity}%',
        'Moisture in the air',
        Icons.opacity_rounded,
      ),
      _Metric(
        'Cloud cover',
        '${weather.cloudCover}%',
        'Portion of sky covered',
        Icons.cloud_outlined,
      ),
      _Metric(
        'Pressure',
        '${weather.pressureHpa} hPa',
        pressureTrend,
        Icons.speed_rounded,
      ),
      _Metric(
        'UV index',
        weather.uvIndex?.toStringAsFixed(1) ?? '—',
        'Sun exposure',
        Icons.wb_sunny_outlined,
      ),
      _Metric(
        'Visibility',
        weather.visibilityKm == null
            ? '—'
            : '${weather.visibilityKm!.toStringAsFixed(1)} km',
        'How far you can see',
        Icons.visibility_outlined,
      ),
    ], loading);
  }

  Widget _wind(BuildContext context, FishingConditions data, bool loading) {
    final wind = data.weather;
    return Column(
      children: [
        _metricGrid(context, [
          _Metric(
            'Wind speed',
            '${wind.windKmh.round()} km/h',
            'Steady wind',
            Icons.air_rounded,
          ),
          _Metric(
            'Direction',
            '${data.windDirection} · ${wind.windDegrees}°',
            'Where wind comes from',
            Icons.explore_outlined,
          ),
          _Metric(
            'Gusts',
            '${wind.gustKmh.round()} km/h',
            'Brief stronger bursts',
            Icons.flag_outlined,
          ),
        ], loading),
        const SizedBox(height: 11),
        AppCard(
          child: Row(
            children: [
              SizedBox(
                width: 82,
                height: 82,
                child: _Compass(degrees: wind.windDegrees),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Wind from ${data.windDirection}',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'The arrow points to the direction the wind comes from.',
                      style: TextStyle(
                        color: AppColors.muted,
                        fontSize: 12,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _waves(BuildContext context, FishingConditions data, bool loading) {
    final sea = data.marine;
    final wavePoints = sea.hours.take(24).map((hour) => hour.waveM).toList();
    return Column(
      children: [
        _metricGrid(context, [
          _Metric(
            'Wave height',
            '${sea.waveM.toStringAsFixed(1)} m',
            'Average of the higher waves',
            Icons.waves_rounded,
          ),
          _Metric(
            'Wave direction',
            '${data.waveDirection} · ${sea.waveDegrees}°',
            'Waves arrive from here',
            Icons.explore_outlined,
          ),
          _Metric(
            'Wave period',
            '${sea.wavePeriodSeconds} sec',
            'Time between wave crests',
            Icons.timelapse_rounded,
          ),
          _Metric(
            'Swell height',
            '${sea.swellM.toStringAsFixed(1)} m',
            'Longer ocean waves',
            Icons.water_rounded,
          ),
          _Metric(
            'Swell direction',
            '${data.swellDirection} · ${sea.swellDegrees}°',
            'Swell arrives from here',
            Icons.explore_outlined,
          ),
          _Metric(
            'Swell period',
            '${sea.swellPeriodSeconds} sec',
            'Longer periods can carry more energy',
            Icons.timelapse_rounded,
          ),
        ], loading),
        const SizedBox(height: 11),
        _chartCard('Wave height · next 24 hours', wavePoints, 'm', loading),
      ],
    );
  }

  Widget _sea(BuildContext context, FishingConditions data, bool loading) {
    final sea = data.marine;
    return _metricGrid(context, [
      _Metric(
        'Sea temperature',
        '${sea.waterC.toStringAsFixed(1)}°C',
        'Temperature at the surface',
        Icons.thermostat_rounded,
      ),
      _Metric(
        'Ocean current',
        sea.oceanCurrentKmh == null
            ? '—'
            : '${sea.oceanCurrentKmh!.toStringAsFixed(1)} km/h',
        'Modeled surface flow',
        Icons.swap_horiz_rounded,
      ),
      _Metric(
        'Current direction',
        sea.oceanCurrentDegrees == null
            ? '—'
            : '${FishingConditions.compass(sea.oceanCurrentDegrees!)} · ${sea.oceanCurrentDegrees}°',
        'Where the water flows toward',
        Icons.explore_outlined,
      ),
      _Metric(
        'Sea level',
        sea.seaLevelM == null ? '—' : '${sea.seaLevelM!.toStringAsFixed(2)} m',
        'Relative to mean sea level',
        Icons.water_rounded,
      ),
    ], loading);
  }

  Widget _tides(BuildContext context, FishingConditions data, bool loading) {
    final tide = data.tide;
    final now = DateTime.now().toUtc();
    final remaining = tide.nextUtc == null
        ? '—'
        : _duration(tide.nextUtc!.difference(now));
    final liveTidePoints = data.marine.hours
        .where((hour) => !hour.timeUtc.isBefore(now) && hour.seaLevelM != null)
        .take(24)
        .map((hour) => hour.seaLevelM)
        .toList();
    final hasTideCurve = liveTidePoints.length >= 2;
    final tidePoints = hasTideCurve
        ? liveTidePoints
        : List<double?>.generate(
            24,
            (hour) => 0.8 * math.sin((hour - 2) * math.pi / 6),
          );
    return Column(
      children: [
        _metricGrid(context, [
          _Metric(
            'Current tide',
            tide.phase,
            tide.origin == DataOrigin.live
                ? 'Modeled from sea level'
                : 'Sample',
            Icons.trending_up_rounded,
          ),
          _Metric(
            'Next high tide',
            data.clock(tide.highUtc),
            'Local time',
            Icons.arrow_upward_rounded,
          ),
          _Metric(
            'Next low tide',
            data.clock(tide.lowUtc),
            'Local time',
            Icons.arrow_downward_rounded,
          ),
          _Metric(
            'Tide height',
            data.marine.seaLevelM == null
                ? '0.40 m'
                : '${data.marine.seaLevelM!.toStringAsFixed(2)} m',
            data.marine.seaLevelM == null
                ? 'Sample'
                : 'Relative to mean sea level',
            Icons.water_drop_outlined,
          ),
          _Metric(
            'Next tide event',
            data.clock(tide.nextUtc),
            'In $remaining',
            Icons.schedule_rounded,
          ),
        ], loading),
        const SizedBox(height: 11),
        _chartCard(
          hasTideCurve
              ? 'Sea level · next 24 hours'
              : 'Sea level · next 24 hours (sample)',
          tidePoints,
          'm',
          loading,
        ),
        const SizedBox(height: 7),
        const Text(
          'Sea-level estimates and sample curves are not suitable for navigation.',
          style: TextStyle(fontSize: 11, color: AppColors.muted),
        ),
      ],
    );
  }

  Widget _sunMoon(BuildContext context, FishingConditions data, bool loading) {
    final sunset = data.weather.sunsetUtc;
    final goldenStart = sunset.subtract(const Duration(hours: 1));
    return Column(
      children: [
        _metricGrid(context, [
          _Metric(
            'Sunrise',
            data.clock(data.weather.sunriseUtc),
            'Local time',
            Icons.wb_twilight_rounded,
          ),
          _Metric(
            'Sunset',
            data.clock(sunset),
            'Local time',
            Icons.nights_stay_outlined,
          ),
          _Metric(
            'Golden hour',
            '${data.clock(goldenStart)}–${data.clock(sunset)}',
            'Approx. hour before sunset',
            Icons.wb_sunny_outlined,
          ),
          const _Metric(
            'Moon phase',
            'Waxing gibbous',
            'Sample',
            Icons.brightness_2_outlined,
          ),
          const _Metric(
            'Moon illumination',
            '62%',
            'Sample',
            Icons.brightness_4_outlined,
          ),
          const _Metric(
            'Moonrise',
            '15:42',
            'Sample local time',
            Icons.arrow_upward_rounded,
          ),
          const _Metric(
            'Moonset',
            '04:18',
            'Sample local time',
            Icons.arrow_downward_rounded,
          ),
        ], loading),
        const SizedBox(height: 7),
        const Text(
          'Moon values are sample data until a lunar data source is connected.',
          style: TextStyle(fontSize: 11, color: AppColors.muted),
        ),
      ],
    );
  }

  Widget _hourly(FishingConditions data, bool loading) {
    final now = DateTime.now().toUtc();
    final start = DateTime.utc(now.year, now.month, now.day, now.hour);
    final weatherByTime = {
      for (final hour in data.weather.hours)
        hour.timeUtc.millisecondsSinceEpoch: hour,
    };
    final marineByTime = {
      for (final hour in data.marine.hours)
        hour.timeUtc.millisecondsSinceEpoch: hour,
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Fishing scores in this timeline are sample values. Weather and sea figures use available model data.',
          style: TextStyle(color: AppColors.muted, fontSize: 11, height: 1.4),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 206,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: 24,
            separatorBuilder: (_, _) => const SizedBox(width: 9),
            itemBuilder: (context, index) {
              final time = start.add(Duration(hours: index));
              final weather = weatherByTime[time.millisecondsSinceEpoch];
              final marine = marineByTime[time.millisecondsSinceEpoch];
              final score = data.hourly.length > index
                  ? data.hourly[index].score
                  : 86;
              final quality = FishingConditions.ratingFor(score);
              final color = score >= 80
                  ? AppColors.good
                  : score >= 65
                  ? AppColors.blue
                  : score >= 45
                  ? AppColors.warning
                  : Colors.redAccent;
              final tide = _tideAt(data.marine.hours, time, data.tide.phase);
              return SizedBox(
                width: 136,
                child: AppCard(
                  padding: const EdgeInsets.all(11),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data.clock(time),
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            weatherIconFor(
                              weather?.weatherCode ?? data.weather.weatherCode,
                            ),
                            color: AppColors.blue,
                            size: 18,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${weather?.temperatureC.round() ?? data.weather.airC.round()}°C',
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ],
                      ),
                      const SizedBox(height: 7),
                      Text(
                        'Wind ${weather?.windKmh.round() ?? data.weather.windKmh.round()} km/h',
                        style: const TextStyle(fontSize: 11),
                      ),
                      Text(
                        'Waves ${(marine?.waveM ?? data.marine.waveM).toStringAsFixed(1)} m',
                        style: const TextStyle(fontSize: 11),
                      ),
                      Text('Tide $tide', style: const TextStyle(fontSize: 11)),
                      const Spacer(),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 5),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: .12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '$score · $quality',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: color,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _why(FishingConditions data) {
    final notes = <String>[
      '${data.weather.windKmh.round()} km/h wind: ${data.weather.windKmh < 20 ? 'manageable for many shore trips' : 'check your casting and safety plan'}.',
      '${data.marine.waveM.toStringAsFixed(1)} m waves with a ${data.marine.wavePeriodSeconds} sec period.',
      '${data.tide.phase} tide: moving water can change where fish feed.',
      if (data.weather.gustKmh > 25)
        'Stronger gusts may affect handling and comfort.',
      'Sunset is at ${data.clock(data.weather.sunsetUtc)}; low light can change fish activity.',
    ];
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'The 86/100 score is a demo value. These notes explain the measured conditions; they do not calculate that score.',
            style: TextStyle(fontSize: 12, color: AppColors.muted, height: 1.4),
          ),
          const SizedBox(height: 12),
          for (final note in notes)
            Padding(
              padding: const EdgeInsets.only(bottom: 9),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.check_circle_outline_rounded,
                    size: 17,
                    color: AppColors.good,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      note,
                      style: const TextStyle(fontSize: 12, height: 1.35),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _metricGrid(
    BuildContext context,
    List<_Metric> values,
    bool loading,
  ) => LayoutBuilder(
    builder: (context, constraints) {
      final columns = constraints.maxWidth >= 780
          ? 4
          : constraints.maxWidth >= 560
          ? 3
          : 2;
      const gap = 10.0;
      final width = (constraints.maxWidth - (columns - 1) * gap) / columns;
      return Wrap(
        spacing: gap,
        runSpacing: gap,
        children: values
            .map(
              (metric) => SizedBox(
                width: width,
                height: 118,
                child: AppCard(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(metric.icon, size: 17, color: AppColors.blue),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              metric.label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.muted,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 11),
                      loading
                          ? const LoadingLine(width: 76, height: 18)
                          : Text(
                              metric.value,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                      const SizedBox(height: 3),
                      Text(
                        metric.detail,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppColors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
            .toList(),
      );
    },
  );

  Widget _chartCard(
    String title,
    List<double?> points,
    String unit,
    bool loading,
  ) => AppCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 9),
        if (loading)
          const SizedBox(
            height: 90,
            child: Center(child: LoadingLine(width: 160, height: 12)),
          )
        else if (points.whereType<double>().length < 2)
          const SizedBox(
            height: 90,
            child: Center(
              child: Text(
                'Chart unavailable',
                style: TextStyle(color: AppColors.muted, fontSize: 12),
              ),
            ),
          )
        else
          SizedBox(
            height: 90,
            width: double.infinity,
            child: CustomPaint(painter: _SeriesPainter(points)),
          ),
        const SizedBox(height: 4),
        Text(
          'Now → 24 hours · $unit',
          style: const TextStyle(color: AppColors.muted, fontSize: 10),
        ),
      ],
    ),
  );

  String _duration(Duration duration) {
    if (duration.isNegative) return 'soon';
    return '${duration.inHours} h ${duration.inMinutes.remainder(60)} min';
  }

  String _tideAt(List<MarineHour> hours, DateTime time, String fallback) {
    final index = hours.indexWhere((hour) => !hour.timeUtc.isBefore(time));
    if (index <= 0 ||
        index >= hours.length ||
        hours[index].seaLevelM == null ||
        hours[index - 1].seaLevelM == null) {
      return fallback.toLowerCase();
    }
    return hours[index].seaLevelM! >= hours[index - 1].seaLevelM!
        ? 'rising'
        : 'falling';
  }
}

class _Metric {
  const _Metric(this.label, this.value, this.detail, this.icon);
  final String label, value, detail;
  final IconData icon;
}

class _Compass extends StatelessWidget {
  const _Compass({required this.degrees});
  final int degrees;

  @override
  Widget build(BuildContext context) => Stack(
    alignment: Alignment.center,
    children: [
      Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.mist,
          border: Border.all(color: AppColors.blue.withValues(alpha: .2)),
        ),
      ),
      const Positioned(
        top: 3,
        child: Text(
          'N',
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w900,
            color: AppColors.blue,
          ),
        ),
      ),
      const Positioned(
        right: 4,
        child: Text(
          'E',
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w900,
            color: AppColors.blue,
          ),
        ),
      ),
      const Positioned(
        bottom: 3,
        child: Text(
          'S',
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w900,
            color: AppColors.blue,
          ),
        ),
      ),
      const Positioned(
        left: 4,
        child: Text(
          'W',
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w900,
            color: AppColors.blue,
          ),
        ),
      ),
      Transform.rotate(
        angle: degrees * math.pi / 180,
        child: const Icon(
          Icons.navigation_rounded,
          size: 32,
          color: AppColors.blue,
        ),
      ),
    ],
  );
}

class _SeriesPainter extends CustomPainter {
  _SeriesPainter(this.values);
  final List<double?> values;

  @override
  void paint(Canvas canvas, Size size) {
    final good = values.whereType<double>().toList();
    if (good.length < 2) return;
    final minValue = good.reduce(math.min);
    final maxValue = good.reduce(math.max);
    final range = math.max(.1, maxValue - minValue);
    final path = Path();
    var began = false;
    for (var i = 0; i < values.length; i++) {
      final value = values[i];
      if (value == null) {
        began = false;
        continue;
      }
      final point = Offset(
        i / math.max(1, values.length - 1) * size.width,
        size.height - 8 - ((value - minValue) / range) * (size.height - 16),
      );
      if (!began) {
        path.moveTo(point.dx, point.dy);
        began = true;
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    final grid = Paint()
      ..color = AppColors.mist
      ..strokeWidth = 1;
    for (var i = 1; i <= 2; i++) {
      final y = i * size.height / 3;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = AppColors.aqua
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(covariant _SeriesPainter oldDelegate) =>
      oldDelegate.values != values;
}
