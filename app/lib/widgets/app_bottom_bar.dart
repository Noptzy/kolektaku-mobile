import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../core/theme/kolektaku_tokens.dart';
import 'pressable.dart';

class BottomDestination {
  const BottomDestination({required this.label, required this.icon});

  final String label;
  final IconData icon;
}

class AppBottomBar extends StatelessWidget {
  const AppBottomBar({
    super.key,
    required this.destinations,
    required this.currentIndex,
    required this.onSelected,
  });

  final List<BottomDestination> destinations;
  final int currentIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final scheme = ShadTheme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.background,
        border: Border(top: BorderSide(color: scheme.border)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: Sizes.bottomBarHeight,
          child: Row(
            children: [
              for (var i = 0; i < destinations.length; i++)
                Expanded(
                  child: _Item(
                    destination: destinations[i],
                    selected: i == currentIndex,
                    onTap: () => onSelected(i),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Item extends StatelessWidget {
  const _Item({
    required this.destination,
    required this.selected,
    required this.onTap,
  });

  final BottomDestination destination;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final color = selected
        ? theme.colorScheme.primary
        : theme.colorScheme.mutedForeground;
    return Pressable(
      onTap: onTap,
      selected: selected,
      minSize: Sizes.touchTarget,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(destination.icon, size: 22, color: color),
          const SizedBox(height: Spacing.xs),
          Text(
            destination.label,
            style: theme.textTheme.small.copyWith(
              color: color,
              fontSize: 12,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
