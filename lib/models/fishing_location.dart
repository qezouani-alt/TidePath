import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';

@immutable
class FishingLocation {
  const FishingLocation({
    required this.label,
    required this.point,
    this.fromDevice = false,
  });

  final String label;
  final LatLng point;
  final bool fromDevice;

  String get shortName {
    final first = label.split(',').first.trim();
    return first == 'Selected location' || double.tryParse(first) != null
        ? 'this location'
        : first;
  }

  String get coordinates =>
      '${point.latitude.toStringAsFixed(4)}, ${point.longitude.toStringAsFixed(4)}';

  bool get isNearAgadir =>
      const Distance().as(
        LengthUnit.Kilometer,
        point,
        const LatLng(30.4278, -9.5981),
      ) <
      60;
}

class FishingLocationController extends ChangeNotifier {
  FishingLocation _selected = const FishingLocation(
    label: 'Agadir, Morocco',
    point: LatLng(30.4278, -9.5981),
  );

  FishingLocation get selected => _selected;

  void select(FishingLocation location) {
    _selected = location;
    notifyListeners();
  }
}
