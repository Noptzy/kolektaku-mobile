import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../core/theme/glass_tokens.dart';
import '../core/theme/kolektaku_tokens.dart';
import 'dock_indicator.dart';
import 'glass_surface.dart';
import 'pop_icon.dart';
import 'pressable.dart';

class BottomDestination {
  const BottomDestination({
    required this.label,
    required this.icon,
    this.spin = false,
  });

  final String label;
  final IconData icon;
  final bool spin;
}

class FloatingDock extends StatelessWidget {
  const FloatingDock({
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
    return GlassSurface(
      radius: BorderRadius.circular(DockMetrics.radius),
      child: SizedBox(
        height: DockMetrics.height,
        child: Padding(
          padding: const EdgeInsets.all(DockMetrics.itemPadding),
          child: Stack(
            children: [
              Positioned.fill(
                child: DockIndicator(
                  index: currentIndex,
                  count: destinations.length,
                ),
              ),
              Row(
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
        : theme.colorScheme.foreground.withValues(alpha: 0.78);
    return Pressable(
      onTap: onTap,
      selected: selected,
      minSize: Sizes.touchTarget,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          PopIcon(
            icon: destination.icon,
            color: color,
            selected: selected,
            spin: destination.spin,
          ),
          const SizedBox(height: Spacing.xs),
          Text(
            destination.label,
            maxLines: 1,
            style: theme.textTheme.small.copyWith(
              color: color,
              fontSize: 11.5,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
