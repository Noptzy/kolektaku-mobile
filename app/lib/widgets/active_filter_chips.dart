import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart' show LucideIcons;

import '../core/theme/kolektaku_tokens.dart';
import 'filter_bar.dart';
import 'option_chip.dart';

class ActiveFilterChips extends StatelessWidget {
  const ActiveFilterChips({super.key, required this.active});

  final List<ActiveFilter> active;

  @override
  Widget build(BuildContext context) {
    if (active.isEmpty) return const SizedBox.shrink();
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(
        Spacing.screenGutter,
        0,
        Spacing.screenGutter,
        Spacing.md,
      ),
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
    );
  }
}
