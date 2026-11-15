import '../../src/rust/dto/cards.dart';
import '../../src/rust/dto/library.dart';
import '../../src/rust/dto/media.dart';
import '../../widgets/kind_switch.dart';
import 'home_sections.dart';

typedef HeroEntry = ({MediaKindDto kind, MediaCardDto card, String label});

const heroCategories = [
  ('top_rated', 'Rating tertinggi minggu ini'),
  ('new_week', 'Terbaru minggu ini'),
  ('finished_week', 'Baru saja tamat minggu ini'),
  ('returning', 'Baru saja comeback'),
  ('trending', 'Sedang ramai minggu ini'),
];
const otherKindCategories = ['top_rated', 'new_week'];
const resumeLimit = 12;

MediaKindDto otherKind(MediaKindDto kind) =>
    kind == MediaKindDto.anime ? MediaKindDto.manga : MediaKindDto.anime;

MediaKindDto favoredKind({required bool prefersAnime}) =>
    prefersAnime ? MediaKindDto.anime : MediaKindDto.manga;

String heroLabelOf(String sectionId) {
  for (final (id, label) in heroCategories) {
    if (id == sectionId) return label;
  }
  return sectionId;
}

List<HeroEntry> _entries(
  MediaKindDto kind,
  HomeDto? home,
  Iterable<String> sections,
  Set<String> seen, {
  required bool prefixed,
}) {
  if (home == null) return const [];
  final found = <HeroEntry>[];
  for (final id in sections) {
    for (final card in cardsOf(home, id)) {
      final key = '${kind.name}:${card.reference.id}';
      if (!seen.add(key)) continue;
      final label = heroLabelOf(id);
      found.add((
        kind: kind,
        card: card,
        label: prefixed ? '${kindSwitchLabel(kind)} · $label' : label,
      ));
      break;
    }
  }
  return found;
}

List<HeroEntry> mixHero({
  required HomeDto? anime,
  required HomeDto? manga,
  required bool prefersAnime,
}) {
  final favored = favoredKind(prefersAnime: prefersAnime);
  final other = otherKind(favored);
  HomeDto? homeOf(MediaKindDto kind) =>
      kind == MediaKindDto.anime ? anime : manga;
  final seen = <String>{};
  final primary = _entries(
    favored,
    homeOf(favored),
    heroCategories.map((entry) => entry.$1),
    seen,
    prefixed: false,
  );
  final secondary = _entries(
    other,
    homeOf(other),
    otherKindCategories,
    seen,
    prefixed: true,
  );
  if (primary.isEmpty) {
    return _entries(
      other,
      homeOf(other),
      heroCategories.map((entry) => entry.$1),
      <String>{},
      prefixed: false,
    );
  }
  return [...primary, ...secondary];
}

List<ProgressDto> mergeResume(Iterable<List<ProgressDto>> groups) {
  final all = [for (final group in groups) ...group]
    ..sort((a, b) => b.updatedAtSecs.compareTo(a.updatedAtSecs));
  return all.take(resumeLimit).toList();
}

String railTitle(MediaKindDto kind, String sectionId) {
  if (kind == MediaKindDto.novel) {
    return sectionId == 'popular' ? 'Novel populer' : sectionId;
  }
  final anime = kind == MediaKindDto.anime;
  return switch (sectionId) {
    'trending' => anime ? 'Top 10 anime' : 'Top 10 komik',
    'latest' => anime ? 'Episode baru' : 'Chapter baru',
    'seasonal' => anime ? 'Anime musim ini' : 'Komik musim ini',
    'popular' => anime ? 'Anime populer' : 'Komik populer',
    _ => sectionId,
  };
}

String actionLabelFor(MediaKindDto kind) =>
    kind == MediaKindDto.anime ? 'Tonton' : 'Baca';
