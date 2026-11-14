import 'dart:async';

import '../../../platform/pip.dart';
import 'player_session.dart';

class WatchPip {
  WatchPip({
    required this.host,
    required this.session,
    required this.onModeChanged,
  });

  final PipHost host;
  final PlayerSession session;
  final void Function(bool inPip) onModeChanged;

  StreamSubscription<bool>? _modes;
  StreamSubscription<void>? _toggles;
  bool _playing = false;

  Future<void> start() async {
    _playing = session.engine.snapshot.value.playing;
    _modes = host.modeChanges.listen(onModeChanged);
    _toggles = host.toggleRequests.listen((_) => session.togglePlay());
    session.engine.snapshot.addListener(_follow);
    await host.arm(playing: _playing);
  }

  void _follow() {
    final playing = session.engine.snapshot.value.playing;
    if (playing == _playing) return;
    _playing = playing;
    host.update(playing: playing);
  }

  Future<void> dispose() async {
    session.engine.snapshot.removeListener(_follow);
    final disarmed = host.disarm();
    await _modes?.cancel();
    await _toggles?.cancel();
    await disarmed;
  }
}
