import '../../src/rust/dto/cards.dart';
import '../../src/rust/dto/media.dart';

const genreTileCount = 6;

List<MediaCardDto> cardsOf(HomeDto home, String sectionId) {
  for (final section in home.sections) {
    if (section.id == sectionId) return section.cards;
  }
  return const [];
}

String unitLabelFor(MediaKindDto kind) =>
    kind == MediaKindDto.anime ? 'eps' : 'ch';

String resumeTitle(MediaKindDto kind) =>
    kind == MediaKindDto.anime ? 'Lanjut nonton' : 'Lanjut baca';

String? genreImage(String genreName, HomeDto home) {
  final wanted = genreName.toLowerCase();
  for (final section in home.sections) {
    for (final card in section.cards) {
      final cover = card.coverUrl;
      if (cover == null) continue;
      if (card.genres.any((genre) => genre.toLowerCase() == wanted)) {
        return cover;
      }
    }
  }
  return null;
}
