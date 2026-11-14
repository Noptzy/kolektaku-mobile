import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../core/theme/kolektaku_text.dart';
import '../../core/theme/kolektaku_tokens.dart';
import '../../src/rust/dto/library.dart';
import '../../src/rust/dto/media.dart';
import '../../widgets/media_grid.dart';
import '../../widgets/media_rail.dart';
import '../../widgets/skeleton.dart';
import '../home/home_sections.dart';
import '../home/resume_card.dart';
import 'collection_logic.dart';
import 'history_box.dart';

class SectionTitle extends StatelessWidget {
  const SectionTitle({super.key, required this.text, this.trailing});

  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Spacing.screenGutter,
        Spacing.xl,
        Spacing.screenGutter,
        Spacing.md,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              text,
              style: ShadTheme.of(context).textTheme.sectionTitle,
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

class EmptyNote extends StatelessWidget {
  const EmptyNote({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Spacing.screenGutter),
      child: Text(text, style: ShadTheme.of(context).textTheme.muted),
    );
  }
}

class SectionLoading extends StatelessWidget {
  const SectionLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: Spacing.screenGutter),
      child: Skeleton(height: 96, radius: Radii.card),
    );
  }
}

List<Widget> continueSection(
  MediaKindDto kind,
  List<ProgressDto> items,
  ValueChanged<ProgressDto> onOpen,
) {
  if (items.isEmpty) return const [];
  final cards = [for (final item in items) resumeCard(item)];
  return [
    SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.only(top: Spacing.xl),
        child: MediaRail(
          title: resumeTitle(kind),
          cards: cards,
          unitLabel: unitLabelFor(kind),
          progressOf: (card) => resumeFraction(items[cards.indexOf(card)]),
          onTap: (card) => onOpen(items[cards.indexOf(card)]),
        ),
      ),
    ),
  ];
}

List<Widget> favoritesSection(
  MediaKindDto kind,
  List<FavoriteDto> items,
  ValueChanged<FavoriteDto> onOpen,
  ValueChanged<FavoriteDto> onRemove,
) {
  final cards = [for (final item in items) favoriteCard(item)];
  return [
    const SliverToBoxAdapter(child: SectionTitle(text: 'Favorit')),
    if (items.isEmpty)
      SliverToBoxAdapter(child: EmptyNote(text: emptyFavorites(kind)))
    else
      MediaGridSliver(
        cards: cards,
        unitLabel: unitLabelFor(kind),
        onTap: (card) => onOpen(items[cards.indexOf(card)]),
        onRemove: (card) => onRemove(items[cards.indexOf(card)]),
      ),
  ];
}

List<Widget> historySection(
  MediaKindDto kind,
  List<ProgressDto> items,
  int nowSecs,
  ValueChanged<ProgressDto> onOpen,
  ValueChanged<ProgressDto> onRemove,
  VoidCallback onClear,
) {
  return [
    SliverToBoxAdapter(
      child: SectionTitle(
        text: 'Riwayat',
        trailing: items.isEmpty
            ? null
            : ShadButton.ghost(
                key: const Key('clear-history'),
                onPressed: onClear,
                size: ShadButtonSize.sm,
                child: const Text('Hapus semua'),
              ),
      ),
    ),
    if (items.isEmpty)
      SliverToBoxAdapter(child: EmptyNote(text: emptyHistory(kind)))
    else
      SliverToBoxAdapter(
        child: HistoryBox(
          items: items,
          nowSecs: nowSecs,
          onOpen: onOpen,
          onRemove: onRemove,
        ),
      ),
  ];
}
