import '../../src/rust/dto/cards.dart';
import '../../src/rust/dto/library.dart';
import '../../src/rust/dto/media.dart';
import 'home_sections.dart';

typedef KindCard = ({MediaKindDto kind, MediaCardDto card});

const heroSlots = [true, true, false, true, true, false, true, true];
const resumeLimit = 12;

MediaKindDto otherKind(MediaKindDto kind) =>
    kind == MediaKindDto.anime ? MediaKindDto.manga : MediaKindDto.anime;

MediaKindDto favoredKind({required bool prefersAnime}) =>
    prefersAnime ? MediaKindDto.anime : MediaKindDto.manga;

List<KindCard> _trending(MediaKindDto kind, HomeDto? home) {
  if (home == null) return [];
  return [
    for (final card in cardsOf(home, 'trending')) (kind: kind, card: card),
  ];
}

List<KindCard> mixHero({
  required HomeDto? anime,
  required HomeDto? manga,
  required bool prefersAnime,
}) {
  final favored = favoredKind(prefersAnime: prefersAnime);
  final primary = _trending(
    favored,
    favored == MediaKindDto.anime ? anime : manga,
  );
  final other = otherKind(favored);
  final secondary = _trending(
    other,
    other == MediaKindDto.anime ? anime : manga,
  );
  final mixed = <KindCard>[];
  for (final wantPrimary in heroSlots) {
    final first = wantPrimary ? primary : secondary;
    final second = wantPrimary ? secondary : primary;
    final source = first.isNotEmpty ? first : second;
    if (source.isEmpty) break;
    mixed.add(source.removeAt(0));
  }
  return mixed;
}

List<ProgressDto> mergeResume(
  List<ProgressDto> anime,
  List<ProgressDto> manga,
) {
  final all = [...anime, ...manga]
    ..sort((a, b) => b.updatedAtSecs.compareTo(a.updatedAtSecs));
  return all.take(resumeLimit).toList();
}

String railTitle(MediaKindDto kind, String sectionId) {
  final anime = kind == MediaKindDto.anime;
  return switch (sectionId) {
    'trending' => anime ? 'Top 10 anime' : 'Top 10 manga',
    'latest' => anime ? 'Episode baru' : 'Chapter baru',
    'seasonal' => anime ? 'Anime musim ini' : 'Manga musim ini',
    'popular' => anime ? 'Anime populer' : 'Manga populer',
    _ => sectionId,
  };
}

String actionLabelFor(MediaKindDto kind) =>
    kind == MediaKindDto.anime ? 'Tonton' : 'Baca';
