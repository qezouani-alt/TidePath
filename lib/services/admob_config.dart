/// Real iOS AdMob ad unit IDs. Paste your IDs in the defaultValue fields,
/// or provide them with --dart-define. Empty values disable the ad format.
abstract final class AdMobConfig {
  static const appOpenUnitId = String.fromEnvironment(
    'ADMOB_IOS_APP_OPEN_ID',
    defaultValue: 'ca-app-pub-2535194044471316/7277341828', // Paste the real iOS app-open ad unit ID here.
  );

  static const interstitialUnitId = String.fromEnvironment(
    'ADMOB_IOS_INTERSTITIAL_ID',
    defaultValue: 'ca-app-pub-2535194044471316/4956188405', // Paste the real iOS interstitial ad unit ID here.
  );

  static bool isConfigured(String unit) =>
      RegExp(r'^ca-app-pub-\d+/\d+$').hasMatch(unit);
}
