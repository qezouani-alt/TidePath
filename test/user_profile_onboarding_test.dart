import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fishing/services/user_profile_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'tour is seen after first launch even without completing the name step',
    () async {
      SharedPreferences.setMockInitialValues({});
      final firstLaunch = UserProfileService();
      await firstLaunch.load();
      expect(firstLaunch.onboardingSeen, isFalse);
      await firstLaunch.markOnboardingSeen();
      final nextLaunch = UserProfileService();
      await nextLaunch.load();
      expect(nextLaunch.onboardingSeen, isTrue);
      expect(nextLaunch.onboardingComplete, isFalse);
      firstLaunch.dispose();
      nextLaunch.dispose();
    },
  );

  test(
    'existing completed onboarding skips the tour without a stored name',
    () async {
      SharedPreferences.setMockInitialValues({
        'profile.onboarding_complete.v1': true,
      });
      final profile = UserProfileService();
      await profile.load();
      expect(profile.onboardingSeen, isTrue);
      profile.dispose();
    },
  );
}
