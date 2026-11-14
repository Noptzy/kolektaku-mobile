import 'package:flutter/widgets.dart';

const _maxHeightFraction = 0.6;

class SheetScroll extends StatelessWidget {
  const SheetScroll({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * _maxHeightFraction,
      ),
      child: SingleChildScrollView(child: child),
    );
  }
}
