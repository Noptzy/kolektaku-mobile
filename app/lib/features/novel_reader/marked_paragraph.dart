import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart'
    show AdaptiveTextSelectionToolbar, SelectionArea;
import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import 'highlight_ranges.dart';

typedef HighlightPicked = void Function(int start, int end, String quote);

class MarkedParagraph extends StatefulWidget {
  const MarkedParagraph({
    super.key,
    required this.text,
    required this.style,
    this.marks = const [],
    this.onHighlight,
    this.onTapMark,
  });

  final String text;
  final TextStyle style;
  final List<Marked> marks;
  final HighlightPicked? onHighlight;
  final ValueChanged<int>? onTapMark;

  @override
  State<MarkedParagraph> createState() => _MarkedParagraphState();
}

class _MarkedParagraphState extends State<MarkedParagraph> {
  final List<TapGestureRecognizer> _taps = [];
  final ValueNotifier<String> _selected = ValueNotifier('');

  void _dropTaps() {
    for (final tap in _taps) {
      tap.dispose();
    }
    _taps.clear();
  }

  @override
  void dispose() {
    _dropTaps();
    _selected.dispose();
    super.dispose();
  }

  void _highlight() {
    final range = rangeOfSelection(widget.text, _selected.value);
    if (range == null) return;
    widget.onHighlight?.call(range.start, range.end, _selected.value.trim());
  }

  Widget _toolbar(BuildContext context, SelectableRegionState state) {
    return ValueListenableBuilder<String>(
      valueListenable: _selected,
      builder: (context, selected, child) {
        final items = [...state.contextMenuButtonItems];
        if (widget.onHighlight != null && isHighlightable(selected)) {
          items.insert(
            0,
            ContextMenuButtonItem(
              label: 'Sorot',
              onPressed: () {
                _highlight();
                state.hideToolbar();
              },
            ),
          );
        }
        return AdaptiveTextSelectionToolbar.buttonItems(
          anchors: state.contextMenuAnchors,
          buttonItems: items,
        );
      },
    );
  }

  TextSpan _spans(Color mark) {
    _dropTaps();
    final children = <InlineSpan>[];
    for (final piece in segmentsOf(widget.text, widget.marks)) {
      final text = widget.text.substring(piece.start, piece.end);
      final id = piece.highlightId;
      if (id == null) {
        children.add(TextSpan(text: text));
        continue;
      }
      final tap = TapGestureRecognizer()
        ..onTap = () => widget.onTapMark?.call(id);
      _taps.add(tap);
      children.add(
        TextSpan(
          text: text,
          recognizer: tap,
          style: TextStyle(backgroundColor: mark),
        ),
      );
    }
    return TextSpan(children: children);
  }

  @override
  Widget build(BuildContext context) {
    final accent = ShadTheme.of(context).colorScheme.primary;
    return SelectionArea(
      onSelectionChanged: (content) =>
          _selected.value = content?.plainText ?? '',
      contextMenuBuilder: _toolbar,
      child: Text.rich(
        _spans(accent.withValues(alpha: 0.35)),
        key: const Key('marked-paragraph'),
        style: widget.style,
      ),
    );
  }
}
