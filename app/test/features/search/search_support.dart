import 'package:kolektaku/src/rust/dto/cards.dart';
import 'package:kolektaku/src/rust/dto/media.dart';

MediaCardDto card(
  int id, {
  String? title,
  String? format = 'TV',
  double? score = 8.0,
  int? year = 2020,
}) {
  return MediaCardDto(
    reference: MediaRefDto(
      kind: MediaRefKind.catalog,
      id: BigInt.from(id),
      source: '',
      item: '',
    ),
    title: title ?? 'Judul $id',
    format: format,
    score: score,
    year: year,
    genres: const [],
    limited: false,
    sources: const [],
  );
}

CardPageDto page(List<MediaCardDto> cards, {bool hasNext = false}) =>
    CardPageDto(cards: cards, hasNextPage: hasNext, notices: const []);
