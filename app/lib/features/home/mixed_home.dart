import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../core/theme/kolektaku_tokens.dart';
import '../../src/rust/dto/cards.dart';
import '../../src/rust/dto/library.dart';
import '../../src/rust/dto/media.dart';
import '../../src/rust/dto/sources.dart';
import '../../widgets/hero_carousel.dart';
import '../../widgets/hero_slide.dart';
import '../../widgets/media_rail.dart';
import '../../widgets/top10_rail.dart';
import 'genre_grid.dart';
import 'home_actions.dart';
import 'home_mix.dart';
import 'home_notice.dart';
import 'home_sections.dart';
import 'resume_card.dart';

class MixedHome extends StatelessWidget {
  const MixedHome({
    super.key,
    required this.anime,
    required this.manga,
    required this.prefersAnime,
    required this.resume,
    required this.genres,
    required this.covers,
    required this.actions,
  });

  final HomeDto? anime;
  final HomeDto? manga;
  final bool prefersAnime;
  final List<ProgressDto> resume;
  final Map<MediaKindDto, List<GenreDto>> genres;
  final Map<MediaKindDto, Map<String, String>> covers;
  final HomeActions actions;

  HomeDto? _home(MediaKindDto kind) =>
      kind == MediaKindDto.anime ? anime : manga;

  Widget _top(MediaKindDto kind) {
    final home = _home(kind);
    final cards = home == null
        ? const <MediaCardDto>[]
        : cardsOf(home, 'trending');
    if (cards.isEmpty) return const SizedBox.shrink();
    return Top10Rail(
      title: railTitle(kind, 'trending'),
      cards: cards,
      onTap: (card) => actions.onOpen(kind, card),
    );
  }

  Widget _rail(MediaKindDto kind, String id, {bool fresh = false}) {
    final home = _home(kind);
    final cards = home == null ? const <MediaCardDto>[] : cardsOf(home, id);
    if (cards.isEmpty) return const SizedBox.shrink();
    return MediaRail(
      title: railTitle(kind, id),
      cards: cards,
      unitLabel: unitLabelFor(kind),
      newOnly: fresh,
      onTap: (card) => actions.onOpen(kind, card),
    );
  }

  Widget _genres(MediaKindDto kind) {
    final home = _home(kind);
    if (home == null) return const SizedBox.shrink();
    return GenreGrid(
      genres: genres[kind] ?? const [],
      covers: covers[kind] ?? const {},
      home: home,
      onGenre: (genre) => actions.onGenre(kind, genre),
      onAll: () => actions.onAllGenres(kind),
    );
  }

  Widget _otherGenres(MediaKindDto kind) {
    if ((genres[kind] ?? const []).isEmpty) return const SizedBox.shrink();
    final label = kind == MediaKindDto.anime ? 'anime' : 'manga';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Spacing.screenGutter),
      child: ShadButton.outline(
        onPressed: () => actions.onAllGenres(kind),
        child: Text('Jelajahi genre $label'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final favored = favoredKind(prefersAnime: prefersAnime);
    final other = otherKind(favored);
    final hero = mixHero(
      anime: anime,
      manga: manga,
      prefersAnime: prefersAnime,
    );
    final resumeCards = [for (final item in resume) resumeCard(item)];
    final notices = [...?anime?.notices, ...?manga?.notices];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: Spacing.xl,
      children: [
        if (notices.isNotEmpty) HomeNotice(notices: notices),
        if (hero.isNotEmpty)
          HeroCarousel(
            slides: [
              for (final item in hero)
                HeroSlide.fromCard(
                  item.card,
                  actionLabel: actionLabelFor(item.kind),
                ),
            ],
            onWatch: (index) =>
                actions.onOpen(hero[index].kind, hero[index].card),
          ),
        if (resume.isNotEmpty)
          MediaRail(
            title: 'Lanjutkan',
            cards: resumeCards,
            unitLabel: '',
            progressOf: (card) =>
                resumeFraction(resume[resumeCards.indexOf(card)]),
            onTap: (card) =>
                actions.onResume(resume[resumeCards.indexOf(card)]),
          ),
        _top(favored),
        _rail(favored, 'latest', fresh: true),
        _top(other),
        _genres(favored),
        _rail(favored, 'seasonal'),
        _rail(other, 'latest', fresh: true),
        _rail(favored, 'popular'),
        _rail(other, 'popular'),
        _otherGenres(other),
        const SizedBox(height: Spacing.xl),
      ],
    );
  }
}
