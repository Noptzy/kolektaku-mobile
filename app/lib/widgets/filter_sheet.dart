import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../core/theme/kolektaku_tokens.dart';
import 'swipe_sheet.dart';
import 'filter_links.dart';
import 'option_chip.dart';

typedef FilterChoice = Map<String, String>;

class FilterOption {
  const FilterOption(this.id, this.label);

  final String id;
  final String label;
}

class FilterSection {
  const FilterSection({
    required this.key,
    required this.title,
    required this.options,
  });

  final String key;
  final String title;
  final List<FilterOption> options;
}

Future<FilterChoice?> showFilterSheet(
  BuildContext context, {
  required List<FilterSection> sections,
  required FilterChoice current,
  required FilterChoice initial,
  FilterLinkSection? links,
}) {
  return showSwipeSheet<FilterChoice>(
    context: context,
    builder: (sheetContext) => ShadSheet(
      title: const Text('Filter'),
      child: FilterSheetBody(
        sections: sections,
        current: current,
        initial: initial,
        links: links,
        onLink: (id) {
          Navigator.of(sheetContext).pop();
          links?.onOpen(id);
        },
        onApply: (choice) => Navigator.of(sheetContext).pop(choice),
      ),
    ),
  );
}

class FilterSheetBody extends StatefulWidget {
  const FilterSheetBody({
    super.key,
    required this.sections,
    required this.current,
    required this.initial,
    required this.onApply,
    this.links,
    this.onLink,
  });

  final FilterLinkSection? links;
  final ValueChanged<String>? onLink;
  final List<FilterSection> sections;
  final FilterChoice current;
  final FilterChoice initial;
  final ValueChanged<FilterChoice> onApply;

  @override
  State<FilterSheetBody> createState() => _FilterSheetBodyState();
}

class _FilterSheetBodyState extends State<FilterSheetBody> {
  late FilterChoice _draft = {...widget.initial, ...widget.current};

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.sizeOf(context).height;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Spacing.md),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: Spacing.lg,
        children: [
          ConstrainedBox(
            constraints: BoxConstraints(maxHeight: height * 0.55),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: Spacing.lg,
                children: [
                  for (final section in widget.sections)
                    _Section(
                      section: section,
                      selected: _draft[section.key],
                      onPick: (id) =>
                          setState(() => _draft = {..._draft, section.key: id}),
                    ),
                  if (widget.links != null && widget.onLink != null)
                    FilterLinkBlock(
                      section: widget.links!,
                      onPick: widget.onLink!,
                    ),
                ],
              ),
            ),
          ),
          Row(
            spacing: Spacing.md,
            children: [
              Expanded(
                child: ShadButton.outline(
                  key: const Key('filter-reset'),
                  onPressed: () => setState(() => _draft = {...widget.initial}),
                  child: const Flexible(
                    child: Text(
                      'Atur ulang',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: ShadButton(
                  key: const Key('filter-apply'),
                  onPressed: () => widget.onApply(_draft),
                  child: const Flexible(
                    child: Text(
                      'Terapkan',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.section,
    required this.selected,
    required this.onPick,
  });

  final FilterSection section;
  final String? selected;
  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: Spacing.sm,
      children: [
        Text(section.title, style: theme.textTheme.large),
        Wrap(
          spacing: Spacing.sm,
          runSpacing: Spacing.sm,
          children: [
            for (final option in section.options)
              OptionChip(
                key: Key('${section.key}-${option.id}'),
                label: option.label,
                selected: option.id == selected,
                onTap: () => onPick(option.id),
              ),
          ],
        ),
      ],
    );
  }
}
