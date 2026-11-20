import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../core/theme/kolektaku_tokens.dart';

class HistorySwipe extends StatelessWidget {
  const HistorySwipe({
    super.key,
    required this.id,
    required this.onRemoved,
    required this.child,
  });

  final String id;
  final VoidCallback onRemoved;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey('history-swipe-$id'),
      onDismissed: (_) => onRemoved(),
      background: const _RemoveBackground(alignment: Alignment.centerLeft),
      secondaryBackground: const _RemoveBackground(
        alignment: Alignment.centerRight,
      ),
      direction: DismissDirection.horizontal,
      child: child,
    );
  }
}

class _RemoveBackground extends StatelessWidget {
  const _RemoveBackground({required this.alignment});

  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    final scheme = ShadTheme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Spacing.xs),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: scheme.destructive,
          borderRadius: BorderRadius.circular(Radii.poster),
        ),
        child: Align(
          alignment: alignment,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: Spacing.xl),
            child: Icon(
              LucideIcons.trash2,
              color: scheme.destructiveForeground,
              semanticLabel: 'Hapus dari riwayat',
            ),
          ),
        ),
      ),
    );
  }
}
