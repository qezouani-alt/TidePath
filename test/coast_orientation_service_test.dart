import 'package:flutter_test/flutter_test.dart';
import 'package:fishing/models/coast_orientation.dart';
import 'package:fishing/models/fishing_location.dart';
import 'package:fishing/services/coast_orientation_service.dart';
import 'package:latlong2/latlong.dart';

void main() {
  test(
    'directed coastline identifies onshore, offshore and alongshore wind',
    () async {
      final source = _CoastlineSource([
        const [LatLng(.01, -.01), LatLng(0, -.01), LatLng(-.01, -.01)],
      ]);
      final service = CoastOrientationService(source: source);
      const location = FishingLocation(
        label: 'Test shore',
        point: LatLng(0, 0),
      );

      final coast = await service.lookup(location);
      expect(coast, isNotNull);
      expect(coast!.seaBearingDegrees, closeTo(270, .1));
      expect(coast.relationForWind(270), CoastWindRelation.onshore);
      expect(coast.relationForWind(90), CoastWindRelation.offshore);
      expect(coast.relationForWind(0), CoastWindRelation.alongshore);

      await service.lookup(location);
      expect(source.calls, 1);
    },
  );

  test('missing coastline leaves coast relation unavailable', () async {
    final service = CoastOrientationService(source: _CoastlineSource([]));
    const location = FishingLocation(
      label: 'Inland location',
      point: LatLng(35, 140),
    );
    expect(await service.lookup(location), isNull);
  });

  test(
    'shoreline request failure leaves Agadir coast relation unavailable',
    () async {
      final service = CoastOrientationService(
        source: _FailingCoastlineSource(),
      );
      const location = FishingLocation(
        label: 'Agadir, Morocco',
        point: LatLng(30.4278, -9.5981),
      );
      final coast = await service.lookup(location);
      expect(coast, isNull);
    },
  );
}

class _CoastlineSource implements CoastlineSource {
  _CoastlineSource(this.ways);
  final List<List<LatLng>> ways;
  int calls = 0;

  @override
  Future<List<List<LatLng>>> fetch(FishingLocation location) async {
    calls++;
    return ways;
  }
}

class _FailingCoastlineSource implements CoastlineSource {
  @override
  Future<List<List<LatLng>>> fetch(FishingLocation location) async =>
      throw StateError('offline');
}
