import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../models/fishing_forecast.dart';

class SummaryTimeSlider extends StatelessWidget {
  const SummaryTimeSlider({
    super.key,
    required this.selectedHour,
    required this.onSelected,
  });

  final int selectedHour;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text('TIME OF DAY', style: _sectionStyle),
      const SizedBox(height: 7),
      Row(
        children: [
          _arrow(
            'Previous hour',
            Icons.chevron_left_rounded,
            selectedHour > 0,
            () => onSelected(selectedHour - 1),
          ),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) => GestureDetector(
                key: const Key('summary-time-slider'),
                behavior: HitTestBehavior.opaque,
                onTapDown: (details) =>
                    _choose(details.localPosition.dx, constraints.maxWidth),
                onHorizontalDragUpdate: (details) =>
                    _choose(details.localPosition.dx, constraints.maxWidth),
                child: SizedBox(
                  height: 30,
                  child: Stack(
                    alignment: Alignment.centerLeft,
                    children: [
                      Container(
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: .23),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      FractionallySizedBox(
                        widthFactor: selectedHour / 23,
                        child: Container(
                          height: 5,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [AppColors.blue, AppColors.glow],
                            ),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                      AnimatedPositioned(
                        duration: const Duration(milliseconds: 180),
                        curve: Curves.easeOut,
                        left: (constraints.maxWidth - 18) * selectedHour / 23,
                        child: Container(
                          width: 18,
                          height: 18,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.glow,
                            border: Border.all(color: Colors.white, width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.aqua.withValues(alpha: .55),
                                blurRadius: 11,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          _arrow(
            'Next hour',
            Icons.chevron_right_rounded,
            selectedHour < 23,
            () => onSelected(selectedHour + 1),
          ),
        ],
      ),
      const Padding(
        padding: EdgeInsets.symmetric(horizontal: 30),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('0h', style: _tickStyle),
            Text('6h', style: _tickStyle),
            Text('12h', style: _tickStyle),
            Text('18h', style: _tickStyle),
            Text('0h', style: _tickStyle),
          ],
        ),
      ),
    ],
  );

  void _choose(double x, double width) =>
      onSelected((x / width * 23).round().clamp(0, 23));

  Widget _arrow(
    String label,
    IconData icon,
    bool enabled,
    VoidCallback onTap,
  ) => IconButton(
    tooltip: label,
    onPressed: enabled ? onTap : null,
    visualDensity: VisualDensity.compact,
    constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
    padding: EdgeInsets.zero,
    icon: Icon(
      icon,
      color: enabled ? AppColors.glow : Colors.white38,
      size: 25,
    ),
  );
}

class SummaryWeekSelector extends StatelessWidget {
  const SummaryWeekSelector({
    super.key,
    required this.days,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<FishingForecastDay> days;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Row(
        children: [
          Expanded(child: Text('7-DAY OUTLOOK', style: _sectionStyle)),
          SizedBox(width: 5),
          Text('CONDITIONS INDEX', style: _captionStyle),
        ],
      ),
      const SizedBox(height: 12),
      SizedBox(
        height: 96,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: days.length,
          separatorBuilder: (_, _) => const SizedBox(width: 11),
          itemBuilder: (context, index) {
            final day = days[index];
            final selected = selectedIndex == index;
            return Semantics(
              button: true,
              selected: selected,
              label:
                  '${_weekday(day.dateLocal)} ${day.dateLocal.day}, ${day.score.score} conditions index',
              child: GestureDetector(
                key: Key('summary-day-$index'),
                onTap: () => onSelected(index),
                child: SizedBox(
                  width: 56,
                  child: Column(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        width: 55,
                        height: 55,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: selected
                              ? AppColors.glow
                              : Colors.white.withValues(alpha: .07),
                          border: Border.all(
                            color: selected
                                ? AppColors.glow
                                : AppColors.aqua.withValues(alpha: .65),
                            width: selected ? 2 : 1.3,
                          ),
                          boxShadow: selected
                              ? [
                                  BoxShadow(
                                    color: AppColors.aqua.withValues(
                                      alpha: .35,
                                    ),
                                    blurRadius: 14,
                                  ),
                                ]
                              : null,
                        ),
                        child: Text(
                          '${day.dateLocal.day}',
                          style: TextStyle(
                            color: selected ? AppColors.deep : Colors.white,
                            fontSize: 19,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _weekday(day.dateLocal),
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        '${day.score.score}',
                        style: const TextStyle(
                          color: AppColors.glow,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    ],
  );

  static String _weekday(DateTime date) =>
      const ['Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa', 'Su'][date.weekday - 1];
}

const _sectionStyle = TextStyle(
  color: Colors.white,
  fontSize: 11,
  fontWeight: FontWeight.w900,
  letterSpacing: .85,
);
const _captionStyle = TextStyle(
  color: Colors.white70,
  fontSize: 9,
  fontWeight: FontWeight.w700,
);
const _tickStyle = TextStyle(
  color: Colors.white70,
  fontSize: 10,
  fontWeight: FontWeight.w700,
);
