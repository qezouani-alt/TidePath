import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../models/coast_orientation.dart';
import '../../../models/fishing_conditions.dart';
import '../../../models/fishing_forecast.dart';
import '../../../services/coast_orientation_service.dart';
import '../../../services/fishing_forecast_builder.dart';
import '../../../widgets/premium_widgets.dart';
import '../../home/widgets/fishing_forecast_selectors.dart';
import '../conditions_scope.dart';
import '../widgets/fishing_summary_tab.dart';
import '../widgets/sun_moon_details_card.dart';
import '../widgets/tide_details_card.dart';

/// The detailed dashboard reads the same cached conditions as Home.
class FishingConditionsDetailsScreen extends StatefulWidget {
  const FishingConditionsDetailsScreen({super.key});

  @override
  State<FishingConditionsDetailsScreen> createState() =>
      _FishingConditionsDetailsScreenState();
}

class _FishingConditionsDetailsScreenState
    extends State<FishingConditionsDetailsScreen> {
  static const _builder = FishingForecastBuilder();
  final ScrollController _hourScroll = ScrollController();
  late FishingConditions _source;
  late List<FishingForecastDay> _days;
  bool _initialized = false;
  int _selectedDay = 0;
  int _selectedHour = 0;
  int _selectedTab = 0;
  CoastOrientation? _coast;
  String? _coastRequestKey;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final current = FishingConditionsScope.controllerOf(context).current;
    if (_initialized && identical(_source, current)) return;
    final selectedTime = _initialized
        ? _days[_selectedDay].hours[_selectedHour].timeUtc
        : null;
    final locationChanged =
        _initialized &&
        _source.location.coordinates != current.location.coordinates;
    _source = current;
    _days = _builder.build(current);
    _loadCoast(current);
    _initialized = true;
    if (selectedTime == null || locationChanged) {
      _selectedDay = 0;
      _selectedHour = _currentHourIndex();
    } else {
      final dayIndex = _days.indexWhere(
        (day) => day.hours.any((hour) => hour.timeUtc == selectedTime),
      );
      if (dayIndex < 0) {
        _selectedDay = 0;
        _selectedHour = _currentHourIndex();
      } else {
        _selectedDay = dayIndex;
        _selectedHour = _days[dayIndex].hours.indexWhere(
          (hour) => hour.timeUtc == selectedTime,
        );
      }
    }
    _scrollToHour();
  }

  int _currentHourIndex() {
    final index = _days.first.hours.indexWhere((hour) => hour.isCurrent);
    return index < 0 ? 0 : index;
  }

  void _loadCoast(FishingConditions conditions) {
    final location = conditions.location;
    final key = '${location.coordinates}:${conditions.isAllSample}';
    if (_coastRequestKey == key) return;
    _coastRequestKey = key;
    _coast = CoastOrientationService.shared.cachedFor(location);
    if (conditions.isAllSample) return;
    CoastOrientationService.shared.lookup(location).then((result) {
      if (mounted && _coastRequestKey == key) {
        setState(() => _coast = result);
      }
    });
  }

  void _scrollToHour() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_hourScroll.hasClients) return;
      final viewport = _hourScroll.position.viewportDimension;
      final offset =
          (_selectedHour * HourlyFishingSlider.itemExtent - (viewport - 98) / 2)
              .clamp(0.0, _hourScroll.position.maxScrollExtent);
      _hourScroll.animateTo(
        offset,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
    });
  }

  void _selectHour(int index) {
    if (index == _selectedHour) return;
    setState(() => _selectedHour = index);
  }

  void _selectDay(int index) {
    if (index == _selectedDay) return;
    setState(() => _selectedDay = index);
    _scrollToHour();
  }

  void _shiftHour(int delta) {
    final absolute = (_selectedDay * 24 + _selectedHour + delta).clamp(0, 167);
    setState(() {
      _selectedDay = absolute ~/ 24;
      _selectedHour = absolute % 24;
    });
    _scrollToHour();
  }

  @override
  void dispose() {
    _hourScroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = FishingConditionsScope.controllerOf(context);
    if (!_source.hasLiveForecast) {
      return Scaffold(
        appBar: AppBar(title: const Text('Fishing Conditions Details')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  controller.showSkeleton
                      ? 'Loading weather and marine forecasts…'
                      : 'Live conditions are unavailable for this location.',
                  textAlign: TextAlign.center,
                ),
                if (!controller.showSkeleton)
                  TextButton.icon(
                    onPressed: () => controller.refresh(forceRefresh: true),
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Retry'),
                  ),
              ],
            ),
          ),
        ),
      );
    }
    final day = _days[_selectedDay];
    final hour = day.hours[_selectedHour];
    final tabTitle = const ['SUMMARY', 'TIDES', 'SUN'][_selectedTab];
    return Scaffold(
      appBar: AppBar(title: const Text('Fishing Conditions Details')),
      body: Column(
        children: [
          _contentWidth(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ConditionsSegmentedTabs(
                  selectedIndex: _selectedTab,
                  onSelected: (index) => setState(() => _selectedTab = index),
                ),
                const SizedBox(height: 15),
                Text(
                  tabTitle,
                  style: const TextStyle(
                    color: AppColors.aqua,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _dateLabel(day.dateLocal),
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    const Icon(
                      Icons.location_on_rounded,
                      color: AppColors.blue,
                      size: 16,
                    ),
                    const SizedBox(width: 3),
                    Expanded(
                      child: Text(
                        _source.location.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Conditions at ${_clock(hour.localTime)}'
                        '${hour.isCurrent ? ' · NOW' : ''}',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    _HourArrow(
                      key: const Key('details-previous-hour'),
                      icon: Icons.chevron_left_rounded,
                      enabled: _selectedDay != 0 || _selectedHour != 0,
                      onTap: () => _shiftHour(-1),
                    ),
                    const SizedBox(width: 6),
                    _HourArrow(
                      key: const Key('details-next-hour'),
                      icon: Icons.chevron_right_rounded,
                      enabled: _selectedDay != 6 || _selectedHour != 23,
                      onTap: () => _shiftHour(1),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  controller.showSkeleton
                      ? 'Loading conditions…'
                      : _source.sourceLabel,
                  style: const TextStyle(color: AppColors.muted, fontSize: 10),
                ),
                const SizedBox(height: 14),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => controller.refresh(forceRefresh: true),
              child: IndexedStack(
                index: _selectedTab,
                children: [
                  _scrollTab(
                    key: const PageStorageKey('summary-tab'),
                    child: FishingSummaryTab(
                      days: _days,
                      selectedDay: _selectedDay,
                      selectedHour: _selectedHour,
                      hourController: _hourScroll,
                      onDaySelected: _selectDay,
                      onHourSelected: _selectHour,
                      loading: controller.showSkeleton,
                      coast: _coast,
                    ),
                  ),
                  _scrollTab(
                    key: const PageStorageKey('tides-tab'),
                    child: TideDetailsCard(
                      days: _days,
                      selectedDay: _selectedDay,
                      selectedHour: _selectedHour,
                    ),
                  ),
                  _scrollTab(
                    key: const PageStorageKey('sun-tab'),
                    child: SunMoonDetailsCard(
                      conditions: _source,
                      day: day,
                      hour: hour,
                      dayOffset: _selectedDay,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _scrollTab({required Key key, required Widget child}) =>
      SingleChildScrollView(
        key: key,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 42),
        child: _contentWidth(child: child),
      );

  Widget _contentWidth({required Widget child}) => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 940),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: child,
      ),
    ),
  );

  static String _dateLabel(DateTime date) {
    const weekdays = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${weekdays[date.weekday - 1]}, ${months[date.month - 1]} ${date.day}';
  }

  static String _clock(DateTime local) {
    final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
    return '$hour:${local.minute.toString().padLeft(2, '0')} ${local.hour < 12 ? 'AM' : 'PM'}';
  }
}

class ConditionsSegmentedTabs extends StatelessWidget {
  const ConditionsSegmentedTabs({
    super.key,
    required this.selectedIndex,
    required this.onSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(4),
    decoration: BoxDecoration(
      color: AppColors.mist,
      borderRadius: BorderRadius.circular(19),
    ),
    child: Row(
      children: [
        for (var index = 0; index < 3; index++)
          Expanded(
            child: GestureDetector(
              key: Key('conditions-tab-$index'),
              onTap: () => onSelected(index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  gradient: index == selectedIndex ? oceanGradient : null,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: index == selectedIndex
                      ? [
                          BoxShadow(
                            color: AppColors.aqua.withValues(alpha: .18),
                            blurRadius: 12,
                          ),
                        ]
                      : null,
                ),
                child: Text(
                  const ['Summary', 'Tides', 'Sun'][index],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: index == selectedIndex
                        ? Colors.white
                        : AppColors.muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ),
      ],
    ),
  );
}

class _HourArrow extends StatelessWidget {
  const _HourArrow({
    super.key,
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: enabled ? onTap : null,
    child: Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: AppColors.mist,
        borderRadius: BorderRadius.circular(11),
      ),
      child: Icon(
        icon,
        color: enabled ? AppColors.blue : AppColors.muted,
        size: 21,
      ),
    ),
  );
}
