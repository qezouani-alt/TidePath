import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../models/demo_data.dart';
import '../../../services/learn_progress_service.dart';
import '../../../widgets/premium_widgets.dart';
import 'lesson_detail_screen.dart';
import 'topic_lessons_screen.dart';

class LearnScreen extends StatefulWidget {
  const LearnScreen({super.key});
  @override
  State<LearnScreen> createState() => _LearnScreenState();
}

class _LearnScreenState extends State<LearnScreen> {
  LearnProgressService get _progress => LearnProgressService.instance;

  @override
  void initState() {
    super.initState();
    _progress.addListener(_onProgressChanged);
    unawaited(_progress.load());
  }

  @override
  void dispose() {
    _progress.removeListener(_onProgressChanged);
    super.dispose();
  }

  void _onProgressChanged() => setState(() {});

  String get _level {
    final completed = _progress.completedCount;
    if (completed >= 15) return 'Advanced Angler';
    if (completed >= 12) return 'Advanced Angler';
    if (completed >= 9) return 'Skilled Angler';
    if (completed >= 6) return 'Intermediate Angler';
    if (completed >= 3) return 'Confident Beginner';
    return 'Beginner Explorer';
  }

  Lesson? get _nextLesson {
    for (final lesson in DemoData.lessons) {
      if (!_progress.isCompleted(lesson.id)) return lesson;
    }
    return null;
  }

  void _openLesson(Lesson lesson) =>
      pushPage(context, LessonDetailScreen(lesson: lesson));

  @override
  Widget build(BuildContext context) {
    final nextLesson = _nextLesson;
    final completedCount = _progress.completedCount.clamp(
      0,
      DemoData.lessons.length,
    );
    return SingleChildScrollView(
      padding: const EdgeInsets.only(top: 22, bottom: 120),
      child: ScreenPadding(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Learn Fishing',
              style: Theme.of(context).textTheme.headlineLarge,
            ),
            const SizedBox(height: 5),
            const Text(
              'Build confidence, one lesson at a time.',
              style: TextStyle(color: AppColors.muted, fontSize: 14),
            ),
            const SizedBox(height: 22),
            Container(
              padding: const EdgeInsets.all(21),
              decoration: BoxDecoration(
                gradient: oceanGradient,
                borderRadius: BorderRadius.circular(25),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'YOUR FISHING LEVEL',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 7),
                        Text(
                          _level,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: completedCount / DemoData.lessons.length,
                            minHeight: 7,
                            color: Color(0xFF7AE1DC),
                            backgroundColor: Colors.white24,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          completedCount == DemoData.lessons.length
                              ? 'All ${DemoData.lessons.length} lessons complete — keep practising!'
                              : '$completedCount of ${DemoData.lessons.length} lessons complete',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 18),
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: .15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.emoji_events_outlined,
                      color: Colors.white,
                      size: 29,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 27),
            const SectionHeader('Continue learning'),
            if (nextLesson != null)
              LessonCard(
                lesson: nextLesson,
                onTap: () => _openLesson(nextLesson),
              )
            else
              const AppCard(
                child: Text(
                  'You’ve completed the learning path. Pick a topic to keep building your skills.',
                ),
              ),
            const SizedBox(height: 28),
            const SectionHeader('Lesson topics'),
            LayoutBuilder(
              builder: (context, constraints) {
                const categories = [
                  ('Getting Started', Icons.sailing_rounded),
                  ('Fishing Gear', Icons.sports_rounded),
                  ('Fishing Knots', Icons.link_rounded),
                  ('Baits & Lures', Icons.phishing_rounded),
                  ('Surf Fishing', Icons.waves_rounded),
                  ('Rock Fishing', Icons.terrain_rounded),
                  ('Safety', Icons.health_and_safety_outlined),
                  ('Fishing Techniques', Icons.auto_awesome_rounded),
                  ('Fish Care', Icons.favorite_outline_rounded),
                  ('Fish Identification', Icons.set_meal_rounded),
                  ('Advanced Skills', Icons.school_rounded),
                ];
                final availableCategories = categories
                    .where(
                      (topic) => DemoData.lessons.any(
                        (lesson) => lesson.category == topic.$1,
                      ),
                    )
                    .toList();
                final columns = constraints.maxWidth > 920
                    ? 4
                    : constraints.maxWidth > 620
                    ? 3
                    : 2;
                return GridView.count(
                  crossAxisCount: columns,
                  mainAxisExtent: 66,
                  crossAxisSpacing: 12,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children: availableCategories.map((entry) {
                    final topicLessons = DemoData.lessons
                        .where((lesson) => lesson.category == entry.$1)
                        .toList();
                    final doneCount = topicLessons
                        .where((lesson) => _progress.isCompleted(lesson.id))
                        .length;
                    return Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => pushPage(
                          context,
                          TopicLessonsScreen(
                            category: entry.$1,
                            icon: entry.$2,
                          ),
                        ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: Theme.of(context)
                                    .colorScheme
                                    .outlineVariant
                                    .withValues(alpha: .45),
                              ),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(entry.$2, color: AppColors.blue, size: 20),
                              const SizedBox(width: 9),
                              Expanded(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      entry.$1,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        height: 1.1,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      '${topicLessons.length} ${topicLessons.length == 1 ? 'lesson' : 'lessons'} · $doneCount done',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: AppColors.muted,
                                        fontSize: 9,
                                        fontWeight: FontWeight.w600,
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
                  }).toList(),
                );
              },
            ),
            const SizedBox(height: 28),
            const SectionHeader('Your learning path'),
            ...[
              (
                '1 · Start from zero',
                'Safety, gear, and first-trip confidence',
                DemoData.lessons.sublist(0, 3),
              ),
              (
                '2 · Learn the essentials',
                'Knots, bait, and casting',
                DemoData.lessons.sublist(3, 6),
              ),
              (
                '3 · Understand the water',
                'Tides, weather, and finding a spot',
                DemoData.lessons.sublist(6, 9),
              ),
              (
                '4 · Fish different coasts',
                'Beach, rocks, fish care, and identification',
                DemoData.lessons.sublist(9, 12),
              ),
              (
                '5 · Plan like a pro',
                'Build your own repeatable fishing strategy',
                DemoData.lessons.sublist(12),
              ),
            ].expand(
              (stage) => [
                Padding(
                  padding: const EdgeInsets.only(top: 8, bottom: 9),
                  child: Text(
                    stage.$1,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 9),
                  child: Text(
                    stage.$2,
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 12,
                    ),
                  ),
                ),
                ...stage.$3.map(
                  (lesson) => Padding(
                    padding: const EdgeInsets.only(bottom: 11),
                    child: LessonCard(
                      lesson: lesson,
                      completed: _progress.isCompleted(lesson.id),
                      onTap: () => _openLesson(lesson),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
