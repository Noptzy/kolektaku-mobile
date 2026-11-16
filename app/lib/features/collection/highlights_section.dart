import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../core/theme/kolektaku_tokens.dart';
import '../../src/rust/dto/highlight.dart';
import 'collection_sections.dart';

List<Widget> highlightsSection(
  List<HighlightDto> items,
  ValueChanged<HighlightDto> onOpen,
  ValueChanged<HighlightDto> onRemove,
) {
  return [
    const SliverToBoxAdapter(child: SectionTitle(text: 'Sorotan')),
    if (items.isEmpty)
      const SliverToBoxAdapter(
        child: EmptyNote(
          text: 'Belum ada sorotan. Tahan kata di novel lalu pilih Sorot.',
        ),
      )
    else
      SliverList.separated(
        itemCount: items.length,
        separatorBuilder: (context, index) =>
            const SizedBox(height: Spacing.md),
        itemBuilder: (context, index) => HighlightCard(
          item: items[index],
          onOpen: () => onOpen(items[index]),
          onRemove: () => onRemove(items[index]),
        ),
      ),
  ];
}

class HighlightCard extends StatelessWidget {
  const HighlightCard({
    super.key,
    required this.item,
    required this.onOpen,
    required this.onRemove,
  });

  final HighlightDto item;
  final VoidCallback onOpen;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Spacing.screenGutter),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onOpen,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                key: const Key('highlight-accent'),
                width: 3,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: Spacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.quote,
                      maxLines: 5,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.p,
                    ),
                    const SizedBox(height: Spacing.xs),
                    Text(
                      '${item.title}  ·  ${item.chapterLabel}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.muted,
                    ),
                  ],
                ),
              ),
              ShadIconButton.ghost(
                key: Key('remove-highlight-${item.id}'),
                icon: const Icon(LucideIcons.trash2),
                onPressed: onRemove,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
