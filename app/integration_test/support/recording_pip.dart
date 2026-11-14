import 'dart:async';

import 'package:kolektaku/platform/pip.dart';

class RecordingPip extends ChannelPipHost {
  final List<bool> modes = [];
  final List<bool> playingUpdates = [];
  int toggles = 0;

  RecordingPip() {
    modeChanges.listen(modes.add);
    toggleRequests.listen((_) => toggles++);
  }

  @override
  Future<void> update({required bool playing}) {
    playingUpdates.add(playing);
    return super.update(playing: playing);
  }
}
