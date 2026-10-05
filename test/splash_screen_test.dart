import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fishing/features/splash/screens/splash_screen.dart';

void main() {
  testWidgets('waits at 90%, then finishes the fish jumps and completes once', (
    tester,
  ) async {
    final ready = Completer<void>();
    var completions = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: SplashScreen(
          ready: ready.future,
          onComplete: () => completions++,
        ),
      ),
    );
    expect(find.text('TidePath Fishing\nSpot Finder'), findsOneWidget);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 2200));
    expect(find.text('90%'), findsOneWidget);
    final painter = tester
        .widgetList<CustomPaint>(find.byType(CustomPaint))
        .map((widget) => widget.painter)
        .whereType<WaveJumpPainter>()
        .single;
    expect(WaveJumpPainter.fishCount, 5);
    expect(painter.progress, .9);
    expect(completions, 0);
    await tester.pump(const Duration(seconds: 2));
    expect(find.text('90%'), findsOneWidget);
    ready.complete();
    await tester.pump();
    await tester.pumpAndSettle();
    expect(find.text('100%'), findsOneWidget);
    expect(completions, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('disposing during the jumps safely cancels completion', (
    tester,
  ) async {
    var completed = false;
    await tester.pumpWidget(
      MaterialApp(
        home: SplashScreen(
          ready: Future.value(),
          onComplete: () => completed = true,
        ),
      ),
    );
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 4));
    expect(completed, isFalse);
    expect(tester.takeException(), isNull);
  });
}
