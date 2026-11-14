import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../core/theme/kolektaku_tokens.dart';
import 'option_chip.dart';

class ActiveFilter {
  const ActiveFilter({required this.label, required this.onRemove});

  final String label;
  final VoidCallback onRemove;
}

class FilterBar extends StatelessWidget {
  const FilterBar({super.key, required this.onOpen, required this.active});

  final VoidCallback onOpen;
  final List<ActiveFilter> active;

  @override
  Widget build(BuildContext context) {
    final count = active.length;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Spacing.screenGutter,
        0,
        0,
        Spacing.md,
      ),
      child: Row(
        spacing: Spacing.sm,
        children: [
          ShadButton.outline(
            key: const Key('open-filters'),
            onPressed: onOpen,
            leading: const Icon(LucideIcons.slidersHorizontal, size: 16),
            child: Text(count == 0 ? 'Filter' : 'Filter ($count)'),
          ),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.only(right: Spacing.screenGutter),
              child: Row(
                spacing: Spacing.sm,
                children: [
                  for (final filter in active)
                    OptionChip(
                      key: Key('active-${filter.label}'),
                      label: filter.label,
                      selected: true,
                      trailing: LucideIcons.x,
                      onTap: filter.onRemove,
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
