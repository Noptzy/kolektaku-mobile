import '../../src/rust/dto/settings.dart';

extension SettingsEdit on SettingsDto {
  SettingsDto copyWith({
    bool? prefersAnime,
    SubtitleLanguageDto? subtitleLanguage,
    SubtitleSizeDto? subtitleSize,
    SubtitleColorDto? subtitleColor,
    SubtitleEdgeDto? subtitleEdge,
    SubtitleBoxColorDto? subtitleBoxColor,
    SubtitleBoxOpacityDto? subtitleBoxOpacity,
    QualityDto? quality,
    bool? autoNext,
    bool? autoSkip,
  }) {
    return _build(
      prefersAnime: prefersAnime ?? this.prefersAnime,
      animeSource: animeSource,
      subtitleLanguage: subtitleLanguage ?? this.subtitleLanguage,
      subtitleSize: subtitleSize ?? this.subtitleSize,
      subtitleColor: subtitleColor ?? this.subtitleColor,
      subtitleEdge: subtitleEdge ?? this.subtitleEdge,
      subtitleBoxColor: subtitleBoxColor ?? this.subtitleBoxColor,
      subtitleBoxOpacity: subtitleBoxOpacity ?? this.subtitleBoxOpacity,
      quality: quality ?? this.quality,
      autoNext: autoNext ?? this.autoNext,
      autoSkip: autoSkip ?? this.autoSkip,
    );
  }

  SettingsDto withAnimeSource(String? source) {
    return _build(
      prefersAnime: prefersAnime,
      animeSource: source,
      subtitleLanguage: subtitleLanguage,
      subtitleSize: subtitleSize,
      subtitleColor: subtitleColor,
      subtitleEdge: subtitleEdge,
      subtitleBoxColor: subtitleBoxColor,
      subtitleBoxOpacity: subtitleBoxOpacity,
      quality: quality,
      autoNext: autoNext,
      autoSkip: autoSkip,
    );
  }

  SettingsDto withDefaultSubtitleLook() {
    return copyWith(
      subtitleSize: SubtitleSizeDto.medium,
      subtitleColor: SubtitleColorDto.white,
      subtitleEdge: SubtitleEdgeDto.outline,
      subtitleBoxColor: SubtitleBoxColorDto.black,
      subtitleBoxOpacity: SubtitleBoxOpacityDto.off,
    );
  }
}

SettingsDto _build({
  required bool prefersAnime,
  required String? animeSource,
  required SubtitleLanguageDto subtitleLanguage,
  required SubtitleSizeDto subtitleSize,
  required SubtitleColorDto subtitleColor,
  required SubtitleEdgeDto subtitleEdge,
  required SubtitleBoxColorDto subtitleBoxColor,
  required SubtitleBoxOpacityDto subtitleBoxOpacity,
  required QualityDto quality,
  required bool autoNext,
  required bool autoSkip,
}) {
  return SettingsDto(
    prefersAnime: prefersAnime,
    animeSource: animeSource,
    subtitleLanguage: subtitleLanguage,
    subtitleSize: subtitleSize,
    subtitleColor: subtitleColor,
    subtitleEdge: subtitleEdge,
    subtitleBoxColor: subtitleBoxColor,
    subtitleBoxOpacity: subtitleBoxOpacity,
    quality: quality,
    autoNext: autoNext,
    autoSkip: autoSkip,
  );
}
