import 'package:flutter/widgets.dart';

class Pressable extends StatelessWidget {
  const Pressable({
    super.key,
    required this.onTap,
    required this.child,
    this.label,
    this.minSize = 0,
    this.selected,
  });

  final VoidCallback? onTap;
  final Widget child;
  final String? label;
  final double minSize;
  final bool? selected;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: onTap != null,
      label: label,
      selected: selected,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: ConstrainedBox(
          constraints: BoxConstraints(minWidth: minSize, minHeight: minSize),
          child: child,
        ),
      ),
    );
  }
}
