import '../../src/rust/dto/settings.dart';

typedef Options<T> = List<(T, String)>;

const Options<SubtitleLanguageDto> languageOptions = [
  (SubtitleLanguageDto.indonesian, 'Indonesia'),
  (SubtitleLanguageDto.english, 'Inggris'),
  (SubtitleLanguageDto.off, 'Mati'),
];

const Options<SubtitleSizeDto> sizeOptions = [
  (SubtitleSizeDto.small, 'Kecil'),
  (SubtitleSizeDto.medium, 'Sedang'),
  (SubtitleSizeDto.large, 'Besar'),
  (SubtitleSizeDto.huge, 'Sangat besar'),
];

const Options<SubtitleColorDto> inkOptions = [
  (SubtitleColorDto.white, 'Putih'),
  (SubtitleColorDto.yellow, 'Kuning'),
  (SubtitleColorDto.green, 'Hijau'),
  (SubtitleColorDto.cyan, 'Biru muda'),
  (SubtitleColorDto.pink, 'Merah muda'),
];

const Options<SubtitleEdgeDto> edgeOptions = [
  (SubtitleEdgeDto.none, 'Tanpa'),
  (SubtitleEdgeDto.shadow, 'Bayangan'),
  (SubtitleEdgeDto.outline, 'Garis tepi'),
];

const Options<SubtitleBoxColorDto> boxInkOptions = [
  (SubtitleBoxColorDto.black, 'Hitam'),
  (SubtitleBoxColorDto.gray, 'Abu-abu'),
  (SubtitleBoxColorDto.navy, 'Biru tua'),
];

const Options<SubtitleBoxOpacityDto> opacityOptions = [
  (SubtitleBoxOpacityDto.off, 'Tanpa latar'),
  (SubtitleBoxOpacityDto.light, 'Tipis'),
  (SubtitleBoxOpacityDto.medium, 'Sedang'),
  (SubtitleBoxOpacityDto.full, 'Penuh'),
];

const Options<QualityDto> qualityOptions = [
  (QualityDto.auto, 'Otomatis'),
  (QualityDto.p1080, '1080p'),
  (QualityDto.p720, '720p'),
  (QualityDto.p480, '480p'),
  (QualityDto.p360, '360p'),
];

String labelOf<T>(Options<T> options, T value) {
  for (final option in options) {
    if (option.$1 == value) return option.$2;
  }
  return options.first.$2;
}
