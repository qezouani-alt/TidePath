import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:fishing/services/app_open_ad_service.dart';
import 'package:fishing/services/navigation_ad_service.dart';

void main() {
  tearDown(() {
    NavigationAdService.ads?.dispose();
    NavigationAdService.ads = null;
  });
  test(
    'waits for dismissal and ignores repeated taps while displaying',
    () async {
      final ad = _Ad();
      var loads = 0;
      final service = AppOpenAdService(
        loadAd: () async => loads++ == 0 ? ad : null,
      );
      NavigationAdService.ads = service;
      await service.preload();
      var pages = 0;
      final opening = NavigationAdService.navigate(() => pages++);
      await NavigationAdService.navigate(() => pages++);
      expect(ad.shows, 1);
      expect(pages, 0);
      ad.dismiss.complete();
      await opening;
      expect(pages, 1);
      expect(ad.disposed, isTrue);
      expect(loads, 2);
    },
  );
  test('page opens even if no ad is ready', () async {
    NavigationAdService.ads = AppOpenAdService(loadAd: () async => null);
    var opened = false;
    await NavigationAdService.navigate(() => opened = true);
    expect(opened, isTrue);
  });
  test('page opens after a display error', () async {
    final ad = _Ad()..fails = true;
    final service = AppOpenAdService(loadAd: () async => ad);
    NavigationAdService.ads = service;
    await service.preload();
    var opened = false;
    await NavigationAdService.navigate(() => opened = true);
    expect(opened, isTrue);
    expect(ad.disposed, isTrue);
  });
}

class _Ad implements OpenAd {
  int shows = 0;
  bool disposed = false, fails = false;
  final dismiss = Completer<void>();
  @override
  Future<void> show() {
    shows++;
    if (fails) return Future.error(StateError('show failed'));
    return dismiss.future;
  }

  @override
  void dispose() {
    disposed = true;
  }
}
