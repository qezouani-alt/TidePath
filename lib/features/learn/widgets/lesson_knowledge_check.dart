import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../widgets/premium_widgets.dart';

class LessonKnowledgeCheck extends StatefulWidget {
  const LessonKnowledgeCheck({super.key, required this.lessonId});

  final String lessonId;

  @override
  State<LessonKnowledgeCheck> createState() => _LessonKnowledgeCheckState();
}

class _LessonKnowledgeCheckState extends State<LessonKnowledgeCheck> {
  int? _selected;

  @override
  Widget build(BuildContext context) {
    final check = _knowledgeChecks[widget.lessonId];
    if (check == null) return const SizedBox.shrink();
    final selected = _selected;
    return AppCard(
      color: AppColors.mist,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.quiz_outlined, color: AppColors.blue),
              SizedBox(width: 9),
              Text(
                'Quick check',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            check.question,
            style: const TextStyle(fontWeight: FontWeight.w700, height: 1.4),
          ),
          const SizedBox(height: 9),
          ...List.generate(check.options.length, (index) {
            final isSelected = selected == index;
            final isCorrect = check.answerIndex == index;
            final color = isSelected
                ? isCorrect
                      ? AppColors.good
                      : AppColors.warning
                : AppColors.blue.withValues(alpha: .18);
            return Padding(
              padding: const EdgeInsets.only(top: 7),
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () => setState(() => _selected = index),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 13,
                    vertical: 11,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: color, width: isSelected ? 2 : 1),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          check.options[index],
                          style: const TextStyle(fontSize: 12, height: 1.35),
                        ),
                      ),
                      if (isSelected)
                        Icon(
                          isCorrect
                              ? Icons.check_circle_rounded
                              : Icons.info_outline_rounded,
                          color: color,
                          size: 18,
                        ),
                    ],
                  ),
                ),
              ),
            );
          }),
          if (selected != null) ...[
            const SizedBox(height: 11),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  selected == check.answerIndex
                      ? Icons.check_circle_rounded
                      : Icons.lightbulb_outline_rounded,
                  color: selected == check.answerIndex
                      ? AppColors.good
                      : AppColors.blue,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    check.explanation,
                    style: const TextStyle(fontSize: 12, height: 1.4),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _KnowledgeCheck {
  const _KnowledgeCheck(
    this.question,
    this.options,
    this.answerIndex,
    this.explanation,
  );

  final String question;
  final List<String> options;
  final int answerIndex;
  final String explanation;
}

const _knowledgeChecks = <String, _KnowledgeCheck>{
  'first_trip': _KnowledgeCheck(
    'What is the best first step before choosing a place to fish?',
    [
      'Buy the heaviest rod',
      'Check access and local rules',
      'Cast as far as possible',
    ],
    1,
    'Start with a safe, legal place you can reach comfortably. Then pack gear to suit it.',
  ),
  'rod_reel': _KnowledgeCheck(
    'What should match the rod’s line rating?',
    ['The color of the bait', 'The time of sunrise', 'The line and reel setup'],
    2,
    'A balanced rod, reel, and line are easier to use and help avoid equipment problems.',
  ),
  'water_safety': _KnowledgeCheck(
    'The rocks are wet and waves are reaching higher than before. What should you do?',
    [
      'Stand closer to the edge',
      'Move to a safer place or leave',
      'Turn your back to the waves',
    ],
    1,
    'Changing waves can reach unexpectedly far. Leave exposed rocks and keep a safe route back.',
  ),
  'palomar_knot': _KnowledgeCheck(
    'Why moisten the line before tightening the knot?',
    [
      'To make the hook heavier',
      'To change the line color',
      'To reduce heat and friction',
    ],
    2,
    'Moistening reduces friction as the knot tightens. Pull smoothly and test it before fishing.',
  ),
  'bait_lure_basics': _KnowledgeCheck(
    'How should you choose bait or a lure?',
    [
      'Always use the largest one',
      'Match it to a legal local target fish',
      'Choose by color alone',
    ],
    1,
    'Target species, local rules, water, and the size of the offering all matter.',
  ),
  'shore_cast': _KnowledgeCheck(
    'What must you do before every cast?',
    [
      'Look only at the target',
      'Cast harder into the wind',
      'Check that the casting area is clear',
    ],
    2,
    'Check behind and beside you for people, wires, and obstacles before swinging the rod.',
  ),
  'read_tides': _KnowledgeCheck(
    'Where should you check tide times for a fishing place?',
    [
      'A reliable local tide table',
      'A tide time from another coast',
      'The cloud color',
    ],
    0,
    'Tide times vary by place. Use a local table and keep an escape route as water rises.',
  ),
  'read_conditions': _KnowledgeCheck(
    'How should you use a weather forecast at the coast?',
    [
      'Check it, then observe conditions in person',
      'Assume it cannot change',
      'Ignore wind gusts',
    ],
    0,
    'Forecasts help you plan, but recheck the sea and weather during your trip and leave if unsafe.',
  ),
  'choose_spot': _KnowledgeCheck(
    'What makes a useful fishing spot choice?',
    [
      'Fish habitat plus safe legal access',
      'The longest walk',
      'The most crowded place',
    ],
    0,
    'Look for structure and food while making sure the place is legal, accessible, and safe for you.',
  ),
  'sandy_beach': _KnowledgeCheck(
    'Where should you cast on a busy beach?',
    [
      'Only where people are clear of your line',
      'Toward swimmers',
      'Across other anglers’ lines',
    ],
    0,
    'Keep hooks and lines well away from swimmers and other beach users.',
  ),
  'rock_fishing': _KnowledgeCheck(
    'What is the priority when swell builds on exposed rocks?',
    [
      'Leave for a safer place',
      'Move closer to the water',
      'Carry more tackle down',
    ],
    0,
    'Swell can wash over rocks. Leave early and never rely on a single calm moment.',
  ),
  'fish_care': _KnowledgeCheck(
    'What helps protect a fish you plan to release?',
    [
      'Wet hands and gentle support',
      'Squeeze the body firmly',
      'Keep it out of water longer',
    ],
    0,
    'Handle the fish briefly and gently, avoid the gills, and follow local fish-care advice.',
  ),
  'identify_fish': _KnowledgeCheck(
    'You are unsure which species you caught. What is a careful choice?',
    [
      'Release it carefully and verify later',
      'Keep it without checking',
      'Guess from one marking',
    ],
    0,
    'Similar species can look alike. Check a trusted regional guide and local rules before keeping a fish.',
  ),
  'plan_session': _KnowledgeCheck(
    'What should a useful trip plan include?',
    [
      'Target, conditions, safety, and a backup',
      'Only a favorite lure',
      'A promise to stay all day',
    ],
    0,
    'Choose a realistic target, check conditions and access, and have a safe alternative ready.',
  ),
  'fishing_strategy': _KnowledgeCheck(
    'How can you learn what change helped during a session?',
    [
      'Change one thing at a time and take notes',
      'Change everything at once',
      'Remember only the catch',
    ],
    0,
    'A simple trip log and one change at a time make it easier to learn from results.',
  ),
};
