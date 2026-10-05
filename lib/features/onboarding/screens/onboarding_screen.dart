import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../widgets/premium_widgets.dart';
import '../../../services/user_profile_service.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, this.firstRun = false});
  final bool firstRun;
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final controller = PageController();
  final nameController = TextEditingController();
  int page = 0;
  bool saving = false;
  bool showNameError = false;
  static const pages = [
    (
      'Know When to Fish',
      'Check wind, waves, tides and fishing conditions before heading out.',
      Icons.waves_rounded,
    ),
    (
      'Discover Fishing Spots',
      'Find beautiful beaches and productive fishing locations near you.',
      Icons.explore_rounded,
    ),
    (
      'Learn Every Catch',
      'Explore fish species, knots, baits, gear and fishing techniques.',
      Icons.menu_book_rounded,
    ),
    (
      'Track Your Journey',
      'Save your catches, celebrate your progress and grow your skills.',
      Icons.phishing_rounded,
    ),
  ];
  @override
  void dispose() {
    controller.dispose();
    nameController.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    if (!widget.firstRun) {
      Navigator.pop(context);
      return;
    }
    if (page < pages.length) {
      controller.animateToPage(
        pages.length,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
      return;
    }
    if (nameController.text.trim().isEmpty) {
      setState(() => showNameError = true);
      return;
    }
    if (saving) return;
    setState(() => saving = true);
    await UserProfileService.instance.completeOnboarding(nameController.text);
    if (mounted) setState(() => saving = false);
  }

  Widget _namePage(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.fromLTRB(22, 26, 22, 18),
    child: Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 220,
          child: Center(
            child: Container(
              width: 208,
              height: 208,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.aqua.withValues(alpha: .18),
                    AppColors.aqua.withValues(alpha: 0),
                  ],
                ),
              ),
              child: Center(
                child: Container(
                  width: 164,
                  height: 164,
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(39),
                    border: Border.all(
                      color: AppColors.aqua.withValues(alpha: .4),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.ocean.withValues(alpha: .2),
                        blurRadius: 28,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(33),
                    child: Image.asset(
                      'assets/icon/appicon.png',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 28),
        Text(
          'What should we call you?',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineLarge,
        ),
        const SizedBox(height: 10),
        const Text(
          'Your name will appear on your profile and Home screen.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.muted, fontSize: 14, height: 1.5),
        ),
        const SizedBox(height: 24),
        TextField(
          controller: nameController,
          maxLength: 32,
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.done,
          onChanged: (_) {
            if (showNameError) setState(() => showNameError = false);
          },
          onSubmitted: (_) => _finish(),
          decoration: InputDecoration(
            labelText: 'Your name',
            hintText: 'Enter your name',
            prefixIcon: const Icon(Icons.person_outline_rounded),
            errorText: showNameError ? 'Please enter your name' : null,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(18)),
          ),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(23, 12, 23, 0),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(7),
                  child: Image.asset(
                    'assets/icon/appicon.png',
                    width: 28,
                    height: 28,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 7),
                const Text(
                  'TidePath',
                  style: TextStyle(
                    color: AppColors.ocean,
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: widget.firstRun
                      ? (page == pages.length
                            ? null
                            : () => controller.animateToPage(
                                pages.length,
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeOutCubic,
                              ))
                      : () => Navigator.pop(context),
                  child: Text(widget.firstRun ? 'Skip tour' : 'Skip'),
                ),
              ],
            ),
          ),
          Expanded(
            child: PageView.builder(
              controller: controller,
              itemCount: pages.length + (widget.firstRun ? 1 : 0),
              onPageChanged: (value) => setState(() => page = value),
              itemBuilder: (context, i) => i == pages.length
                  ? _namePage(context)
                  : Padding(
                      padding: const EdgeInsets.fromLTRB(22, 30, 22, 0),
                      child: Column(
                        children: [
                          Expanded(
                            child: Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(30),
                                gradient: oceanGradient,
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(30),
                                child: Stack(
                                  children: [
                                    if (i == 0 || i == 1)
                                      const Positioned.fill(child: SeaPhoto()),
                                    if (i == 0 || i == 1)
                                      Positioned.fill(
                                        child: Container(
                                          color: AppColors.ocean.withValues(
                                            alpha: .2,
                                          ),
                                        ),
                                      ),
                                    Center(
                                      child: Container(
                                        width: 148,
                                        height: 148,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Colors.white.withValues(
                                            alpha: .14,
                                          ),
                                        ),
                                        child: Icon(
                                          pages[i].$3,
                                          color: Colors.white,
                                          size: 76,
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      bottom: 24,
                                      left: 24,
                                      child: Text(
                                        '0${i + 1} / 04',
                                        style: const TextStyle(
                                          color: Colors.white70,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: 1.2,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 34),
                          Text(
                            pages[i].$1,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.headlineLarge,
                          ),
                          const SizedBox(height: 11),
                          Text(
                            pages[i].$2,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: AppColors.muted,
                              fontSize: 14,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              pages.length + (widget.firstRun ? 1 : 0),
              (i) => AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                width: page == i ? 23 : 7,
                height: 7,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  color: page == i
                      ? AppColors.blue
                      : AppColors.blue.withValues(alpha: .22),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 22, 22, 24),
            child: GradientButton(
              saving
                  ? 'Saving...'
                  : page == pages.length ||
                        (!widget.firstRun && page == pages.length - 1)
                  ? 'Start Fishing'
                  : 'Continue',
              onPressed: () {
                if (page == pages.length ||
                    (!widget.firstRun && page == pages.length - 1)) {
                  _finish();
                } else {
                  controller.nextPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOutCubic,
                  );
                }
              },
            ),
          ),
        ],
      ),
    ),
  );
}
