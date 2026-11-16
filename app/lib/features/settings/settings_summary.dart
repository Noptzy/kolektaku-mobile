import '../../core/theme/accent_palette.dart';
import '../../core/translation_labels.dart';
import '../../src/rust/dto/media.dart';
import '../../src/rust/dto/settings.dart';
import '../../src/rust/dto/sources.dart';
import 'settings_labels.dart';
import 'settings_logic.dart';

String preferenceSummary(SettingsDto settings) =>
    settings.prefersAnime ? 'Lebih banyak anime' : 'Lebih banyak komik';

String appearanceSummary(SettingsDto settings) {
  for (final preset in accentPresets) {
    if (accentToHex(preset.color) == settings.accent) return preset.label;
  }
  return 'Kustom';
}

String translationSummary(SettingsDto settings) =>
    translationLanguageNames[settings.translation]!;

String animeSourceSummary(
  SettingsDto settings,
  List<SourceStatusDto> statuses,
) {
  final chosen = settings.animeSource;
  if (chosen == null) return 'Otomatis';
  for (final entry in numberedSources(statuses, MediaKindDto.anime)) {
    if (entry.status.id == chosen) {
      return sourceLabel(MediaKindDto.anime, entry.number);
    }
  }
  return 'Otomatis';
}

String subtitleSummary(SettingsDto settings) {
  if (settings.subtitleLanguage == SubtitleLanguageDto.off) return 'Mati';
  final language = labelOf(languageOptions, settings.subtitleLanguage);
  final size = labelOf(sizeOptions, settings.subtitleSize);
  return '$language · $size';
}

String playerSummary(SettingsDto settings) {
  final parts = [
    'Kualitas ${labelOf(qualityOptions, settings.quality).toLowerCase()}',
    if (settings.autoNext) 'berikutnya otomatis',
    if (settings.autoSkip) 'lewati otomatis',
  ];
  return parts.join(' · ');
}

String sourcesSummary(List<SourceStatusDto> statuses) {
  if (statuses.isEmpty) return 'Memuat daftar sumber';
  final active = statuses.where((status) => status.enabled).length;
  return '$active dari ${statuses.length} sumber aktif';
}
