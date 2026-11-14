import 'package:flutter/foundation.dart';

import '../../platform/screen_awake.dart';
import 'player/playback_engine.dart';

class AwakeGuard {
  AwakeGuard(this._awake);

  final ScreenAwake _awake;
  ValueListenable<PlaybackSnapshot>? _source;
  bool _on = false;

  void follow(ValueListenable<PlaybackSnapshot>? source) {
    if (identical(source, _source)) return;
    _source?.removeListener(_sync);
    _source = source;
    source?.addListener(_sync);
    _sync();
  }

  void _sync() {
    final snapshot = _source?.value;
    final wanted = snapshot != null && (snapshot.playing || snapshot.buffering);
    if (wanted == _on) return;
    _on = wanted;
    _awake.keepOn(wanted);
  }

  void dispose() {
    _source?.removeListener(_sync);
    _source = null;
    if (!_on) return;
    _on = false;
    _awake.keepOn(false);
  }
}
