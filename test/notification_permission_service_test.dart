import 'package:flutter_test/flutter_test.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fishing/services/notification_permission_service.dart';
import 'package:fishing/services/user_profile_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  for (final result in [PermissionStatus.granted, PermissionStatus.denied]) {
    test('startup saves $result and requests only once', () async {
      SharedPreferences.setMockInitialValues({});
      var requests = 0;
      final profile = UserProfileService();
      final service = NotificationPermissionService(
        profile: profile,
        supported: true,
        status: () async => result,
        request: () async {
          requests++;
          return result;
        },
      );
      await service.requestOnLaunch();
      expect(profile.notificationsEnabled, result == PermissionStatus.granted);
      await service.requestOnLaunch();
      expect(requests, result == PermissionStatus.granted ? 0 : 1);
      final restored = UserProfileService();
      await restored.load();
      expect(restored.notificationsEnabled, result == PermissionStatus.granted);
      profile.dispose();
      restored.dispose();
    });
  }
  test('revoked OS permission turns notifications off', () async {
    SharedPreferences.setMockInitialValues({
      'preferences.notifications.v1': true,
    });
    final profile = UserProfileService();
    final service = NotificationPermissionService(
      profile: profile,
      supported: true,
      status: () async => PermissionStatus.denied,
    );
    await service.syncPermission();
    expect(profile.notificationsEnabled, isFalse);
    profile.dispose();
  });
}
