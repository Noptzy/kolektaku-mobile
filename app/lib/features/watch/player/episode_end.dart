import 'playback_engine.dart';

const _endTolerance = Duration(milliseconds: 800);
const _resumeBackBy = Duration(seconds: 3);

bool hasEnded(PlaybackSnapshot snapshot) {
  if (snapshot.duration <= Duration.zero) return false;
  return snapshot.position >= snapshot.duration - _endTolerance;
}

bool leftTheEnd(PlaybackSnapshot snapshot) {
  if (snapshot.duration <= Duration.zero) return false;
  return snapshot.position < snapshot.duration - _resumeBackBy;
}
