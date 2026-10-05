import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'tracking_permission_service.dart';
import 'admob_config.dart';

abstract class OpenAd {
  Future<void> show();
  void dispose();
}

/// Owns one cached ad and never waits for a network load before opening the app.
class AppOpenAdService {
  AppOpenAdService({
    required this.loadAd,
    DateTime Function()? now,
    this.maxCacheDuration = const Duration(hours: 4),
  }) : _now = now ?? DateTime.now;
  final Future<OpenAd?> Function() loadAd;
  final DateTime Function() _now;
  final Duration maxCacheDuration;
  OpenAd? _ad;
  DateTime? _loadedAt;
  bool _loading = false, _showing = false, _disposed = false;

  Future<void> preload() async {
    if (_disposed || _loading || _ad != null) return;
    _loading = true;
    try {
      final ad = await loadAd();
      if (_disposed) {
        ad?.dispose();
      } else {
        _ad = ad;
        _loadedAt = _now();
      }
    } catch (_) {
      // Offline or unsupported devices continue directly into the app.
    } finally {
      _loading = false;
    }
  }

  Future<void> showIfReady() async {
    if (_disposed || _showing) return;
    final ad = _ad;
    if (ad == null) return;
    _ad = null;
    if (_loadedAt == null ||
        _now().difference(_loadedAt!) >= maxCacheDuration) {
      ad.dispose();
      unawaited(preload());
      return;
    }
    _showing = true;
    try {
      await ad.show();
    } catch (_) {
      // A display failure must not prevent startup.
    } finally {
      ad.dispose();
      _showing = false;
    }
  }

  void dispose() {
    _disposed = true;
    _ad?.dispose();
    _ad = null;
  }
}

class GoogleAppOpenAdSource {
  Future<bool>? _ready;

  Future<bool> prepare(String unit) => _ready ??= _initialize(unit);

  Future<bool> _initialize([String? overrideUnit]) async {
    final unit = overrideUnit ?? AdMobConfig.appOpenUnitId;
    if (kIsWeb ||
        defaultTargetPlatform != TargetPlatform.iOS ||
        !AdMobConfig.isConfigured(unit)) {
      return false;
    }
    // Obtain consent before requesting ads with real units.
    {
      final updated = Completer<void>();
      ConsentInformation.instance.requestConsentInfoUpdate(
        ConsentRequestParameters(),
        () => updated.complete(),
        (_) => updated.complete(),
      );
      await updated.future;
      final formDone = Completer<void>();
      ConsentForm.loadAndShowConsentFormIfRequired((_) => formDone.complete());
      await formDone.future;
      if (!await ConsentInformation.instance.canRequestAds()) return false;
    }
    await TrackingPermissionService.shared.requestOnLaunch();
    await MobileAds.instance.initialize();
    return true;
  }

  Future<OpenAd?> load() async {
    if (!await (_ready ??= _initialize())) return null;
    final result = Completer<OpenAd?>();
    await AppOpenAd.load(
      adUnitId: AdMobConfig.appOpenUnitId,
      request: const AdRequest(nonPersonalizedAds: true),
      adLoadCallback: AppOpenAdLoadCallback(
        onAdLoaded: (ad) => result.complete(_GoogleOpenAd(ad)),
        onAdFailedToLoad: (_) => result.complete(null),
      ),
    );
    return result.future;
  }
}

class _GoogleOpenAd implements OpenAd {
  _GoogleOpenAd(this.ad);
  final AppOpenAd ad;
  @override
  Future<void> show() async {
    final done = Completer<void>();
    ad.fullScreenContentCallback = FullScreenContentCallback<AppOpenAd>(
      onAdDismissedFullScreenContent: (_) {
        if (!done.isCompleted) done.complete();
      },
      onAdFailedToShowFullScreenContent: (_, _) {
        if (!done.isCompleted) done.complete();
      },
    );
    await ad.show();
    await done.future;
  }

  @override
  void dispose() {
    unawaited(ad.dispose());
  }
}
