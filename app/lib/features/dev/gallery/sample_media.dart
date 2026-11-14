import '../../../src/rust/dto/cards.dart';
import '../../../src/rust/dto/media.dart';

const sampleSynopsis =
    'Seorang apoteker muda kembali ke kehidupan lamanya di distrik hiburan '
    'setelah pemberontakan berakhir, tetapi teka-teki baru segera muncul dan '
    'menariknya ke dalam intrik istana.';

MediaCardDto sampleCard(
  int id, {
  String? title,
  double? score = 8.6,
  int? year = 2016,
  int? units = 12,
  bool limited = false,
  bool withSynopsis = true,
  String? format = 'TV',
}) {
  return MediaCardDto(
    reference: MediaRefDto(
      kind: MediaRefKind.catalog,
      id: BigInt.from(id),
      source: '',
      item: '',
    ),
    title: title ?? 'Judul contoh nomor $id yang cukup panjang',
    coverUrl: null,
    synopsis: withSynopsis ? sampleSynopsis : null,
    score: score,
    year: year,
    format: format,
    genres: const ['Action', 'Drama'],
    unitCount: units,
    limited: limited,
    sources: const [],
  );
}

List<MediaCardDto> sampleCards(int count) => [
  for (var i = 1; i <= count; i++)
    sampleCard(
      i,
      limited: i == 3,
      score: i == 2 ? null : 9.0 - i / 10,
      units: i == 4 ? null : 12,
    ),
];
