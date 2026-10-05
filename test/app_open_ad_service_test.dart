import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:fishing/services/app_open_ad_service.dart';

void main() {
  test('no loaded ad opens immediately and never shows a late ad', () async {
    final pending = Completer<OpenAd?>();
    final ad = _Ad();
    final service = AppOpenAdService(loadAd: () => pending.future);
    final loading = service.preload();
    await service.showIfReady();
    pending.complete(ad);
    await loading;
    expect(ad.shows, 0);
    service.dispose();
    expect(ad.disposals, 1);
  });

  test('cached ad displays once and waits for dismissal', () async {
    final ad = _Ad();
    final service = AppOpenAdService(loadAd: () async => ad);
    await service.preload();
    var completed = false;
    final showing = service.showIfReady().then((_) => completed = true);
    await service.showIfReady();
    expect(ad.shows, 1);
    expect(completed, isFalse);
    ad.dismiss.complete();
    await showing;
    expect(completed, isTrue);
    expect(ad.disposals, 1);
    service.dispose();
  });

  test('ads older than four hours are disposed without showing', () async {
    var now = DateTime.utc(2026, 10, 4);
    final ad = _Ad();
    var loads = 0;
    final service = AppOpenAdService(
      now: () => now,
      loadAd: () async => loads++ == 0 ? ad : null,
    );
    await service.preload();
    now = now.add(const Duration(hours: 4));
    await service.showIfReady();
    expect(ad.shows, 0);
    expect(ad.disposals, 1);
    service.dispose();
  });

  test('loading errors never block startup', () async {
    final service = AppOpenAdService(
      loadAd: () async => throw StateError('offline'),
    );
    await service.preload();
    await service.showIfReady();
    service.dispose();
  });

  test('disposing during load releases a late ad', () async {
    final pending = Completer<OpenAd?>();
    final service = AppOpenAdService(loadAd: () => pending.future);
    final loading = service.preload();
    service.dispose();
    final ad = _Ad();
    pending.complete(ad);
    await loading;
    expect(ad.disposals, 1);
    expect(ad.shows, 0);
  });
}

class _Ad implements OpenAd {
  int shows = 0, disposals = 0;
  final dismiss = Completer<void>();
  @override
  Future<void> show() {
    shows++;
    return dismiss.future;
  }

  @override
  void dispose() {
    disposals++;
  }
}
