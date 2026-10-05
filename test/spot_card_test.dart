import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fishing/core/theme/app_theme.dart';
import 'package:fishing/models/demo_data.dart';
import 'package:fishing/widgets/premium_widgets.dart';

void main() {
  testWidgets('nearby spot card shows details without loading a photo', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: Center(
            child: SizedBox(
              height: 176,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  FishingSpotCard(spot: DemoData.spots.first, compact: true),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.byType(SeaPhoto), findsNothing);
    expect(find.text('Taghazout Coast'), findsOneWidget);
    expect(find.text('12 km away'), findsOneWidget);
    expect(find.text('SAMPLE SPOT'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
