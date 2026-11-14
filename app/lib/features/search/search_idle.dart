import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../core/theme/kolektaku_text.dart';
import '../../core/theme/kolektaku_tokens.dart';
import '../../widgets/pressable.dart';

class SearchIdle extends StatelessWidget {
  const SearchIdle({
    super.key,
    required this.recent,
    required this.suggestions,
    required this.onPick,
    required this.onClear,
  });

  final List<String> recent;
  final List<String> suggestions;
  final ValueChanged<String> onPick;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Spacing.screenGutter),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: Spacing.lg,
        children: [
          if (recent.isNotEmpty) ...[
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Pencarian terakhir',
                    style: theme.textTheme.sectionTitle,
                  ),
                ),
                ShadButton.ghost(
                  onPressed: onClear,
                  size: ShadButtonSize.sm,
                  child: const Text('Hapus semua'),
                ),
              ],
            ),
            _Tags(items: recent, onPick: onPick, icon: LucideIcons.history),
          ],
          if (suggestions.isNotEmpty) ...[
            Text('Coba cari', style: theme.textTheme.sectionTitle),
            _Tags(items: suggestions, onPick: onPick, icon: LucideIcons.search),
          ],
          if (recent.isEmpty && suggestions.isEmpty)
            Text(
              'Ketik judul untuk mulai mencari.',
              style: theme.textTheme.muted,
            ),
        ],
      ),
    );
  }
}

class _Tags extends StatelessWidget {
  const _Tags({required this.items, required this.onPick, required this.icon});

  final List<String> items;
  final ValueChanged<String> onPick;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final scheme = ShadTheme.of(context).colorScheme;
    return Wrap(
      spacing: Spacing.sm,
      runSpacing: Spacing.sm,
      children: [
        for (final item in items)
          Pressable(
            onTap: () => onPick(item),
            label: item,
            minSize: 40,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: scheme.card,
                borderRadius: Radii.chipShape,
                border: Border.all(color: scheme.border),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: Spacing.md,
                  vertical: Spacing.sm,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, size: 14, color: scheme.mutedForeground),
                    const SizedBox(width: Spacing.xs + 2),
                    Flexible(
                      child: Text(
                        item,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
