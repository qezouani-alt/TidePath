import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Tracks lesson completion during the current app session.
///
/// Lesson IDs are stable curriculum keys so lesson titles can be edited without
/// losing the learner's progress when durable storage is added later.
class LearnProgressService extends ChangeNotifier {
  LearnProgressService._();

  static final LearnProgressService instance = LearnProgressService._();

  final Set<String> _completedLessonIds = <String>{};
  Future<void>? _loadFuture;
  static const _storageKey = 'learn.completed_lesson_ids.v1';

  Set<String> get completedLessonIds => Set.unmodifiable(_completedLessonIds);
  int get completedCount => _completedLessonIds.length;

  Future<void> load() => _loadFuture ??= _loadFromStorage();

  Future<void> _loadFromStorage() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      _completedLessonIds
        ..clear()
        ..addAll(preferences.getStringList(_storageKey) ?? const <String>[]);
    } catch (_) {
      // Keep progress available for this session if local storage is unavailable.
    }
    notifyListeners();
  }

  bool isCompleted(String? lessonId) =>
      lessonId != null && _completedLessonIds.contains(lessonId);

  Future<void> complete(String? lessonId) async {
    if (lessonId == null) return;
    await load();
    if (!_completedLessonIds.add(lessonId)) return;
    await _save();
    notifyListeners();
  }

  Future<void> reset() async {
    await load();
    if (_completedLessonIds.isEmpty) return;
    _completedLessonIds.clear();
    await _save();
    notifyListeners();
  }

  Future<void> _save() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      await preferences.setStringList(
        _storageKey,
        _completedLessonIds.toList(),
      );
    } catch (_) {
      // The in-memory state remains usable if saving fails.
    }
  }
}
