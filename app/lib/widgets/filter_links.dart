import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../core/theme/kolektaku_tokens.dart';
import 'filter_sheet.dart';
import 'option_chip.dart';

class FilterLinkSection {
  const FilterLinkSection({
    required this.key,
    required this.title,
    required this.options,
    required this.onOpen,
    this.hint,
  });

  final String key;
  final String title;
  final String? hint;
  final List<FilterOption> options;
  final void Function(String id) onOpen;
}

class FilterLinkBlock extends StatelessWidget {
  const FilterLinkBlock({
    super.key,
    required this.section,
    required this.onPick,
  });

  final FilterLinkSection section;
  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: Spacing.sm,
      children: [
        Text(section.title, style: theme.textTheme.large),
        if (section.hint != null)
          Text(section.hint!, style: theme.textTheme.muted),
        Wrap(
          spacing: Spacing.sm,
          runSpacing: Spacing.sm,
          children: [
            for (final option in section.options)
              OptionChip(
                key: Key('${section.key}-${option.id}'),
                label: option.label,
                selected: false,
                trailing: LucideIcons.arrowUpRight,
                onTap: () => onPick(option.id),
              ),
          ],
        ),
      ],
    );
  }
}
