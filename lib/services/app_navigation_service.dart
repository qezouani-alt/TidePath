import 'dart:async';

import 'navigation_ad_service.dart';

import 'package:flutter/foundation.dart';

/// Shared selected tab so nested pages can return to the requested app section.
abstract final class AppNavigationService {
  static final ValueNotifier<int> selectedTab = ValueNotifier<int>(0);

  static const int learnTab = 3;

  static void selectTab(int index) {
    if (selectedTab.value == index) return;
    unawaited(NavigationAdService.navigate(() => selectedTab.value = index));
  }

  static void goToLearn() => selectTab(learnTab);
}
