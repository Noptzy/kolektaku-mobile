import 'package:flutter/widgets.dart';

import '../core/theme/kolektaku_tokens.dart';
import '../src/rust/dto/cards.dart';
import 'media_card.dart';
import 'media_card_height.dart';
import 'rail.dart';

class MediaRail extends StatelessWidget {
  const MediaRail({
    super.key,
    required this.title,
    required this.cards,
    this.onTap,
    this.progressOf,
    this.newOnly = false,
    this.unitLabel = 'eps',
    this.cardWidth = Sizes.railPosterWidth,
    this.trailing,
  });

  final String title;
  final List<MediaCardDto> cards;
  final ValueChanged<MediaCardDto>? onTap;
  final double? Function(MediaCardDto card)? progressOf;
  final bool newOnly;
  final String unitLabel;
  final double cardWidth;
  final Widget? trailing;

  static double heightFor(double cardWidth, TextScaler scaler) =>
      mediaCardHeight(cardWidth, scaler);

  @override
  Widget build(BuildContext context) {
    return Rail(
      title: title,
      height: heightFor(cardWidth, MediaQuery.textScalerOf(context)),
      trailing: trailing,
      itemCount: cards.length,
      itemBuilder: (context, index) {
        final card = cards[index];
        return SizedBox(
          width: cardWidth,
          child: MediaCard(
            card: card,
            isNew: newOnly,
            unitLabel: unitLabel,
            progress: progressOf?.call(card),
            onTap: onTap == null ? null : () => onTap!(card),
          ),
        );
      },
    );
  }
}
