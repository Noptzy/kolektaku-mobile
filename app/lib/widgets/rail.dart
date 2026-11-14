import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../core/theme/kolektaku_text.dart';
import '../core/theme/kolektaku_tokens.dart';

class Rail extends StatelessWidget {
  const Rail({
    super.key,
    required this.title,
    required this.height,
    required this.itemCount,
    required this.itemBuilder,
    this.trailing,
  });

  final String title;
  final double height;
  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: Spacing.screenGutter),
          child: Row(
            children: [
              Expanded(child: Text(title, style: theme.textTheme.sectionTitle)),
              ?trailing,
            ],
          ),
        ),
        const SizedBox(height: Spacing.md),
        SizedBox(
          height: height,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(
              horizontal: Spacing.screenGutter,
            ),
            itemCount: itemCount,
            separatorBuilder: (context, index) =>
                const SizedBox(width: Spacing.md),
            itemBuilder: itemBuilder,
          ),
        ),
      ],
    );
  }
}
