import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../core/labels.dart';
import '../../core/theme/kolektaku_text.dart';
import '../../core/theme/kolektaku_tokens.dart';
import '../../src/rust/dto/cards.dart';
import '../../src/rust/dto/credits.dart';
import '../../src/rust/dto/media.dart';
import '../../widgets/media_grid.dart';
import '../../widgets/summary_card.dart';

MediaSummaryDto? adaptationOf(
  List<RelationDto> relations,
  MediaKindDto wanted,
) {
  for (final relation in relations) {
    if (relation.relationType.toUpperCase() == 'ADAPTATION' &&
        relation.media.kind == wanted) {
      return relation.media;
    }
  }
  return null;
}

MediaSummaryDto? novelOf(List<RelationDto> relations) {
  for (final relation in relations) {
    final type = relation.relationType.toUpperCase();
    final linked = type == 'ADAPTATION' || type == 'SOURCE';
    if (linked && relation.media.kind == MediaKindDto.novel) {
      return relation.media;
    }
  }
  return null;
}

class RelatedSection extends StatelessWidget {
  const RelatedSection({
    super.key,
    required this.relations,
    required this.recommendations,
    required this.onOpen,
  });

  final List<RelationDto> relations;
  final List<MediaSummaryDto> recommendations;
  final void Function(MediaSummaryDto summary) onOpen;

  @override
  Widget build(BuildContext context) {
    if (relations.isEmpty && recommendations.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(Spacing.xl),
          child: Text(
            'Belum ada judul terkait.',
            style: ShadTheme.of(context).textTheme.muted,
          ),
        ),
      );
    }
    final tags = {
      for (final relation in relations)
        relation.media.id: relationLabel(relation.relationType),
    };
    return SliverMainAxisGroup(
      slivers: [
        if (relations.isNotEmpty) ...[
          _title(context, 'Terkait'),
          MediaGridSliver(
            cards: [for (final item in relations) cardFromSummary(item.media)],
            tagOf: (card) => tags[card.reference.id],
            onTap: (MediaCardDto card) => onOpen(
              relations
                  .firstWhere((item) => item.media.id == card.reference.id)
                  .media,
            ),
          ),
        ],
        if (recommendations.isNotEmpty) ...[
          _title(context, 'Mungkin kamu suka'),
          MediaGridSliver(
            cards: [for (final item in recommendations) cardFromSummary(item)],
            onTap: (MediaCardDto card) => onOpen(
              recommendations.firstWhere(
                (item) => item.id == card.reference.id,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _title(BuildContext context, String text) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          Spacing.screenGutter,
          Spacing.lg,
          Spacing.screenGutter,
          Spacing.md,
        ),
        child: Text(text, style: ShadTheme.of(context).textTheme.sectionTitle),
      ),
    );
  }
}
