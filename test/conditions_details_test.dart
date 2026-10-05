import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fishing/features/conditions/conditions_scope.dart';
import 'package:fishing/features/conditions/screens/fishing_conditions_details_screen.dart';
import 'package:fishing/features/conditions/widgets/circular_fishing_dashboard.dart';
import 'package:fishing/features/conditions/widgets/summary_forecast_navigation.dart';
import 'package:fishing/features/conditions/widgets/sun_moon_details_card.dart';
import 'package:fishing/features/conditions/widgets/tide_details_card.dart';
import 'package:fishing/features/home/widgets/fishing_forecast_selectors.dart';
import 'package:fishing/features/location/location_scope.dart';
import 'package:fishing/models/fishing_conditions.dart';
import 'package:fishing/models/fishing_location.dart';
import 'package:fishing/services/fishing_conditions_repository.dart';
import 'package:fishing/services/coast_orientation_service.dart';
import 'package:latlong2/latlong.dart';

import 'support/live_conditions_fixture.dart';

void main() {
  final originalCoastService = CoastOrientationService.shared;
  setUpAll(() {
    CoastOrientationService.shared = CoastOrientationService(
      source: _EmptyCoastlineSource(),
    );
  });
  tearDownAll(() => CoastOrientationService.shared = originalCoastService);
  testWidgets('details tabs share selected day and hour', (tester) async {
    final location = FishingLocationController();
    final conditions = FishingConditionsController(
      location: location,
      repository: _DemoRepository(),
    );
    addTearDown(conditions.dispose);
    addTearDown(location.dispose);
    await tester.pumpWidget(
      FishingLocationScope(
        controller: location,
        child: FishingConditionsScope(
          controller: conditions,
          child: const MaterialApp(home: FishingConditionsDetailsScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(CircularFishingDashboard), findsOneWidget);
    expect(find.byType(SummaryTimeSlider), findsOneWidget);

    await tester.ensureVisible(find.byType(SummaryWeekSelector));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('summary-day-1')));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<SummaryWeekSelector>(find.byType(SummaryWeekSelector))
          .selectedIndex,
      1,
    );
    final selectedHour = tester
        .widget<HourlyFishingSlider>(find.byType(HourlyFishingSlider))
        .selectedIndex;

    await tester.tap(find.byKey(const Key('conditions-tab-1')));
    await tester.pumpAndSettle();
    expect(find.byType(TideDetailsCard), findsOneWidget);
    expect(find.text('24-hour tide curve'), findsOneWidget);
    await tester.tap(find.byKey(const Key('details-next-hour')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('conditions-tab-2')));
    await tester.pumpAndSettle();
    expect(find.byType(SunMoonDetailsCard), findsOneWidget);
    expect(find.text('Golden hour'), findsOneWidget);

    await tester.tap(find.byKey(const Key('conditions-tab-0')));
    await tester.pumpAndSettle();
    final totalHours = 24 + selectedHour + 1;
    expect(
      tester
          .widget<SummaryWeekSelector>(find.byType(SummaryWeekSelector))
          .selectedIndex,
      totalHours ~/ 24,
    );
    expect(
      tester
          .widget<HourlyFishingSlider>(find.byType(HourlyFishingSlider))
          .selectedIndex,
      totalHours % 24,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('details screen fits small phone and iPad', (tester) async {
    final location = FishingLocationController();
    final conditions = FishingConditionsController(
      location: location,
      repository: _DemoRepository(),
    );
    addTearDown(conditions.dispose);
    addTearDown(location.dispose);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    for (final width in [320.0, 834.0]) {
      tester.view.physicalSize = Size(width, 900);
      tester.view.devicePixelRatio = 1;
      await tester.pumpWidget(
        FishingLocationScope(
          controller: location,
          child: FishingConditionsScope(
            controller: conditions,
            child: MaterialApp(
              key: UniqueKey(),
              home: const FishingConditionsDetailsScreen(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: '$width px summary');
      await tester.tap(find.byKey(const Key('conditions-tab-1')));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: '$width px tides');
      await tester.tap(find.byKey(const Key('conditions-tab-2')));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: '$width px sun');
    }
  });

  testWidgets('summary time ruler updates the circular readings', (
    tester,
  ) async {
    final location = FishingLocationController();
    final conditions = FishingConditionsController(
      location: location,
      repository: _DemoRepository(),
    );
    addTearDown(conditions.dispose);
    addTearDown(location.dispose);
    await tester.pumpWidget(
      FishingLocationScope(
        controller: location,
        child: FishingConditionsScope(
          controller: conditions,
          child: const MaterialApp(home: FishingConditionsDetailsScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();
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
      tester
          .widget<CircularFishingDashboard>(
            find.byType(CircularFishingDashboard),
          )
          .hour
          .localTime
          .hour,
      23,
    );
    expect(tester.takeException(), isNull);
  });
}

class _EmptyCoastlineSource implements CoastlineSource {
  @override
  Future<List<List<LatLng>>> fetch(FishingLocation location) async => [];
}

class _DemoRepository implements FishingConditionsRepository {
  @override
  Future<FishingConditions> load(
    FishingLocation location, {
    bool forceRefresh = false,
  }) async => liveConditionsFixture(location);

  @override
  void dispose() {}
}
