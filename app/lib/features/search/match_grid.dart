import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../core/theme/kolektaku_text.dart';
import '../../core/theme/kolektaku_tokens.dart';
import '../../src/rust/dto/cards.dart';
import '../../widgets/media_card.dart';
import '../../widgets/media_card_height.dart';

const matchColumns = 3;

class MatchGrid extends StatelessWidget {
  const MatchGrid({
    super.key,
    required this.title,
    required this.cards,
    required this.onTap,
    required this.onSeeAll,
  });

  final String title;
  final List<MediaCardDto> cards;
  final ValueChanged<MediaCardDto> onTap;
  final VoidCallback onSeeAll;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Spacing.screenGutter,
        Spacing.sm,
        Spacing.screenGutter,
        Spacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: Spacing.sm,
        children: [
          Row(
            children: [
              Expanded(child: Text(title, style: theme.textTheme.sectionTitle)),
              ShadButton.ghost(
                key: Key('see-all-$title'),
                size: ShadButtonSize.sm,
                onPressed: onSeeAll,
                child: const Text('Lihat semua'),
              ),
            ],
          ),
          LayoutBuilder(
            builder: (context, constraints) {
              final gaps = Spacing.md * (matchColumns - 1);
              final width = (constraints.maxWidth - gaps) / matchColumns;
              final height = mediaCardHeight(
                width,
                MediaQuery.textScalerOf(context),
              );
              return Wrap(
                spacing: Spacing.md,
                runSpacing: Spacing.lg,
                children: [
                  for (final card in cards)
                    SizedBox(
                      width: width,
                      height: height,
                      child: MediaCard(card: card, onTap: () => onTap(card)),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
