import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../src/rust/api/subtitle.dart' as core;
import '../../../src/rust/dto/cues.dart';
import '../../../src/rust/dto/settings.dart';
import '../../../src/rust/dto/stream.dart';
import '../../../src/rust/dto/stream_extras.dart';
import 'playback_engine.dart';
import 'skip_logic.dart';
import 'subtitle_logic.dart';
import 'video_quality.dart';

typedef CueLoader = Future<List<CueDto>> Function(
  String url,
  List<HeaderDto> headers,
);

Future<List<CueDto>> loadCuesFromCore(String url, List<HeaderDto> headers) =>
    core.fetchCues(url: url, headers: headers);

class PlayerExtras {
  PlayerExtras({
    required this.engine,
    required this.settings,
    required this.cueLoader,
    required this.seek,
  });

  final PlaybackEngine engine;
  final SettingsDto settings;
  final CueLoader cueLoader;
  final Future<void> Function(Duration target) seek;

  final ValueNotifier<List<VideoQuality>> tracks = ValueNotifier(const []);
  final ValueNotifier<String?> trackId = ValueNotifier(null);
  final ValueNotifier<SubtitleDto?> subtitle = ValueNotifier(null);
  final ValueNotifier<List<CueDto>> cues = ValueNotifier(const []);
  final ValueNotifier<SkipDto?> current = ValueNotifier(null);
  final ValueNotifier<List<SkipDto>> marks = ValueNotifier(const []);

  List<SubtitleDto> available = const [];
  List<SkipDto> _skips = const [];
  List<HeaderDto> _headers = const [];
  final Set<String> _taken = {};
  int _cueRequest = 0;
  bool _closed = false;

  bool get hasSubtitles => available.isNotEmpty;

  void load(StreamSetDto set) {
    available = set.subtitles;
    _skips = set.skips;
    marks.value = set.skips;
    _headers = set.headers;
    _taken.clear();
    current.value = null;
    unawaited(
      selectSubtitle(chooseSubtitle(available, settings.subtitleLanguage)),
    );
  }

  Future<void> onOpened() async {
    List<VideoQuality> found;
    try {
      found = await engine.qualities();
    } on Object {
      found = const [];
    }
    if (_closed) return;
    tracks.value = found;
    trackId.value = null;
    final wanted = preferredTrack(found, settings.quality);
    if (wanted != null) await selectTrack(wanted.id);
  }

  Future<void> selectTrack(String? id) async {
    if (_closed) return;
    trackId.value = id;
    try {
      await engine.selectQuality(id);
    } on Object {
      trackId.value = null;
    }
  }

  Future<void> selectSubtitle(SubtitleDto? track) async {
    final request = ++_cueRequest;
    subtitle.value = track;
    cues.value = const [];
    if (track == null) return;
    try {
      final loaded = await cueLoader(track.url, _headers);
      if (request == _cueRequest && !_closed) cues.value = loaded;
    } on Object {
      if (request == _cueRequest && !_closed) cues.value = const [];
    }
  }

  void onPosition(Duration position) {
    if (_closed) return;
    final range = activeSkip(_skips, position);
    final same =
        range?.kind == current.value?.kind &&
        range?.startMs == current.value?.startMs;
    if (!same) current.value = range;
    if (range == null || !settings.autoSkip) return;
    if (_taken.add(skipKey(range))) unawaited(seek(skipTarget(range)));
  }

  Future<void> skipCurrent() async {
    final range = current.value;
    if (range == null) return;
    _taken.add(skipKey(range));
    current.value = null;
    await seek(skipTarget(range));
  }

  void dispose() {
    _closed = true;
    tracks.dispose();
    trackId.dispose();
    subtitle.dispose();
    cues.dispose();
    current.dispose();
    marks.dispose();
  }
}
