import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fishing/features/conditions/widgets/circular_fishing_dashboard.dart';
import 'package:fishing/features/conditions/widgets/summary_forecast_navigation.dart';
import 'package:fishing/features/conditions/widgets/tide_timeline_bar.dart';
import 'package:fishing/features/conditions/widgets/wind_coast_compass.dart';
import 'package:fishing/features/home/widgets/fishing_conditions_hero_card.dart';
import 'package:fishing/models/fishing_location.dart';
import 'package:fishing/services/demo_condition_data.dart';
import 'package:fishing/services/fishing_forecast_builder.dart';
import 'package:latlong2/latlong.dart';

const _location = FishingLocation(
  label: 'Agadir, Morocco',
  point: LatLng(30.4278, -9.5981),
);

void main() {
  testWidgets('Home circle shows current conditions and opens details', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final conditions = DemoConditionData.forLocation(_location);
    final days = const FishingForecastBuilder().build(conditions);
    var detailsOpened = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: FishingConditionsHeroCard(
                conditions: conditions,
                onDetails: () => detailsOpened++,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final expectedHour = days.first.hours.firstWhere((hour) => hour.isCurrent);
    final circle = tester.widget<CircularFishingDashboard>(
      find.byType(CircularFishingDashboard),
    );
    expect(find.byKey(const Key('circle-tide-bar')), findsOneWidget);
    expect(find.text('BEACH LINE'), findsNothing);
    expect(find.byType(WindCoastCompass), findsOneWidget);
    expect(find.text('COAST —'), findsOneWidget);
    expect(circle.hour.timeUtc, expectedHour.timeUtc);
    expect(circle.hour.windKmh, expectedHour.windKmh);
    expect(circle.hour.waveM, expectedHour.waveM);
    await tester.ensureVisible(
      find.byKey(const Key('home-conditions-more-details')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('home-conditions-more-details')));
    expect(detailsOpened, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('marine hero fits small phone and tablet widths', (tester) async {
    for (final width in [320.0, 834.0]) {
      tester.view.physicalSize = Size(width, 900);
      tester.view.devicePixelRatio = 1;
      await tester.pumpWidget(
        MaterialApp(
          key: UniqueKey(),
          home: Scaffold(
            body: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: FishingConditionsHeroCard(
                  conditions: DemoConditionData.forLocation(_location),
                  onDetails: () {},
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: '$width px wide');
    }
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  });

  testWidgets('hour slider changes circle and tide; metric opens explanation', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: FishingConditionsHeroCard(
                conditions: DemoConditionData.forLocation(_location),
                onDetails: () {},
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    for (final metric in [
      'air',
      'feels',
      'rain',
      'cloud',
      'pressure',
      'wind',
      'time',
      'waves',
      'tide-bar',
      'tide',
      'period',
      'swell',
      'sea',
      'score',
      'activity',
    ]) {
      await tester.tap(find.byKey(Key('circle-metric-$metric')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('circle-info-popup')),
        findsOneWidget,
        reason: metric,
      );
      if (metric == 'wind') {
        expect(find.textContaining('Gusts may reach'), findsOneWidget);
      }
      await tester.tap(find.byTooltip('Close explanation'));
      await tester.pumpAndSettle();
    }

    await tester.ensureVisible(find.byKey(const Key('summary-time-slider')));
    await tester.pumpAndSettle();
    final track = tester.getRect(find.byKey(const Key('summary-time-slider')));
    await tester.tapAt(Offset(track.right - 3, track.center.dy));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<SummaryTimeSlider>(find.byType(SummaryTimeSlider))
          .selectedHour,
      23,
    );
    expect(
      tester.widget<TideTimelineBar>(find.byType(TideTimelineBar)).selectedHour,
      23,
    );
    expect(
      tester
          .widget<CircularFishingDashboard>(
            find.byType(CircularFishingDashboard),
          )
          .hour
          .localTime
          .hour,
      23,
    );
    await tester.tapAt(Offset(track.left + 3, track.center.dy));
    await tester.pumpAndSettle();
    expect(find.text('TIDE DATA UNAVAILABLE'), findsOneWidget);
    await tester.tapAt(
      Offset(track.left + track.width * 6 / 23, track.center.dy),
    );
    await tester.pumpAndSettle();
    expect(find.text('TIDE DATA UNAVAILABLE'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
