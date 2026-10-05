import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../models/demo_data.dart';
import '../../../services/learn_progress_service.dart';
import '../../../widgets/premium_widgets.dart';
import 'lesson_detail_screen.dart';

class TopicLessonsScreen extends StatefulWidget {
  const TopicLessonsScreen({
    super.key,
    required this.category,
    required this.icon,
  });

  final String category;
  final IconData icon;

  @override
  State<TopicLessonsScreen> createState() => _TopicLessonsScreenState();
}

class _TopicLessonsScreenState extends State<TopicLessonsScreen> {
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

  String get _description => switch (widget.category) {
    'Getting Started' => 'Start with the essentials: choose a safe place, check local rules, and plan a simple first trip.',
    'Fishing Gear' => 'Understand the basic tackle and choose a rod and reel that suit your fishing.',
    'Fishing Knots' => 'Learn a dependable knot and practise tying it until you can do it confidently.',
    'Baits & Lures' => 'Choose a simple bait or lure that fits your target fish and local rules.',
    'Surf Fishing' => 'Learn to fish from shore and read beach conditions while keeping people safe.',
    'Rock Fishing' =>
      'Build safer habits for rocky shorelines and changing swell.',
    'Safety' =>
      'Prepare for changing weather, waves, slippery ground, and sharp hooks.',
    'Fishing Techniques' => 'Read tides, weather, and shoreline features to make better fishing decisions.',
    'Fish Care' => 'Handle fish carefully and understand what to do before releasing or keeping a catch.',
    'Fish Identification' => 'Recognize common fish using several features and check local rules before keeping a catch.',
    'Advanced Skills' => 'Plan fishing sessions, record what happens, and improve through deliberate practice.',
    _ => 'Learn practical fishing skills at your own pace.',
  };

  @override
  Widget build(BuildContext context) {
    final lessons = DemoData.lessons
        .where((lesson) => lesson.category == widget.category)
        .toList();
    final completed = lessons
        .where((lesson) => _progress.isCompleted(lesson.id))
        .length;
    final nextLesson = lessons.cast<Lesson?>().firstWhere(
      (lesson) => !_progress.isCompleted(lesson?.id),
      orElse: () => null,
    );

    return Scaffold(
      appBar: AppBar(title: Text(widget.category)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(top: 12, bottom: 36),
          child: ScreenPadding(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(19),
                  decoration: BoxDecoration(
                    gradient: oceanGradient,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 58,
                        height: 58,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: .16),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(widget.icon, color: Colors.white, size: 29),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$completed of ${lessons.length} lessons complete',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 9),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: LinearProgressIndicator(
                                value: lessons.isEmpty
                                    ? 0
                                    : completed / lessons.length,
                                minHeight: 7,
                                color: AppColors.glow,
                                backgroundColor: Colors.white24,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  _description,
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
                if (nextLesson != null) ...[
                  const SizedBox(height: 22),
                  GradientButton(
                    completed == 0 ? 'Start this topic' : 'Continue this topic',
                    icon: Icons.play_arrow_rounded,
                    onPressed: () => pushPage(
                      context,
                      LessonDetailScreen(lesson: nextLesson),
                    ),
                  ),
                ],
                const SizedBox(height: 27),
                SectionHeader(
                  completed == lessons.length && lessons.isNotEmpty
                      ? 'Topic completed'
                      : 'Lessons in ${widget.category}',
                ),
                if (lessons.isEmpty)
                  const AppCard(
                    child: Text('Lessons for this topic are coming soon.'),
                  )
                else
                  ...lessons.map(
                    (lesson) => Padding(
                      padding: const EdgeInsets.only(bottom: 11),
                      child: LessonCard(
                        lesson: lesson,
                        completed: _progress.isCompleted(lesson.id),
                        onTap: () => pushPage(
                          context,
                          LessonDetailScreen(lesson: lesson),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
