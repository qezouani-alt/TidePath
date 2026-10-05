import 'package:flutter/material.dart';

import '../services/app_navigation_service.dart';
import '../widgets/premium_widgets.dart';
import 'home/screens/home_screen.dart';
import 'explore/screens/explore_screen.dart';
import 'fish/screens/fish_guide_screen.dart';
import 'learn/screens/learn_screen.dart';
import 'profile/screens/profile_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({
    super.key,
    required this.darkMode,
    required this.onThemeChanged,
  });
  final bool darkMode;
  final ValueChanged<bool> onThemeChanged;
  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int index = AppNavigationService.selectedTab.value;

  @override
  void initState() {
    super.initState();
    AppNavigationService.selectedTab.addListener(_onSelectedTabChanged);
  }

  @override
  void dispose() {
    AppNavigationService.selectedTab.removeListener(_onSelectedTabChanged);
    super.dispose();
  }

  void _onSelectedTabChanged() {
    if (mounted) setState(() => index = AppNavigationService.selectedTab.value);
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      HomeScreen(onTabSelected: AppNavigationService.selectTab),
      const ExploreScreen(),
      const FishGuideScreen(),
      const LearnScreen(),
      ProfileScreen(
        darkMode: widget.darkMode,
        onThemeChanged: widget.onThemeChanged,
      ),
    ];
    return Scaffold(
      extendBody: true,
      body: SafeArea(
        bottom: false,
        child: IndexedStack(index: index, children: screens),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: FishingBottomNavigationBar(
          index: index,
          onTap: AppNavigationService.selectTab,
        ),
      ),
    );
  }
}
