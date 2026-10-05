abstract final class WindDirection {
  static const _points = <String>[
    'N',
    'NNE',
    'NE',
    'ENE',
    'E',
    'ESE',
    'SE',
    'SSE',
    'S',
    'SSW',
    'SW',
    'WSW',
    'W',
    'WNW',
    'NW',
    'NNW',
  ];

  /// Meteorological wind direction: the direction the air comes from.
  static String fromDegrees(num degrees) {
    final normalized = ((degrees % 360) + 360) % 360;
    return _points[(normalized / 22.5).round() % 16];
  }
}
