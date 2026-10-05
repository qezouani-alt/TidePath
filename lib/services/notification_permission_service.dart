import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'user_profile_service.dart';

class NotificationPermissionService {
  NotificationPermissionService({
    UserProfileService? profile,
    Future<PermissionStatus> Function()? request,
    Future<PermissionStatus> Function()? status,
    bool? supported,
  }) : profile = profile ?? UserProfileService.instance,
       request = request ?? (() => Permission.notification.request()),
       status = status ?? (() => Permission.notification.status),
       supported =
           supported ??
           (!kIsWeb &&
               [
                 TargetPlatform.android,
                 TargetPlatform.iOS,
               ].contains(defaultTargetPlatform));

  static final shared = NotificationPermissionService();
  static const _askedKey = 'notifications.permission_asked.v1';
  final UserProfileService profile;
  final Future<PermissionStatus> Function() request, status;
  final bool supported;

  bool _allowed(PermissionStatus value) =>
      value.isGranted || value.isProvisional;

  Future<void> requestOnLaunch() async {
    if (!supported) return;
    try {
      final preferences = await SharedPreferences.getInstance();
      if (preferences.getBool(_askedKey) == true) {
        await syncPermission();
        return;
      }
      final current = await status();
      final result = _allowed(current) ? current : await request();
      await profile.setNotificationsEnabled(_allowed(result));
      await preferences.setBool(_askedKey, true);
    } catch (_) {
      // A permission or platform error must not prevent opening the app.
    }
  }

  Future<bool> setEnabled(bool enabled) async {
    if (!enabled) {
      await profile.setNotificationsEnabled(false);
      return true;
    }
    if (!supported) return false;
    final result = await request();
    final allowed = _allowed(result);
    await profile.setNotificationsEnabled(allowed);
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_askedKey, true);
    return allowed;
  }

  Future<void> syncPermission() async {
    if (!supported) return;
    try {
      await profile.load();
      if (profile.notificationsEnabled && !_allowed(await status())) {
        await profile.setNotificationsEnabled(false);
      }
    } catch (_) {
      // Preserve the preference if the OS status cannot be read.
    }
  }
}
