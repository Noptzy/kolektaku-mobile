import 'package:flutter/foundation.dart';

import '../../../src/rust/dto/cues.dart';
import '../../../src/rust/dto/settings.dart';
import '../../../src/rust/dto/stream.dart';
import '../../../src/rust/dto/stream_extras.dart';
import 'cue_loading.dart';
import 'translation_logic.dart';

class SubtitleCues {
  SubtitleCues({
    required this.loader,
    required this.settings,
    required this.position,
  });

  final CueLoader loader;
  final SettingsDto settings;
  final Duration Function() position;

  final ValueNotifier<List<CueDto>> cues = ValueNotifier(const []);
  final ValueNotifier<TranslationStatus> status = ValueNotifier(
    TranslationStatus.none,
  );
  final ValueNotifier<bool> showingOriginal = ValueNotifier(false);
  final ValueNotifier<String?> notice = ValueNotifier(null);

  List<CueDto> _original = const [];
  List<CueDto> _translated = const [];
  int _request = 0;
  bool _closed = false;

  bool get canToggleOriginal => status.value == TranslationStatus.translated;

  void newEpisode() {
    notice.value = null;
  }

  void clear() {
    _request++;
    _original = const [];
    _translated = const [];
    cues.value = const [];
    showingOriginal.value = false;
    status.value = TranslationStatus.none;
  }

  Future<void> load(SubtitleDto track, List<HeaderDto> headers) async {
    clear();
    final request = _request;
    bool current() => request == _request && !_closed;
    try {
      final plain = await loader(_ask(track, headers, translate: false));
      if (!current()) return;
      _original = plain.cues;
      _publish();
      if (!_wantsTranslation(track)) return;
      status.value = TranslationStatus.working;
      final plan = await loader(_ask(track, headers, translate: true));
      if (!current()) return;
      _settle(plan);
    } on Object {
      if (current()) clear();
    }
  }

  CueRequest _ask(
    SubtitleDto track,
    List<HeaderDto> headers, {
    required bool translate,
  }) {
    return CueRequest(
      url: track.url,
      headers: headers,
      language: track.language,
      positionMs: position().inMilliseconds,
      translate: translate,
    );
  }

  bool _wantsTranslation(SubtitleDto track) {
    return translationIsOn(settings.translation) &&
        track.language != trackLanguageOf(settings.translation);
  }

  void _settle(CuePlanDto plan) {
    if (plan.translated) {
      _translated = plan.cues;
      status.value = TranslationStatus.translated;
      _publish();
      return;
    }
    status.value = plan.failed
        ? TranslationStatus.failed
        : TranslationStatus.none;
    if (plan.failed && notice.value == null) {
      notice.value = translationFailedNotice(
        retryAtSecs: plan.retryAtSecs?.toInt(),
      );
    }
  }

  void toggleOriginal() {
    if (!canToggleOriginal) return;
    showingOriginal.value = !showingOriginal.value;
    _publish();
  }

  void _publish() {
    final translated = status.value == TranslationStatus.translated;
    cues.value = translated && !showingOriginal.value ? _translated : _original;
  }

  void dispose() {
    _closed = true;
    cues.dispose();
    status.dispose();
    showingOriginal.dispose();
    notice.dispose();
  }
}
