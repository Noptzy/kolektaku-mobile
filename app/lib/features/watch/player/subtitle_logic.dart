import '../../../src/rust/dto/cues.dart';
import '../../../src/rust/dto/settings.dart';
import '../../../src/rust/dto/stream_extras.dart';
import 'translation_logic.dart';

const _languageNames = {
  'id': 'Indonesia',
  'en': 'Inggris',
  'ms': 'Melayu',
  'ja': 'Jepang',
  'ar': 'Arab',
  'zh': 'Mandarin',
  'ko': 'Korea',
  'th': 'Thai',
  'vi': 'Vietnam',
  'fil': 'Filipino',
  'fr': 'Prancis',
  'de': 'Jerman',
  'it': 'Italia',
  'es': 'Spanyol',
  'pt': 'Portugis',
  'ru': 'Rusia',
  'tr': 'Turki',
  'nl': 'Belanda',
  'pl': 'Polandia',
  'hi': 'Hindi',
};

const _variants = {
  'forced': ' (dialog asing)',
  'sdh': ' (tunarungu)',
  'dubtitle': ' (teks dub)',
};

String subtitleTitle(SubtitleDto track) {
  final name = _languageNames[track.language];
  if (name == null) return track.label;
  return '$name${_variants[track.variant] ?? ''}';
}

String? _languageOf(SubtitleLanguageDto preference) => switch (preference) {
  SubtitleLanguageDto.indonesian => 'id',
  SubtitleLanguageDto.english => 'en',
  SubtitleLanguageDto.off => null,
};

SubtitleDto? _firstFull(Iterable<SubtitleDto> tracks, {String? language}) {
  for (final track in tracks) {
    if (track.variant != 'full') continue;
    if (language == null || track.language == language) return track;
  }
  return null;
}

SubtitleDto? chooseSubtitle(
  List<SubtitleDto> tracks,
  SubtitleLanguageDto preference, {
  TranslationLanguageDto translation = TranslationLanguageDto.off,
}) {
  if (tracks.isEmpty || preference == SubtitleLanguageDto.off) return null;
  final ownLanguage = trackLanguageOf(translation);
  final humanMade = ownLanguage == null
      ? null
      : _firstFull(tracks, language: ownLanguage);
  if (humanMade != null) return humanMade;
  final wanted = _languageOf(preference);
  return _firstFull(tracks, language: wanted) ??
      _firstFull(tracks, language: 'en') ??
      _firstFull(tracks.where((track) => track.isDefault)) ??
      _firstFull(tracks);
}

CueDto? cueAt(List<CueDto> cues, Duration position) {
  final at = position.inMilliseconds;
  var low = 0;
  var high = cues.length - 1;
  while (low <= high) {
    final middle = (low + high) >> 1;
    final cue = cues[middle];
    if (at < cue.startMs.toInt()) {
      high = middle - 1;
    } else if (at >= cue.endMs.toInt()) {
      low = middle + 1;
    } else {
      return cue;
    }
  }
  return null;
}

int _rank(SubtitleDto track) {
  final language = switch (track.language) {
    'id' => 0,
    'en' => 1,
    _ => 2,
  };
  return language * 2 + (track.variant == 'full' ? 0 : 1);
}

List<SubtitleDto> orderedSubtitles(List<SubtitleDto> tracks) {
  final ordered = [...tracks];
  ordered.sort((a, b) {
    final byRank = _rank(a).compareTo(_rank(b));
    return byRank != 0 ? byRank : subtitleTitle(a).compareTo(subtitleTitle(b));
  });
  return ordered;
}
