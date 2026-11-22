import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../core/theme/kolektaku_tokens.dart';
import '../../src/rust/dto/cards.dart';
import '../../src/rust/dto/library.dart';
import '../../src/rust/dto/media.dart';
import '../../src/rust/dto/sources.dart';
import '../../widgets/hero_slide.dart';
import '../../widgets/media_rail.dart';
import '../../widgets/top10_rail.dart';
import 'genre_grid.dart';
import 'home_actions.dart';
import 'home_mix.dart';
import 'home_sections.dart';
import 'resume_rail.dart';
import 'top10_section.dart';
import 'translated_hero.dart';

class MixedHome extends StatelessWidget {
  const MixedHome({
    super.key,
    required this.anime,
    required this.manga,
    this.novel,
    required this.prefersAnime,
    required this.resume,
    required this.genres,
    required this.covers,
    required this.actions,
    this.heroAutoPlay,
  });

  final HomeDto? anime;
  final HomeDto? manga;
  final HomeDto? novel;
  final bool prefersAnime;
  final List<ProgressDto> resume;
  final Map<MediaKindDto, List<GenreDto>> genres;
  final Map<MediaKindDto, Map<String, String>> covers;
  final HomeActions actions;
  final Duration? heroAutoPlay;

  HomeDto? _home(MediaKindDto kind) => switch (kind) {
    MediaKindDto.anime => anime,
    MediaKindDto.manga => manga,
    MediaKindDto.novel => novel,
  };

  List<MediaCardDto> _trending(MediaKindDto kind) {
    final home = _home(kind);
    return home == null ? const [] : cardsOf(home, 'trending');
  }

  Widget _top(MediaKindDto favored, MediaKindDto other) {
    return Top10Section(
      cards: {favored: _trending(favored), other: _trending(other)},
      onTap: actions.onOpen,
    );
  }

  String _key(MediaKindDto kind, MediaCardDto card) =>
      '${kind.name}:${card.reference.id}';

  Set<String> _alreadyShown(
    List<HeroEntry> hero,
    MediaKindDto favored,
    MediaKindDto other,
  ) {
    return {
      for (final item in hero) _key(item.kind, item.card),
      for (final kind in [favored, other]) ...[
        for (final card in _trending(kind).take(topTenCount)) _key(kind, card),
        for (final card in _cards(kind, 'latest')) _key(kind, card),
      ],
    };
  }

  List<MediaCardDto> _cards(MediaKindDto kind, String id) {
    final home = _home(kind);
    return home == null ? const [] : cardsOf(home, id);
  }

  Widget _rail(
    MediaKindDto kind,
    String id, {
    bool fresh = false,
    Set<String> skip = const {},
  }) {
    final cards = [
      for (final card in _cards(kind, id))
        if (!skip.contains(_key(kind, card))) card,
    ];
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
    final label = kind == MediaKindDto.anime ? 'anime' : 'komik';
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: Spacing.xl,
      children: [
        if (hero.isNotEmpty)
          TranslatedHeroCarousel(
            autoPlay: heroAutoPlay,
            slides: [
              for (final item in hero)
                HeroSlide.fromCard(
                  item.card,
                  actionLabel: actionLabelFor(item.kind),
                  label: item.label,
                ),
            ],
            onWatch: (index) =>
                actions.onOpen(hero[index].kind, hero[index].card),
          ),
        if (resume.isNotEmpty) ResumeRail(items: resume, actions: actions),
        _top(favored, other),
        _rail(favored, 'latest', fresh: true),
        _genres(favored),
        _rail(favored, 'seasonal', skip: _alreadyShown(hero, favored, other)),
        _rail(other, 'latest', fresh: true),
        _rail(favored, 'popular'),
        _rail(other, 'popular'),
        _rail(MediaKindDto.novel, 'popular'),
        _otherGenres(other),
        const SizedBox(height: Spacing.xl),
      ],
    );
  }
}
