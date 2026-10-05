import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Stores the name entered during onboarding for use across the app.
class UserProfileService extends ChangeNotifier {
  UserProfileService();

  static final UserProfileService instance = UserProfileService();
  static const _nameKey = 'profile.display_name.v1';
  static const _onboardingKey = 'profile.onboarding_complete.v1';
  static const _notificationsKey = 'preferences.notifications.v1';
  static const _tourSeenKey = 'profile.onboarding_seen.v1';
  static const _joinedYearKey = 'profile.joined_year.v1';

  String _displayName = '';
  bool _notificationsEnabled = false;
  bool _onboardingComplete = false;
  bool _onboardingSeen = false;
  int? _joinedYear;
  Future<void>? _loadFuture;

  bool get notificationsEnabled => _notificationsEnabled;

  String get displayName => _displayName;
  String get firstName => _displayName.trim().split(RegExp(r'\s+')).first;
  bool get onboardingComplete => _onboardingComplete;
  bool get onboardingSeen => _onboardingSeen || _onboardingComplete;
  int? get joinedYear => _joinedYear;

  Future<void> load() => _loadFuture ??= _loadFromStorage();

  Future<void> _loadFromStorage() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      _displayName = preferences.getString(_nameKey)?.trim() ?? '';
      _notificationsEnabled = preferences.getBool(_notificationsKey) ?? false;
      _onboardingComplete = preferences.getBool(_onboardingKey) ?? false;
      _onboardingSeen = preferences.getBool(_tourSeenKey) ?? false;
      _joinedYear = preferences.getInt(_joinedYearKey);
    } catch (_) {
      // A local storage failure still lets the user complete this session.
    }
    notifyListeners();
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    await load();
    _notificationsEnabled = enabled;
    notifyListeners();
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_notificationsKey, enabled);
  }

  Future<void> markOnboardingSeen() async {
    await load();
    _onboardingSeen = true;
    try {
      final preferences = await SharedPreferences.getInstance();
      await preferences.setBool(_tourSeenKey, true);
    } catch (_) {
      // Retain the first-launch decision for this session.
    }
  }

  Future<void> completeOnboarding(String name) async {
    final cleaned = name.trim();
    if (cleaned.isEmpty) return;
    await load();
    _displayName = cleaned;
    _onboardingComplete = true;
    _joinedYear ??= DateTime.now().year;
    try {
      final preferences = await SharedPreferences.getInstance();
      await preferences.setString(_nameKey, cleaned);
      await preferences.setInt(_joinedYearKey, _joinedYear!);
      await preferences.setBool(_onboardingKey, true);
    } catch (_) {
      // Keep the in-memory profile available if persistence fails.
    }
    notifyListeners();
  }

  Future<void> updateName(String name) async {
    final cleaned = name.trim();
    if (cleaned.isEmpty) return;
    await load();
    _displayName = cleaned;
    try {
      final preferences = await SharedPreferences.getInstance();
      await preferences.setString(_nameKey, cleaned);
    } catch (_) {
      // Keep the edited name available for this session.
    }
    notifyListeners();
  }
}
