import 'dart:math' as math;

enum CoastWindRelation { onshore, offshore, alongshore }

/// The compass bearing from a shoreline toward open water.
class CoastOrientation {
  const CoastOrientation({
    required this.seaBearingDegrees,
    required this.distanceKm,
    this.approximate = false,
  });

  final double seaBearingDegrees;
  final double distanceKm;
  final bool approximate;

  /// Wind directions are meteorological bearings: where the air comes from.
  CoastWindRelation relationForWind(int windFromDegrees) {
    final difference = _angleBetween(windFromDegrees, seaBearingDegrees);
    if (difference <= 60) return CoastWindRelation.onshore;
    if (difference >= 120) return CoastWindRelation.offshore;
    return CoastWindRelation.alongshore;
  }

  static double _angleBetween(num a, num b) {
    final delta = ((a - b) % 360 + 360) % 360;
    return math.min(delta, 360 - delta).toDouble();
  }
}

extension CoastWindRelationLabel on CoastWindRelation {
  String get label => switch (this) {
    CoastWindRelation.onshore => 'Onshore',
    CoastWindRelation.offshore => 'Offshore',
    CoastWindRelation.alongshore => 'Alongshore',
  };
}
