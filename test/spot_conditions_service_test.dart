import 'package:flutter_test/flutter_test.dart';
import 'package:fishing/models/demo_data.dart';
import 'package:fishing/models/fishing_conditions.dart';
import 'package:fishing/models/fishing_location.dart';
import 'package:fishing/services/demo_condition_data.dart';
import 'package:fishing/services/fishing_conditions_repository.dart';
import 'package:fishing/services/spot_conditions_service.dart';
import 'package:latlong2/latlong.dart';

import 'support/live_conditions_fixture.dart';

const spot = FishingSpot(
  'Nearby Pier',
  '2 km away',
  0,
  'Pier',
  '',
  '',
  [],
  '',
  point: LatLng(41.85, 3.13),
  mapped: true,
  sourceId: 'node/1',
);

void main() {
  test('uses the spot coordinate and preserves mapped identity', () async {
    final repository = _Repository(live: true);
    final result = (await SpotConditionsService(
      repository: repository,
    ).load([spot], forceRefresh: true)).single;
    expect(repository.location!.point, spot.point);
    expect(repository.refresh, isTrue);
    expect(result.hasForecast, isTrue);
    expect(result.score, inInclusiveRange(0, 100));
    expect(result.wind, contains('km/h'));
    expect(result.waves, contains('m'));
    expect(result.sourceId, spot.sourceId);
    expect(result.mapped, isTrue);
  });

  test(
    'sample conditions never become a good or perfect live rating',
    () async {
      final result = (await SpotConditionsService(
        repository: _Repository(live: false),
      ).load([spot])).single;
      expect(result.hasForecast, isFalse);
      expect(result.score, 0);
      expect(result.wind, isEmpty);
    },
  );
}

class _Repository extends FishingConditionsRepository {
  _Repository({required this.live});
  final bool live;
  FishingLocation? location;
  bool refresh = false;
  @override
  Future<FishingConditions> load(
    FishingLocation value, {
    bool forceRefresh = false,
  }) async {
    location = value;
    refresh = forceRefresh;
    return live
        ? liveConditionsFixture(value)
        : DemoConditionData.forLocation(value);
  }
}
