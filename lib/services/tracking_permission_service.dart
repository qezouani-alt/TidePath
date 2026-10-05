import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:permission_handler/permission_handler.dart';

/// Requests ATT on iOS before the advertising SDK is initialized.
class TrackingPermissionService {
  TrackingPermissionService({
    Future<PermissionStatus> Function()? status,
    Future<PermissionStatus> Function()? request,
    Future<bool> Function()? waitForActive,
    bool? supported,
  }) : _status = status ?? (() => Permission.appTrackingTransparency.status),
       _request =
           request ?? (() => Permission.appTrackingTransparency.request()),
       _waitForActive = waitForActive ?? _active,
       supported =
           supported ??
           (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS);

  static final shared = TrackingPermissionService();
  final bool supported;
  final Future<PermissionStatus> Function() _status, _request;
  final Future<bool> Function() _waitForActive;
  Future<void>? _pending;
  bool authorized = false;

  static Future<bool> _active() async {
    // Allow the notification alert to close and iOS to become active again.
    await Future<void>.delayed(const Duration(milliseconds: 350));
    for (var attempt = 0; attempt < 40; attempt++) {
      if (WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed) {
        return true;
      }
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }
    return false;
  }

  Future<void> requestOnLaunch() {
    if (!supported) return Future.value();
    return _pending ??= _ask().whenComplete(() => _pending = null);
  }

  Future<void> _ask() async {
    try {
      var status = await _status();
      // The plugin maps ATT 'not determined' to denied, and 'denied' to
      // permanentlyDenied. Only the undetermined state may display a prompt.
      if (status.isDenied && await _waitForActive()) {
        status = await _request();
      }
      authorized = status.isGranted;
    } catch (_) {
      authorized = false;
      // Permission failures never prevent access to the app.
    }
  }
}
