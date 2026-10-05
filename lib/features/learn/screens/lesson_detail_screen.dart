import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../models/demo_data.dart';
import '../../../services/app_navigation_service.dart';
import '../../../services/learn_progress_service.dart';
import '../../../widgets/premium_widgets.dart';
import '../widgets/lesson_knowledge_check.dart';

class LessonDetailScreen extends StatefulWidget {
  const LessonDetailScreen({super.key, required this.lesson});
  final Lesson lesson;
  @override
  State<LessonDetailScreen> createState() => _LessonDetailScreenState();
}

class _LessonDetailScreenState extends State<LessonDetailScreen> {
  bool bookmarked = false;

  @override
  void initState() {
    super.initState();
    unawaited(LearnProgressService.instance.load());
  }

  void _returnToLearn() {
    AppNavigationService.goToLearn();
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final completed = LearnProgressService.instance.isCompleted(
      widget.lesson.id,
    );
    final steps = widget.lesson.steps;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lesson'),
        actions: [
          IconButton(
            onPressed: () => setState(() => bookmarked = !bookmarked),
            icon: Icon(
              bookmarked
                  ? Icons.bookmark_rounded
                  : Icons.bookmark_border_rounded,
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: ScreenPadding(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 7),
                      Container(
                        height: 205,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          gradient: oceanGradient,
                          borderRadius: BorderRadius.circular(25),
                        ),
                        child: Stack(
                          children: [
                            Center(
                              child: Icon(
                                widget.lesson.icon,
                                size: 100,
                                color: Colors.white.withValues(alpha: .7),
                              ),
                            ),
                            Positioned(
                              bottom: 17,
                              left: 18,
                              child: LabelPill(
                                widget.lesson.category.toUpperCase(),
                                color: Colors.white,
                                textColor: AppColors.ocean,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 22),
                      Text(
                        widget.lesson.title,
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      if (widget.lesson.description.isNotEmpty) ...[
                        const SizedBox(height: 9),
                        Text(
                          widget.lesson.description,
                          style: const TextStyle(
                            color: AppColors.muted,
                            height: 1.45,
                            fontSize: 14,
                          ),
                        ),
                      ],
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          const Icon(
                            Icons.school_outlined,
                            color: AppColors.aqua,
                            size: 16,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            widget.lesson.difficulty,
                            style: const TextStyle(
                              color: AppColors.muted,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(width: 17),
                          const Icon(
                            Icons.schedule_rounded,
                            color: AppColors.aqua,
                            size: 16,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            widget.lesson.duration,
                            style: const TextStyle(
                              color: AppColors.muted,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 27),
                      const SectionHeader('What you’ll learn'),
                      ...List.generate(
                        steps.length,
                        (i) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: AppCard(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 43,
                                  height: 43,
                                  decoration: BoxDecoration(
                                    color: AppColors.mist,
                                    borderRadius: BorderRadius.circular(13),
                                  ),
                                  child: Center(
                                    child: Text(
                                      '0${i + 1}',
                                      style: const TextStyle(
                                        color: AppColors.blue,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Step ${i + 1}',
                                        style: const TextStyle(
                                          color: AppColors.blue,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 12,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        steps[i],
                                        style: const TextStyle(
                                          fontSize: 13,
                                          height: 1.45,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 3),
                      LessonKnowledgeCheck(lessonId: widget.lesson.id ?? ''),
                      if (widget.lesson.practice.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        AppCard(
                          color: AppColors.mist,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.sports_handball_outlined,
                                color: AppColors.blue,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Try it yourself',
                                      style: TextStyle(
                                        color: AppColors.blue,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    const SizedBox(height: 5),
                                    Text(
                                      widget.lesson.practice,
                                      style: const TextStyle(height: 1.4),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      if (widget.lesson.takeaway.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        AppCard(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.lightbulb_outline_rounded,
                                color: AppColors.aqua,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  widget.lesson.takeaway,
                                  style: const TextStyle(
                                    height: 1.4,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ),
            ScreenPadding(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: GradientButton(
                  completed ? 'Lesson Completed ✓' : 'Complete Lesson',
                  icon: Icons.check_circle_outline_rounded,
                  onPressed: () async {
                    if (completed) {
                      _returnToLearn();
                      return;
                    }
                    await LearnProgressService.instance.complete(
                      widget.lesson.id,
                    );
                    if (!context.mounted) return;
                    _returnToLearn();
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
