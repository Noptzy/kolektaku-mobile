import 'package:flutter/widgets.dart';

class ClipRadius extends StatelessWidget {
  const ClipRadius({super.key, required this.radius, required this.child});

  final double radius;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(borderRadius: BorderRadius.circular(radius), child: child);
  }
}
