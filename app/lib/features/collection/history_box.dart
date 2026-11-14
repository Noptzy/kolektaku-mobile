import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../core/theme/kolektaku_tokens.dart';
import '../../src/rust/dto/library.dart';
import 'collection_logic.dart';
import 'history_row.dart';

const historyInlineLimit = 10;
const historyVisibleRows = 5.5;

double historyBoxHeight(int count) => count <= historyInlineLimit
    ? count * historyRowHeight
    : historyVisibleRows * historyRowHeight;

class HistoryBox extends StatelessWidget {
  const HistoryBox({
    super.key,
    required this.items,
    required this.nowSecs,
    required this.onOpen,
    required this.onRemove,
  });

  final List<ProgressDto> items;
  final int nowSecs;
  final ValueChanged<ProgressDto> onOpen;
  final ValueChanged<ProgressDto> onRemove;

  @override
  Widget build(BuildContext context) {
    final scheme = ShadTheme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Spacing.screenGutter),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: scheme.card,
          borderRadius: Radii.cardShape,
          border: Border.all(color: scheme.border),
        ),
        child: ClipRRect(
          borderRadius: Radii.cardShape,
          child: SizedBox(
            key: const Key('history-box'),
            height: historyBoxHeight(items.length),
            child: ListView.builder(
              physics: items.length <= historyInlineLimit
                  ? const NeverScrollableScrollPhysics()
                  : const ClampingScrollPhysics(),
              padding: EdgeInsets.zero,
              itemCount: items.length,
              itemExtent: historyRowHeight,
              itemBuilder: (context, index) {
                final item = items[index];
                return HistoryRow(
                  key: ValueKey(historyKey(item)),
                  progress: item,
                  nowSecs: nowSecs,
                  onOpen: () => onOpen(item),
                  onRemove: () => onRemove(item),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
