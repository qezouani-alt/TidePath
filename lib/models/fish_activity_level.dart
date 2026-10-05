/// Shared presentation thresholds for the demo score and fish silhouettes.
enum FishActivityLevel {
  veryPoor(0, 'Very Poor'),
  poor(1, 'Poor'),
  average(2, 'Average'),
  good(3, 'Good'),
  excellent(4, 'Excellent'),
  perfect(4, 'Perfect');

  const FishActivityLevel(this.activeFish, this.label);

  final int activeFish;
  final String label;

  static FishActivityLevel fromScore(int score) {
    final value = score.clamp(0, 100);
    if (value < 30) return veryPoor;
    if (value < 50) return poor;
    if (value < 70) return average;
    if (value < 85) return good;
    if (value < 95) return excellent;
    return perfect;
  }
}
