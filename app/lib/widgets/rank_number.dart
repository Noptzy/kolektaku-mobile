import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../core/theme/kolektaku_text.dart';

class RankNumber extends StatelessWidget {
  const RankNumber({super.key, required this.rank});

  final int rank;

  static double widthFor(int rank) => rank.toString().length * 58.0;

  static bool isTop(int rank) => rank == 1;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final color = isTop(rank)
        ? theme.colorScheme.primary
        : theme.colorScheme.foreground.withValues(alpha: 0.9);
    return ExcludeSemantics(
      child: Text('$rank', style: theme.textTheme.rank.copyWith(color: color)),
    );
  }
}
