import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../core/theme/kolektaku_text.dart';

class OutlinedRank extends StatelessWidget {
  const OutlinedRank({super.key, required this.rank});

  final int rank;

  static double widthFor(int rank) => rank.toString().length * 58.0;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final outline = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..color = theme.colorScheme.foreground;
    return ExcludeSemantics(
      child: Text(
        '$rank',
        style: theme.textTheme.rank.copyWith(foreground: outline),
      ),
    );
  }
}
