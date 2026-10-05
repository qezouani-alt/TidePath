import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../models/coast_orientation.dart';
import '../../../models/fishing_conditions.dart';
import '../../../models/fishing_forecast.dart';
import '../../../services/coast_orientation_service.dart';
import '../../../services/fishing_forecast_builder.dart';
import '../../../widgets/premium_widgets.dart';
import '../../conditions/widgets/circular_fishing_dashboard.dart';
import '../../conditions/widgets/summary_forecast_navigation.dart';

/// A quick view of the current hour; the full forecast lives in Details.
class FishingConditionsHeroCard extends StatefulWidget {
  const FishingConditionsHeroCard({
    super.key,
    required this.conditions,
    required this.onDetails,
    this.loading = false,
  });

  final FishingConditions conditions;
  final VoidCallback onDetails;
  final bool loading;

  @override
  State<FishingConditionsHeroCard> createState() =>
      _FishingConditionsHeroCardState();
}

class _FishingConditionsHeroCardState extends State<FishingConditionsHeroCard> {
  static const _builder = FishingForecastBuilder();
  late List<FishingForecastDay> _days;
  late int _selectedHour;
  CoastOrientation? _coast;
  String? _coastRequestKey;

  @override
  void initState() {
    super.initState();
    _days = _builder.build(widget.conditions);
    _selectedHour = _currentHour();
    _loadCoast();
  }

  @override
  void didUpdateWidget(covariant FishingConditionsHeroCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (identical(oldWidget.conditions, widget.conditions)) return;
    final locationChanged =
        oldWidget.conditions.location.coordinates !=
        widget.conditions.location.coordinates;
    _days = _builder.build(widget.conditions);
    if (locationChanged) _selectedHour = _currentHour();
    _loadCoast();
  }

  void _loadCoast() {
    final location = widget.conditions.location;
    final key = '${location.coordinates}:${widget.conditions.isAllSample}';
    if (_coastRequestKey == key) return;
    _coastRequestKey = key;
    _coast = CoastOrientationService.shared.cachedFor(location);
    if (widget.conditions.isAllSample) return;
    CoastOrientationService.shared.lookup(location).then((result) {
      if (mounted && _coastRequestKey == key) {
        setState(() => _coast = result);
      }
    });
  }

  int _currentHour() {
    final index = _days.first.hours.indexWhere((hour) => hour.isCurrent);
    return index < 0 ? 0 : index;
  }

  @override
  Widget build(BuildContext context) {
    final hour = _days.first.hours[_selectedHour];

    return Container(
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
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          children: [
            Positioned(
              top: -80,
              right: -95,
              child: Container(
                width: 260,
                height: 260,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: .07),
                    width: 42,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${hour.score.label} Conditions',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 25,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -.6,
                          ),
                        ),
                      ),
                      const Text(
                        'FORECAST INDEX',
                        style: TextStyle(
                          color: AppColors.glow,
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  CircularFishingDashboard(
                    hour: hour,
                    dayHours: _days.first.hours,
                    coast: _coast,
                    loading: widget.loading,
                  ),
                  const SizedBox(height: 13),
                  Text(
                    '${hour.score.activeFishCount} of 4 indicators highlighted · ${hour.isBestHour ? 'near dawn or dusk' : 'check local wind, waves and tide before heading out'}',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 20),
                  SummaryTimeSlider(
                    selectedHour: _selectedHour,
                    onSelected: (index) =>
                        setState(() => _selectedHour = index),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      key: const Key('home-conditions-more-details'),
                      onPressed: widget.onDetails,
                      iconAlignment: IconAlignment.end,
                      icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                      label: const Text('More details'),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.glow,
                        foregroundColor: AppColors.deep,
                        minimumSize: const Size.fromHeight(46),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
