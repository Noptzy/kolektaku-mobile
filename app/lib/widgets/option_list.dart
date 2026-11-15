import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../widgets/sheet_scroll.dart';

class OptionList<T> extends StatelessWidget {
  const OptionList({
    super.key,
    required this.options,
    required this.selected,
    required this.onPicked,
    this.footer = const [],
  });

  final List<(String, T)> options;
  final T selected;
  final ValueChanged<T> onPicked;
  final List<Widget> footer;

  @override
  Widget build(BuildContext context) {
    return SheetScroll(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (label, value) in options)
            ShadButton.ghost(
              key: Key('option-$label'),
              onPressed: () => onPicked(value),
              child: Flexible(
                child: Text(
                  value == selected ? '$label  •' : label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ...footer,
        ],
      ),
    );
  }
}
