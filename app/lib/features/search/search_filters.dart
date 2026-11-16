import '../../src/rust/dto/cards.dart';
import '../../src/rust/dto/media.dart';

enum SearchFormat {
  all('Semua', []),
  tv('TV', ['TV', 'TV_SHORT']),
  movie('Film', ['MOVIE']),
  ova('OVA', ['OVA', 'ONA', 'SPECIAL']),
  music('Musik', ['MUSIC']),
  manga('Komik', ['MANGA']),
  oneShot('One-shot', ['ONE_SHOT']),
  novel('Novel', ['NOVEL']);

  const SearchFormat(this.label, this.formats);

  final String label;
  final List<String> formats;

  bool accepts(String? format) {
    if (this == SearchFormat.all) return true;
    return format != null && formats.contains(format.toUpperCase());
  }

  static List<SearchFormat> forKind(MediaKindDto kind) => switch (kind) {
    MediaKindDto.anime => const [all, tv, movie, ova, music],
    MediaKindDto.manga => const [all, manga, oneShot],
    MediaKindDto.novel => const [all],
  };
}

enum SearchOrder {
  relevance('Relevan'),
  score('Skor tertinggi'),
  newest('Terbaru');

  const SearchOrder(this.label);

  final String label;

  List<MediaCardDto> apply(List<MediaCardDto> cards) {
    final sorted = [...cards];
    switch (this) {
      case SearchOrder.relevance:
        return sorted;
      case SearchOrder.score:
        sorted.sort((a, b) => (b.score ?? -1).compareTo(a.score ?? -1));
      case SearchOrder.newest:
        sorted.sort((a, b) => (b.year ?? -1).compareTo(a.year ?? -1));
    }
    return sorted;
  }
}

List<MediaCardDto> filterCards(
  List<MediaCardDto> cards,
  SearchFormat format,
  SearchOrder order,
) {
  final kept = cards.where((card) => format.accepts(card.format)).toList();
  return order.apply(kept);
}
