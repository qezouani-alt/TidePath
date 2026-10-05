import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fishing/widgets/fish_activity_indicator.dart';

void main() {
  test('fish activity follows every score threshold', () {
    const cases = <int, FishActivityLevel>{
      0: FishActivityLevel.veryPoor,
      29: FishActivityLevel.veryPoor,
      30: FishActivityLevel.poor,
      49: FishActivityLevel.poor,
      50: FishActivityLevel.average,
      69: FishActivityLevel.average,
      70: FishActivityLevel.good,
      84: FishActivityLevel.good,
      85: FishActivityLevel.excellent,
      94: FishActivityLevel.excellent,
      95: FishActivityLevel.perfect,
      100: FishActivityLevel.perfect,
    };
    for (final entry in cases.entries) {
      expect(
        FishActivityLevel.fromScore(entry.key),
        entry.value,
        reason: 'Score ${entry.key}',
      );
    }
  });

  testWidgets('fish row updates with score and highlights best time', (
    tester,
  ) async {
    Widget screen(int score, {bool isBestTime = false}) => MaterialApp(
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: 320,
            child: FishActivityIndicator(
              fishingScore: score,
              isBestTime: isBestTime,
            ),
          ),
        ),
      ),
    );

    await tester.pumpWidget(screen(70));
    await tester.pumpAndSettle();
    expect(find.text('Good'), findsOneWidget);
    expect(find.byIcon(Icons.set_meal_rounded), findsNWidgets(4));

    final active = tester.widget<Icon>(
      find.descendant(
        of: find.byKey(const Key('fish-activity-icon-2')),
        matching: find.byType(Icon),
      ),
    );
    final inactive = tester.widget<Icon>(
      find.descendant(
        of: find.byKey(const Key('fish-activity-icon-3')),
        matching: find.byType(Icon),
      ),
    );
    expect(active.color, isNot(inactive.color));

    await tester.pumpWidget(screen(95, isBestTime: true));
    await tester.pumpAndSettle();
    expect(find.text('Perfect'), findsOneWidget);
    expect(find.text('BEST TIME NOW'), findsOneWidget);
    expect(
      tester.getSemantics(find.byType(FishActivityIndicator)).label,
      contains('4 of 4 fish active'),
    );
  });
}
