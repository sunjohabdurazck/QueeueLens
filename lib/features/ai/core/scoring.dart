double clamp01(double x) => x < 0 ? 0 : (x > 1 ? 1 : x);

double recommendationScore({
  required int waitMin,
  required double distanceMeters,
  required bool isOpen,
}) {
  if (!isOpen) return 0;

  final waitScore = clamp01(1 - (waitMin / 60));
  final distScore = clamp01(1 - (distanceMeters / 800));
  final openScore = 1.0;

  return (0.55 * waitScore) + (0.35 * distScore) + (0.10 * openScore);
}
