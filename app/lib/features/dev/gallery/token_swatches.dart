import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../core/theme/kolektaku_color_scheme.dart';
import '../../../core/theme/kolektaku_text.dart';
import '../../../core/theme/kolektaku_tokens.dart';

class TokenSwatches extends StatelessWidget {
  const TokenSwatches({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = ShadTheme.of(context).colorScheme;
    final swatches = <String, Color>{
      'latar': scheme.background,
      'permukaan': scheme.card,
      'permukaan 2': scheme.popover,
      'garis': scheme.border,
      'teks': scheme.foreground,
      'teks redup': scheme.mutedForeground,
      'utama': scheme.primary,
      'favorit': scheme.favorite,
      'skor': scheme.score,
      'bahaya': scheme.destructive,
    };
    return Wrap(
      spacing: Spacing.sm,
      runSpacing: Spacing.sm,
      children: [
        for (final entry in swatches.entries)
          _Swatch(name: entry.key, color: entry.value),
      ],
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch({required this.name, required this.color});

  final String name;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return SizedBox(
      width: 96,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: color,
              borderRadius: Radii.posterShape,
              border: Border.all(color: theme.colorScheme.border),
            ),
            child: const SizedBox(height: 48, width: 96),
          ),
          const SizedBox(height: Spacing.xs),
          Text(name, style: theme.textTheme.cardMeta),
        ],
      ),
    );
  }
}
