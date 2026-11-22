import 'package:flutter/widgets.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../core/theme/kolektaku_text.dart';
import 'score_badge.dart';

const _starSize = 11.0;
const _starGap = 4.0;

class ScoreMeta extends StatelessWidget {
  const ScoreMeta({super.key, required this.score, this.rest});

  final double score;
  final String? rest;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final scheme = theme.colorScheme;
    final muted = theme.textTheme.cardMeta.copyWith(
      color: scheme.mutedForeground,
    );
    final spoken = rest == null
        ? 'Skor ${scoreText(score)}'
        : 'Skor ${scoreText(score)}, $rest';
    return Semantics(
      label: spoken,
      excludeSemantics: true,
      child: Row(
        children: [
          FaIcon(
            FontAwesomeIcons.solidStar,
            size: _starSize,
            color: scheme.primary,
          ),
          const SizedBox(width: _starGap),
          Text(
            scoreText(score),
            maxLines: 1,
            style: muted.copyWith(
              color: scheme.foreground,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (rest != null)
            Flexible(
              child: Text(
                ' · $rest',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: muted,
              ),
            ),
        ],
      ),
    );
  }
}
