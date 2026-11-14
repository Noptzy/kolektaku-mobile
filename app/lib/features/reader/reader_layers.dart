import 'package:flutter/widgets.dart';

import 'reader_bars.dart';

class ReaderLayers extends StatelessWidget {
  const ReaderLayers({
    super.key,
    required this.pages,
    required this.title,
    required this.barsVisible,
    required this.page,
    required this.total,
    required this.onBack,
    this.onChapters,
    this.onPrevious,
    this.onNext,
  });

  final Widget pages;
  final String title;
  final bool barsVisible;
  final int page;
  final int total;
  final VoidCallback onBack;
  final VoidCallback? onChapters;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        pages,
        _bar(
          top: true,
          child: ReaderTopBar(
            title: title,
            onBack: onBack,
            onChapters: onChapters,
          ),
        ),
        _bar(
          top: false,
          child: ReaderBottomBar(
            page: page,
            total: total,
            onPrevious: onPrevious,
            onNext: onNext,
          ),
        ),
      ],
    );
  }

  Widget _bar({required bool top, required Widget child}) {
    return Positioned(
      top: top ? 0 : null,
      bottom: top ? null : 0,
      left: 0,
      right: 0,
      child: AnimatedOpacity(
        opacity: barsVisible ? 1 : 0,
        duration: const Duration(milliseconds: 200),
        child: IgnorePointer(ignoring: !barsVisible, child: child),
      ),
    );
  }
}
