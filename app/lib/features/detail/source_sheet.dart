import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../core/theme/kolektaku_tokens.dart';
import '../../src/rust/dto/sources.dart';
import '../../widgets/pressable.dart';
import 'source_names.dart';

String linkSubtitle(SourceLinkDto link) {
  final parts = <String>[
    if (link.unitCount != null) '${link.unitCount} episode',
    if (link.manual)
      'dipilih manual'
    else
      'kecocokan ${(link.confidence * 100).round()}%',
  ];
  return parts.join(' · ');
}

String sourceName(int index) => 'Sumber ${index + 1}';

Future<String?> showSourceSheet(
  BuildContext context, {
  required List<SourceLinkDto> links,
  required String? current,
  SourceNames? names,
}) {
  return showShadSheet<String>(
    context: context,
    side: ShadSheetSide.bottom,
    builder: (sheetContext) => ShadSheet(
      title: const Text('Pilih sumber'),
      description: const Text('Daftar episode mengikuti sumber yang dipilih.'),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: Spacing.md),
        child: Column(
          children: [
            for (var i = 0; i < links.length; i++)
              _Row(
                label: names?.labels[links[i].source] ?? sourceName(i),
                summary: names?.summaries[links[i].source],
                link: links[i],
                selected: links[i].source == current,
                onTap: () => Navigator.of(sheetContext).pop(links[i].source),
              ),
          ],
        ),
      ),
    ),
  );
}

class _Row extends StatelessWidget {
  const _Row({
    required this.label,
    required this.link,
    required this.selected,
    required this.onTap,
    this.summary,
  });

  final String label;
  final String? summary;

  final SourceLinkDto link;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return Pressable(
      onTap: onTap,
      selected: selected,
      minSize: Sizes.touchTarget,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: Spacing.sm),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: theme.textTheme.p.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(linkSubtitle(link), style: theme.textTheme.muted),
                  if (summary != null)
                    Text(
                      summary!,
                      key: Key('source-summary-${link.source}'),
                      style: theme.textTheme.small.copyWith(
                        color: theme.colorScheme.primary,
                      ),
                    ),
                ],
              ),
            ),
            if (selected)
              Icon(
                LucideIcons.check,
                size: 20,
                color: theme.colorScheme.primary,
              ),
          ],
        ),
      ),
    );
  }
}
