typedef PositionReader = Duration Function();
typedef Seeker = Future<void> Function(Duration position);

Future<int> holdStart({
  required Duration start,
  required PositionReader position,
  required Seeker seek,
  required bool Function() active,
  Duration tolerance = const Duration(seconds: 3),
  Duration poll = const Duration(milliseconds: 250),
  int pollsPerAttempt = 12,
  int attempts = 3,
}) async {
  if (start <= tolerance) return 0;
  final goal = start - tolerance;
  var reseeks = 0;
  for (var attempt = 0; attempt < attempts; attempt++) {
    for (var tick = 0; tick < pollsPerAttempt; tick++) {
      if (!active()) return reseeks;
      if (position() >= goal) return reseeks;
      await Future<void>.delayed(poll);
    }
    if (!active()) return reseeks;
    reseeks++;
    await seek(start);
  }
  return reseeks;
}
