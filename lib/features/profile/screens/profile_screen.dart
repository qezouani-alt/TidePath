import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../services/notification_permission_service.dart';

import '../../../core/theme/app_theme.dart';
import '../../../services/user_profile_service.dart';
import '../../../widgets/premium_widgets.dart';
import 'photo_credits_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({
    super.key,
    required this.darkMode,
    required this.onThemeChanged,
  });
  final bool darkMode;
  final ValueChanged<bool> onThemeChanged;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const _storeId = String.fromEnvironment(
    'APP_STORE_ID',
    defaultValue: '6819030430',
  );
  static const _shareUrl = String.fromEnvironment(
    'APP_SHARE_URL',
    defaultValue: 'https://apps.apple.com/app/id6819030430',
  );
  bool _busy = false;

  void _message(String text) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
    }
  }

  Future<void> _share(BuildContext buttonContext) async {
    try {
      final box = buttonContext.findRenderObject() as RenderBox;
      await SharePlus.instance.share(
        ShareParams(
          title: 'TidePath Fishing Spot Finder',
          subject: 'Discover TidePath',
          text:
              'Find nearby fishing spots, check sea conditions, and learn every catch with TidePath Fishing Spot Finder.${_shareUrl.isEmpty ? '' : '\n$_shareUrl'}',
          sharePositionOrigin: box.localToGlobal(Offset.zero) & box.size,
        ),
      );
    } catch (_) {
      _message('Sharing is unavailable right now. Please try again.');
    }
  }

  Future<void> _rate() async {
    try {
      final review = InAppReview.instance;
      if (!kIsWeb &&
          [
            TargetPlatform.android,
            TargetPlatform.iOS,
            TargetPlatform.macOS,
          ].contains(defaultTargetPlatform)) {
        await review.openStoreListing(appStoreId: _storeId);
      } else {
        final opened = await launchUrl(
          Uri.parse(
            'https://apps.apple.com/app/id$_storeId?action=write-review',
          ),
          mode: LaunchMode.externalApplication,
        );
        if (!opened) {
          _message('Could not open the app review page. Please try again.');
        }
      }
    } catch (_) {
      _message(
        'The app store is unavailable right now. Please try again later.',
      );
    }
  }

  Future<void> _notifications(bool enabled) async {
    setState(() => _busy = true);
    try {
      final allowed = await NotificationPermissionService.shared.setEnabled(
        enabled,
      );
      if (!allowed && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Allow notifications in your device settings to turn them on.',
            ),
            action: SnackBarAction(
              label: 'Settings',
              onPressed: openAppSettings,
            ),
          ),
        );
      }
    } catch (_) {
      _message(
        'Could not save your notification preference. Please try again.',
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _information(String title, List<Widget> content) {
    pushPage(
      context,
      Scaffold(
        appBar: AppBar(title: Text(title)),
        body: ListView(padding: const EdgeInsets.all(24), children: content),
      ),
    );
  }

  Future<void> _adPrivacy() async {
    try {
      final status = await ConsentInformation.instance
          .getPrivacyOptionsRequirementStatus();
      if (status != PrivacyOptionsRequirementStatus.required) {
        _message(
          'No advertising privacy choices are required for this session.',
        );
        return;
      }
      await ConsentForm.showPrivacyOptionsForm((error) {
        if (error != null) {
          _message('Advertising privacy choices are unavailable right now.');
        }
      });
    } catch (_) {
      _message('Advertising privacy choices are unavailable on this device.');
    }
  }

  Future<void> _openPolicy() async {
    final url = Uri.parse(
      'https://idepathfishingspotfinder.blogspot.com/2026/10/blog-post.html?m=0',
    );
    try {
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        _message(
          'Could not open the privacy and legal page. Please try again.',
        );
      }
    } catch (_) {
      _message('Could not open the privacy and legal page. Please try again.');
    }
  }

  void _credits() => _information('About and credits', [
    const Text(
      'Using TidePath',
      style: TextStyle(fontSize: 21, fontWeight: FontWeight.w700),
    ),
    const SizedBox(height: 14),
    const Text(
      'Forecasts and fishing scores are indicative. They do not guarantee catches, safe conditions, or permission to fish. Check local weather, access restrictions, fishing regulations, and licensing requirements before heading out.',
      style: TextStyle(height: 1.6),
    ),
    const SizedBox(height: 24),
    const Text(
      'Maps © OpenStreetMap contributors. Weather and marine forecasts are provided by Open-Meteo. Nearby place search may use Geoapify.',
      style: TextStyle(height: 1.6),
    ),
    const SizedBox(height: 20),
    ListTile(
      contentPadding: EdgeInsets.zero,
      title: const Text('Manage advertising consent'),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: _adPrivacy,
    ),
    ListTile(
      contentPadding: EdgeInsets.zero,
      title: const Text('Fish photo credits'),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: () => pushPage(context, const PhotoCreditsScreen()),
    ),
    ListTile(
      contentPadding: EdgeInsets.zero,
      title: const Text('Open-source licenses'),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: () => showLicensePage(
        context: context,
        applicationName: 'TidePath Fishing Spot Finder',
      ),
    ),
  ]);

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 125),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: (constraints.maxHeight - 157).clamp(0, double.infinity),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 14),
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(29),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.ocean.withValues(alpha: .14),
                        blurRadius: 26,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(29),
                    child: Image.asset(
                      'assets/icon/appicon.png',
                      width: 112,
                      height: 112,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'TidePath Fishing',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 5),
                const Text(
                  'Spot Finder',
                  style: TextStyle(
                    color: AppColors.blue,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    letterSpacing: .5,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Find your spot. Follow the tide.\nMake every fishing trip count.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.muted,
                    fontSize: 14,
                    height: 1.65,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 36),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedBuilder(
                  animation: UserProfileService.instance,
                  builder: (context, _) => AppCard(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    child: SwitchListTile.adaptive(
                      minTileHeight: 76,
                      secondary: const Icon(
                        Icons.notifications_none_rounded,
                        color: AppColors.blue,
                      ),
                      title: const Text(
                        'Notifications',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                      subtitle: Text(
                        UserProfileService.instance.notificationsEnabled
                            ? 'On'
                            : 'Off',
                      ),
                      value: UserProfileService.instance.notificationsEnabled,
                      onChanged: _busy ? null : _notifications,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Builder(
                  builder: (buttonContext) => _ActionButton(
                    icon: Icons.ios_share_rounded,
                    label: 'Share app',
                    onTap: () => _share(buttonContext),
                  ),
                ),
                const SizedBox(height: 12),
                _ActionButton(
                  icon: Icons.star_outline_rounded,
                  label: 'Rate app',
                  onTap: _rate,
                ),
                const SizedBox(height: 12),
                _ActionButton(
                  icon: Icons.shield_outlined,
                  label: 'Privacy',
                  onTap: _openPolicy,
                ),
                const SizedBox(height: 12),
                _ActionButton(
                  icon: Icons.info_outline_rounded,
                  label: 'Credits',
                  onTap: _credits,
                ),
                const SizedBox(height: 12),
                const Text(
                  'TidePath · Version 1.0',
                  style: TextStyle(color: AppColors.muted, fontSize: 11),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => AppCard(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    onTap: onTap,
    child: ListTile(
      minTileHeight: 76,
      leading: Icon(icon, size: 24, color: AppColors.blue),
      title: Text(
        label,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
      ),
      trailing: const Icon(
        Icons.chevron_right_rounded,
        color: AppColors.muted,
        size: 21,
      ),
    ),
  );
}
