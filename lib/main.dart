import 'dart:async';

import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'features/app_shell.dart';
import 'features/splash/screens/splash_screen.dart';
import 'features/conditions/conditions_scope.dart';
import 'features/location/location_scope.dart';
import 'features/onboarding/screens/onboarding_screen.dart';
import 'models/fishing_location.dart';
import 'services/fishing_conditions_repository.dart';
import 'services/user_profile_service.dart';
import 'services/app_open_ad_service.dart';
import 'services/notification_permission_service.dart';
import 'services/tracking_permission_service.dart';
import 'services/navigation_ad_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final source = GoogleAppOpenAdSource();
  final interstitials = GoogleInterstitialAdSource();
  NavigationAdService.ads = AppOpenAdService(
    loadAd: interstitials.load,
    maxCacheDuration: const Duration(hours: 1),
  );
  runApp(
    TidePathApp(
      appOpenAds: AppOpenAdService(loadAd: source.load),
      notificationPermissions: NotificationPermissionService.shared,
      trackingPermission: TrackingPermissionService.shared,
    ),
  );
}

class TidePathApp extends StatefulWidget {
  const TidePathApp({
    super.key,
    this.conditionsRepository,
    this.appOpenAds,
    this.notificationPermissions,
    this.trackingPermission,
  });
  final FishingConditionsRepository? conditionsRepository;
  final AppOpenAdService? appOpenAds;
  final NotificationPermissionService? notificationPermissions;
  final TrackingPermissionService? trackingPermission;
  @override
  State<TidePathApp> createState() => _TidePathAppState();
}

class _TidePathAppState extends State<TidePathApp> with WidgetsBindingObserver {
  ThemeMode _themeMode = ThemeMode.light;
  bool _splashComplete = false, _showOnboarding = false;
  late final Future<void> _startup = _initializeProfile();
  final _locationController = FishingLocationController();
  late final _conditionsController = FishingConditionsController(
    location: _locationController,
    repository:
        widget.conditionsRepository ?? LiveFishingConditionsRepository(),
  );

  Future<void> _initializeProfile() async {
    await UserProfileService.instance.load();
    _showOnboarding = !UserProfileService.instance.onboardingSeen;
    await widget.notificationPermissions?.requestOnLaunch();
    await widget.trackingPermission?.requestOnLaunch();
    if (!_showOnboarding) unawaited(widget.appOpenAds?.preload());
  }

  Future<void> _finishSplash() async {
    if (_showOnboarding) await UserProfileService.instance.markOnboardingSeen();
    if (!mounted) return;
    if (!_showOnboarding) await widget.appOpenAds?.showIfReady();
    if (mounted) {
      setState(() => _splashComplete = true);
      unawaited(NavigationAdService.ads?.preload());
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _conditionsController.refresh();
      unawaited(widget.notificationPermissions?.syncPermission());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _conditionsController.dispose();
    _locationController.dispose();
    widget.appOpenAds?.dispose();
    NavigationAdService.ads?.dispose();
    NavigationAdService.ads = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FishingLocationScope(
    controller: _locationController,
    child: FishingConditionsScope(
      controller: _conditionsController,
      child: MaterialApp(
        title: 'TidePath Fishing - Spot Finder',
        debugShowCheckedModeBanner: false,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(supportsShowingSystemContextMenu: false),
          child: child!,
        ),
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: _themeMode,
        home: !_splashComplete
            ? SplashScreen(ready: _startup, onComplete: _finishSplash)
            : AnimatedBuilder(
                animation: UserProfileService.instance,
                builder: (context, _) =>
                    (!_showOnboarding ||
                        UserProfileService.instance.onboardingComplete)
                    ? AppShell(
                        darkMode: _themeMode == ThemeMode.dark,
                        onThemeChanged: (value) => setState(
                          () => _themeMode = value
                              ? ThemeMode.dark
                              : ThemeMode.light,
                        ),
                      )
                    : const OnboardingScreen(firstRun: true),
              ),
      ),
    ),
  );
}
