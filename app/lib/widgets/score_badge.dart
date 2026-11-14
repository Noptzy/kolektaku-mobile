import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../core/theme/kolektaku_color_scheme.dart';
import '../core/theme/kolektaku_text.dart';

String scoreText(double score) => score.toStringAsFixed(1);

class ScoreBadge extends StatelessWidget {
  const ScoreBadge({super.key, required this.score});

  final double score;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return Semantics(
      label: 'Skor ${scoreText(score)}',
      excludeSemantics: true,
      child: ShadBadge(
        backgroundColor: theme.colorScheme.score,
        foregroundColor: theme.colorScheme.onScore,
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        child: Text(scoreText(score), style: theme.textTheme.badge),
      ),
    );
  }
}
