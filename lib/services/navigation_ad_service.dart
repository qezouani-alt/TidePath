import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'app_open_ad_service.dart';
import 'admob_config.dart';

/// Shared gate for user-initiated page navigation. Late loads never interrupt a page.
abstract final class NavigationAdService {
  static AppOpenAdService? ads;
  static bool _navigating = false;

  static Future<void> navigate(VoidCallback openPage) async {
    if (_navigating) return;
    if (ads == null) {
      openPage();
      return;
    }
    _navigating = true;
    try {
      await ads?.showIfReady();
      openPage();
    } finally {
      _navigating = false;
      unawaited(ads?.preload());
    }
  }
}

class GoogleInterstitialAdSource {
  final _initialization = GoogleAppOpenAdSource();
  Future<OpenAd?> load() async {
    const unit = AdMobConfig.interstitialUnitId;
    if (!await _initialization.prepare(unit)) return null;
    final result = Completer<OpenAd?>();
    await InterstitialAd.load(
      adUnitId: unit,
      request: const AdRequest(nonPersonalizedAds: true),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) => result.complete(_Interstitial(ad)),
        onAdFailedToLoad: (_) => result.complete(null),
      ),
    );
    return result.future;
  }
}

class _Interstitial implements OpenAd {
  _Interstitial(this.ad);
  final InterstitialAd ad;
  @override
  Future<void> show() async {
    final dismissed = Completer<void>();
    void finish() {
      if (!dismissed.isCompleted) dismissed.complete();
    }

    ad.fullScreenContentCallback = FullScreenContentCallback<InterstitialAd>(
      onAdDismissedFullScreenContent: (_) => finish(),
      onAdFailedToShowFullScreenContent: (_, _) => finish(),
    );
    await ad.show();
    await dismissed.future;
  }

  @override
  void dispose() {
    unawaited(ad.dispose());
  }
}
