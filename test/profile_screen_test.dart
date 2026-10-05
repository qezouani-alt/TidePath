import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fishing/core/theme/app_theme.dart';
import 'package:fishing/features/profile/screens/profile_screen.dart';
import 'package:fishing/services/user_profile_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'compact profile shows actions, saves notifications, and opens privacy',
    (tester) async {
      const permissions = MethodChannel(
        'flutter.baseflow.com/permissions/methods',
      );
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        permissions,
        (call) async {
          if (call.method == 'requestPermissions') return {17: 1};
          if (call.method == 'checkPermissionStatus') return 1;
          return true;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          permissions,
          null,
        ),
      );
      final openedUrls = <String>[];
      const channel = MethodChannel('plugins.flutter.io/url_launcher');
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (
        call,
      ) async {
        if (call.method == 'launch') {
          openedUrls.add((call.arguments as Map)['url'] as String);
          return true;
        }
        return false;
      });
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          channel,
          null,
        ),
      );
      SharedPreferences.setMockInitialValues({});
      await UserProfileService.instance.load();
      tester.view.physicalSize = const Size(375, 812);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: ProfileScreen(darkMode: false, onThemeChanged: (_) {}),
          ),
        ),
      );
      expect(find.text('TidePath Fishing'), findsOneWidget);
      expect(find.text('Share app'), findsOneWidget);
      expect(find.text('Rate app'), findsOneWidget);
      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();
      final saved = UserProfileService();
      await saved.load();
      expect(saved.notificationsEnabled, isTrue);
      saved.dispose();
      await tester.ensureVisible(find.text('Privacy'));
      await tester.tap(find.text('Privacy'));
      await tester.pumpAndSettle();
      expect(find.text('Legal'), findsNothing);
      expect(find.text('Ad privacy choices'), findsNothing);
      expect(openedUrls, [
        'https://idepathfishingspotfinder.blogspot.com/2026/10/blog-post.html?m=0',
      ]);
      expect(tester.takeException(), isNull);
    },
  );
}
