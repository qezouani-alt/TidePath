import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fishing/main.dart';
import 'package:fishing/services/app_navigation_service.dart';
import 'package:fishing/core/theme/app_theme.dart';
import 'package:fishing/models/demo_data.dart';
import 'package:fishing/features/fishing_spots/screens/spot_detail_screen.dart';
import 'package:fishing/features/fish/screens/fish_detail_screen.dart';
import 'package:fishing/features/fish/screens/fish_guide_screen.dart';
import 'package:fishing/features/fish/widgets/nearby_fish_card.dart';
import 'package:fishing/features/learn/screens/lesson_detail_screen.dart';
import 'package:fishing/features/forecast/screens/forecast_screen.dart';
import 'package:fishing/features/conditions/screens/conditions_screen.dart';
import 'package:fishing/features/conditions/screens/fishing_conditions_dashboard_screen.dart';
import 'package:fishing/features/conditions/screens/fishing_conditions_details_screen.dart';
import 'package:fishing/features/conditions/conditions_scope.dart';
import 'package:fishing/features/fish_identifier/screens/identifier_screen.dart';
import 'package:fishing/features/catches/screens/catches_screen.dart';
import 'package:fishing/features/catches/screens/add_catch_screen.dart';
import 'package:fishing/features/explore/screens/explore_screen.dart';
import 'package:fishing/features/home/screens/home_screen.dart';
import 'package:fishing/features/location/location_scope.dart';
import 'package:fishing/features/location/screens/location_picker_screen.dart';
import 'package:fishing/models/fishing_location.dart';
import 'package:fishing/models/fishing_conditions.dart';
import 'package:fishing/models/nearby_fish.dart';
import 'package:fishing/models/fish_catalog.dart';
import 'package:fishing/services/fishing_conditions_repository.dart';
import 'package:fishing/services/location_service.dart';
import 'package:fishing/services/nearby_spots_service.dart';
import 'package:fishing/services/nearby_fish_service.dart';
import 'package:fishing/services/fish_catalog_service.dart';
import 'package:fishing/services/coast_orientation_service.dart';
import 'package:fishing/services/user_profile_service.dart';
import 'package:fishing/widgets/fish_activity_indicator.dart';
import 'package:fishing/widgets/premium_widgets.dart';

import 'support/live_conditions_fixture.dart';

import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  final originalCoastService = CoastOrientationService.shared;
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await UserProfileService.instance.completeOnboarding('Alex Morgan');
    CoastOrientationService.shared = CoastOrientationService(
      source: _EmptyCoastlineSource(),
    );
  });
  tearDownAll(() => CoastOrientationService.shared = originalCoastService);
  testWidgets('nearby fish cards and header fit a narrow scaled display', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    const fish = NearbyFish(
      taxonId: 123,
      name: 'Common Two-Banded Mediterranean Seabream',
      scientificName: 'Diplodus vulgaris',
      observationCount: 12345,
      photoUrl: 'https://example.invalid/fish.jpg',
      photoCredit: 'A photographer with a long display name',
      photoLicense: 'CC BY',
    );
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(1.6)),
        child: MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: Column(
              children: [
                SectionHeader(
                  'Fish you may catch today',
                  action: 'Fish guide',
                  onAction: () {},
                  stackOnNarrow: true,
                ),
                const SizedBox(
                  width: 180,
                  height: 282,
                  child: NearbyFishCard(fish: fish, compact: true),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(
      tester.getTopLeft(find.text('Fish guide')).dy,
      greaterThan(tester.getTopLeft(find.text('Fish you may catch today')).dy),
    );
  });

  test('every fish species has a bundled photograph', () async {
    for (final fish in DemoData.fish) {
      final photo = await rootBundle.load(fish.imagePath);
      expect(photo.lengthInBytes, greaterThan(1000), reason: fish.name);
    }
    final credits = jsonDecode(
      await rootBundle.loadString('assets/images/fish/credits.json'),
    ) as List<dynamic>;
    expect(credits, hasLength(DemoData.fish.length));
  });

  testWidgets('dashboard and primary navigation open', (tester) async {
    await tester.pumpWidget(
      TidePathApp(conditionsRepository: _DemoRepository()),
    );
    await tester.pumpAndSettle();
    await tester.runAsync(() async {
      await Future<void>.delayed(Duration.zero);
    });
    await tester.pumpAndSettle();

    expect(find.textContaining('Alex 👋'), findsOneWidget);
    expect(find.textContaining('Conditions'), findsWidgets);

    await tester.tap(find.text('Explore').last);
    await tester.pumpAndSettle();
    expect(find.text('Fishing spots near Agadir'), findsOneWidget);

    await tester.tap(find.text('Fish').last);
    await tester.pumpAndSettle();
    expect(find.text('Fish Guide'), findsOneWidget);

    await tester.tap(find.text('Learn').last);
    await tester.pumpAndSettle();
    expect(find.text('Learn Fishing'), findsOneWidget);

    await tester.tap(find.text('Profile').last);
    await tester.pumpAndSettle();
    expect(find.text('TidePath Fishing'), findsOneWidget);
    expect(find.text('Share app'), findsOneWidget);
    expect(find.text('Rate app'), findsOneWidget);
  });

  testWidgets('detail screens fit a large phone viewport', (tester) async {
    final location = FishingLocationController();
    addTearDown(location.dispose);
    final conditions = FishingConditionsController(
      location: location,
      repository: _DemoRepository(),
    );
    addTearDown(conditions.dispose);
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final pages = <Widget>[
      SpotDetailScreen(spot: DemoData.spots.first),
      FishDetailScreen(fish: DemoData.fish.first),
      LessonDetailScreen(lesson: DemoData.lessons[1]),
      const ForecastScreen(),
      const ConditionsScreen(),
      const FishingConditionsDashboardScreen(),
      const FishingConditionsDetailsScreen(),
      const IdentifierScreen(),
      const CatchesScreen(),
      const AddCatchScreen(),
    ];
    for (final page in pages) {
      await tester.pumpWidget(
        FishingLocationScope(
          controller: location,
          child: FishingConditionsScope(
            controller: conditions,
            child: MaterialApp(
              key: UniqueKey(),
              theme: AppTheme.light,
              home: page,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        tester.takeException(),
        isNull,
        reason: page.runtimeType.toString(),
      );
    }
  });

  testWidgets('demo identifier and spot filters open', (tester) async {
    final location = FishingLocationController();
    addTearDown(location.dispose);
    await tester.pumpWidget(const MaterialApp(home: IdentifierScreen()));
    await tester.tap(find.text('Take Photo'));
    await tester.pumpAndSettle();
    expect(find.text('Identification Result'), findsOneWidget);
    expect(find.text('94% match'), findsOneWidget);

    await tester.pumpWidget(
      FishingLocationScope(
        controller: location,
        child: MaterialApp(
          key: UniqueKey(),
          home: const Scaffold(body: ExploreScreen()),
        ),
      ),
    );
    await tester.tap(find.byIcon(Icons.tune_rounded));
    await tester.pumpAndSettle();
    expect(find.text('Filter fishing spots'), findsOneWidget);
    expect(find.text('Fishing score'), findsOneWidget);
  });

  testWidgets('selected worldwide location appears on Home', (tester) async {
    final location = FishingLocationController();
    addTearDown(location.dispose);
    final conditions = FishingConditionsController(
      location: location,
      repository: _DemoRepository(),
    );
    addTearDown(conditions.dispose);
    final nearby = NearbySpotsService(source: _TokyoSpotsSource());
    await tester.pumpWidget(
      FishingLocationScope(
        controller: location,
        child: FishingConditionsScope(
          controller: conditions,
          child: MaterialApp(
            theme: AppTheme.light,
            home: Scaffold(
              body: HomeScreen(
                onTabSelected: (_) {},
                nearbySpotsService: nearby,
              ),
            ),
          ),
        ),
      ),
    );
    location.select(
      const FishingLocation(
        label: 'Tokyo, Japan',
        point: LatLng(35.6762, 139.6503),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Tokyo, Japan'), findsOneWidget);
    expect(find.text('Spots near Tokyo'), findsOneWidget);
    expect(find.text('Featured Morocco spots'), findsNothing);
    expect(find.text('Tokyo Fishing Pier'), findsOneWidget);
  });

  testWidgets('Home retries a failed nearby search', (tester) async {
    final location = FishingLocationController();
    location.select(
      const FishingLocation(
        label: 'Valencia, Spain',
        point: LatLng(39.4699, -0.3763),
      ),
    );
    addTearDown(location.dispose);
    final conditions = FishingConditionsController(
      location: location,
      repository: _DemoRepository(),
    );
    addTearDown(conditions.dispose);
    final nearby = NearbySpotsService(source: _RecoveringSpotsSource());
    await tester.pumpWidget(
      FishingLocationScope(
        controller: location,
        child: FishingConditionsScope(
          controller: conditions,
          child: MaterialApp(
            theme: AppTheme.light,
            home: Scaffold(
              body: HomeScreen(
                onTabSelected: (_) {},
                nearbySpotsService: nearby,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final retry = find.text('Retry nearby search');
    await tester.ensureVisible(retry);
    await tester.tap(retry);
    await tester.pumpAndSettle();
    expect(find.text('Valencia Beach'), findsOneWidget);
  });

  testWidgets('Home fish cards follow the selected location', (tester) async {
    final location = FishingLocationController();
    addTearDown(location.dispose);
    final conditions = FishingConditionsController(
      location: location,
      repository: _DemoRepository(),
    );
    addTearDown(conditions.dispose);
    final fishService = NearbyFishService(source: _RegionalFishSource());
    await tester.pumpWidget(
      FishingLocationScope(
        controller: location,
        child: FishingConditionsScope(
          controller: conditions,
          child: MaterialApp(
            theme: AppTheme.light,
            home: Scaffold(
              body: HomeScreen(
                onTabSelected: (_) {},
                nearbySpotsService: NearbySpotsService(
                  source: _TokyoSpotsSource(),
                ),
                nearbyFishService: fishService,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Moroccan White Seabream'), findsOneWidget);
    expect(find.text('7 observations nearby'), findsOneWidget);

    location.select(
      const FishingLocation(
        label: 'Tokyo, Japan',
        point: LatLng(35.6762, 139.6503),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Japanese Sea Bass'), findsOneWidget);
    expect(find.text('Moroccan White Seabream'), findsNothing);
  });

  testWidgets('Fish Guide All searches the global catalog', (tester) async {
    final location = FishingLocationController();
    addTearDown(location.dispose);
    final catalogSource = _WidgetCatalogSource();
    await tester.pumpWidget(
      FishingLocationScope(
        controller: location,
        child: MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: FishGuideScreen(
              nearbyFishService: NearbyFishService(
                source: _RegionalFishSource(),
              ),
              fishCatalogService: FishCatalogService(source: catalogSource),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Fish near Agadir'), findsOneWidget);
    expect(find.text('Moroccan White Seabream'), findsOneWidget);
    await tester.tap(find.text('All'));
    await tester.pumpAndSettle();
    expect(find.text('42 species'), findsOneWidget);
    expect(find.text('Bluegill'), findsOneWidget);
    expect(find.text('European Sea Bass'), findsNothing);
    await tester.enterText(find.byType(TextField), 'shark');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    expect(find.text('Basking Shark'), findsOneWidget);
    expect(catalogSource.calls, contains('shark/1'));
  });

  testWidgets('map picker accepts a tapped worldwide coordinate', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final location = FishingLocationController();
    addTearDown(location.dispose);
    await tester.pumpWidget(
      FishingLocationScope(
        controller: location,
        child: MaterialApp(
          home: LocationPickerScreen(
            locationService: LocationService(places: _WidgetPlaces()),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(FlutterMap), findsOneWidget);
    final map = tester.getRect(find.byType(FlutterMap));
    await tester.tapAt(Offset(map.right - 70, map.top + 70));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('Use this location'));
    await tester.pump();
    expect(location.selected.coordinates, isNot('30.4278, -9.5981'));
  });

  testWidgets('detected GPS place updates the shared location', (tester) async {
    final location = FishingLocationController();
    addTearDown(location.dispose);
    await tester.pumpWidget(
      FishingLocationScope(
        controller: location,
        child: MaterialApp(
          home: LocationPickerScreen(
            detectOnOpen: true,
            locationService: LocationService(
              position: _WidgetPosition(),
              places: _WidgetPlaces(),
            ),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));
    expect(location.selected.label, 'Essaouira, Morocco');
    expect(location.selected.coordinates, '31.5085, -9.7595');
  });

  testWidgets('Home Fishing Conditions card opens the complete dashboard', (
    tester,
  ) async {
    AppNavigationService.selectTab(0);
    await tester.pumpWidget(
      TidePathApp(conditionsRepository: _DemoRepository()),
    );
    await tester.pumpAndSettle();
    await tester.runAsync(() async {
      await Future<void>.delayed(Duration.zero);
    });
    await tester.pumpAndSettle();
    expect(find.text('MORE CONDITIONS'), findsNothing);
    expect(find.text('7-DAY OUTLOOK'), findsNothing);
    await tester.ensureVisible(
      find.byKey(const Key('home-conditions-more-details')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('home-conditions-more-details')));
    await tester.pumpAndSettle();
    expect(find.byType(FishingConditionsDetailsScreen), findsOneWidget);
    expect(find.text('Summary'), findsOneWidget);
    expect(find.text('Tides'), findsOneWidget);
    expect(find.text('Sun'), findsOneWidget);
    expect(find.byType(FishActivityIndicator), findsOneWidget);
    expect(find.text('MORE CONDITIONS'), findsOneWidget);
    expect(find.text('7-DAY OUTLOOK'), findsOneWidget);
    expect(find.text('HOURLY FORECAST'), findsOneWidget);
  });

  testWidgets('Fishing Conditions dashboard fits an iPad viewport', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(834, 1194);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
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
          child: const MaterialApp(home: FishingConditionsDashboardScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Agadir, Morocco'), findsOneWidget);
  });
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

class _WidgetPosition implements DevicePositionSource {
  @override
  Future<bool> isEnabled() async => true;
  @override
  Future<LocationPermission> checkPermission() async =>
      LocationPermission.whileInUse;
  @override
  Future<LocationPermission> requestPermission() async =>
      LocationPermission.whileInUse;
  @override
  Future<LatLng> currentPoint() async => const LatLng(31.5085, -9.7595);
}

class _WidgetPlaces implements PlaceNameSource {
  @override
  Future<String?> describe(LatLng point) async => 'Essaouira, Morocco';
  @override
  Future<LatLng?> search(String query) async => null;
}

class _TokyoSpotsSource implements NearbySpotsSource {
  @override
  Future<List<Map<String, dynamic>>> fetch(FishingLocation location) async => [
    {
      'type': 'node',
      'id': 300,
      'lat': location.point.latitude + .01,
      'lon': location.point.longitude,
      'tags': {'name': 'Tokyo Fishing Pier', 'man_made': 'pier'},
    },
  ];
}

class _RecoveringSpotsSource implements NearbySpotsSource {
  int calls = 0;

  @override
  Future<List<Map<String, dynamic>>> fetch(FishingLocation location) async {
    calls++;
    if (calls == 1) throw StateError('temporary outage');
    return [
      {
        'type': 'node',
        'id': 301,
        'lat': location.point.latitude + .01,
        'lon': location.point.longitude,
        'tags': {'name': 'Valencia Beach', 'natural': 'beach'},
      },
    ];
  }
}

class _RegionalFishSource implements NearbyFishSource {
  @override
  Future<NearbyFishPage> fetch(FishingLocation location, int page) async {
    final tokyo = location.label.contains('Tokyo');
    return NearbyFishPage(
      page: page,
      total: 1,
      fish: [
        NearbyFish(
          taxonId: tokyo ? 2 : 1,
          name: tokyo ? 'Japanese Sea Bass' : 'Moroccan White Seabream',
          scientificName: tokyo ? 'Lateolabrax japonicus' : 'Diplodus sargus',
          observationCount: tokyo ? 9 : 7,
        ),
      ],
    );
  }
}

class _WidgetCatalogSource implements FishCatalogSource {
  final List<String> calls = [];

  @override
  Future<FishCatalogPage> fetch(String query, int page) async {
    calls.add('$query/$page');
    return FishCatalogPage(
      total: query.isEmpty ? 42 : 1,
      page: page,
      species: [
        FishCatalogSpecies(
          taxonId: query.isEmpty ? 100 : 200,
          name: query.isEmpty ? 'Bluegill' : 'Basking Shark',
          scientificName: query.isEmpty
              ? 'Lepomis macrochirus'
              : 'Cetorhinus maximus',
          observationCount: query.isEmpty ? 1000 : 318,
        ),
      ],
    );
  }
}

class _EmptyCoastlineSource implements CoastlineSource {
  @override
  Future<List<List<LatLng>>> fetch(FishingLocation location) async => [];
}
