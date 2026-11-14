import 'package:flutter/foundation.dart';

import 'episode_end.dart';
import 'playback_engine.dart';

class EndWatcher {
  EndWatcher({required this.onEnd, required this.onLeave});

  final VoidCallback onEnd;
  final VoidCallback onLeave;
  bool _handled = false;

  void reset() => _handled = false;

  void feed(PlaybackSnapshot snapshot) {
    if (hasEnded(snapshot)) {
      if (_handled) return;
      _handled = true;
      onEnd();
    } else if (_handled && leftTheEnd(snapshot)) {
      _handled = false;
      onLeave();
    }
  }
}
