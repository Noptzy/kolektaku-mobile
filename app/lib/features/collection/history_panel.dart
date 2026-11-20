import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../core/theme/kolektaku_tokens.dart';
import '../../src/rust/dto/library.dart';
import '../../src/rust/dto/media.dart';
import 'collection_sections.dart';
import 'history_logic.dart';
import 'history_row.dart';
import 'history_swipe.dart';

class HistoryPanel extends StatefulWidget {
  const HistoryPanel({
    super.key,
    required this.kind,
    required this.items,
    required this.onOpen,
    required this.onRemove,
  });

  final MediaKindDto kind;
  final List<ProgressDto> items;
  final ValueChanged<ProgressDto> onOpen;
  final ValueChanged<ProgressDto> onRemove;

  @override
  State<HistoryPanel> createState() => _HistoryPanelState();
}

class _HistoryPanelState extends State<HistoryPanel> {
  final _query = TextEditingController();
  final _scroll = ScrollController();
  final Set<String> _removed = {};

  @override
  void didUpdateWidget(HistoryPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.items != widget.items) _removed.clear();
    if (oldWidget.kind != widget.kind) _query.clear();
  }

  @override
  void dispose() {
    _query.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _remove(ProgressDto item) {
    setState(() => _removed.add(historyKey(item)));
    widget.onRemove(item);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Spacing.screenGutter),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: Spacing.md,
        children: [
          ShadInput(
            key: const Key('history-search'),
            controller: _query,
            placeholder: Text(historySearchHint(widget.kind)),
            leading: const Icon(LucideIcons.search, size: 18),
            textInputAction: TextInputAction.search,
            onChanged: (_) => setState(() {}),
          ),
          _list(context),
        ],
      ),
    );
  }

  Widget _list(BuildContext context) {
    final visible = filterHistory([
      for (final item in widget.items)
        if (!_removed.contains(historyKey(item))) item,
    ], _query.text);
    if (visible.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(bottom: Spacing.sm),
        child: EmptyNote(
          text: historyNoMatch(_query.text.trim()),
          inset: false,
        ),
      );
    }
    final height =
        historyRowHeight *
        visible.length.clamp(1, historyVisibleRows).toDouble();
    return SizedBox(
      key: const Key('history-list'),
      height: height,
      child: RawScrollbar(
        controller: _scroll,
        thumbColor: ShadTheme.of(context).colorScheme.mutedForeground,
        radius: const Radius.circular(Radii.chip),
        thickness: 3,
        padding: EdgeInsets.zero,
        child: ListView.builder(
          controller: _scroll,
          padding: const EdgeInsets.only(right: Spacing.md),
          itemCount: visible.length,
          itemExtent: historyRowHeight,
          itemBuilder: (context, index) => _row(visible[index]),
        ),
      ),
    );
  }

  Widget _row(ProgressDto item) {
    final id = historyKey(item);
    return HistorySwipe(
      key: ValueKey(id),
      id: id,
      onRemoved: () => _remove(item),
      child: HistoryRow(
        key: Key('history-row-$id'),
        item: item,
        onTap: () => widget.onOpen(item),
      ),
    );
  }
}
