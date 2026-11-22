import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../core/theme/kolektaku_tokens.dart';
import '../../data/providers/haptics_provider.dart';

const historySwipeThreshold = 104.0;
const _fallbackFraction = 0.4;
const _minFraction = 0.05;
const _maxFraction = 0.9;

double swipeFraction(double width) {
  if (!width.isFinite || width <= 0) return _fallbackFraction;
  return (historySwipeThreshold / width).clamp(_minFraction, _maxFraction);
}

class HistorySwipe extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final haptics = ref.watch(hapticsProvider);
    return LayoutBuilder(
      builder: (context, constraints) {
        final fraction = swipeFraction(constraints.maxWidth);
        return Dismissible(
          key: ValueKey('history-swipe-$id'),
          dismissThresholds: {
            DismissDirection.startToEnd: fraction,
            DismissDirection.endToStart: fraction,
          },
          onUpdate: (details) {
            if (details.reached && !details.previousReached) {
              haptics.selection();
            }
          },
          onDismissed: (_) {
            haptics.light();
            onRemoved();
          },
          background: const _RemoveBackground(alignment: Alignment.centerLeft),
          secondaryBackground: const _RemoveBackground(
            alignment: Alignment.centerRight,
          ),
          direction: DismissDirection.horizontal,
          child: child,
        );
      },
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
