import 'package:flutter/widgets.dart';

import '../../src/rust/dto/sources.dart';
import '../detail/episode_window.dart' show unitAfter;
import '../reader/chapter_divider.dart';
import '../reader/reader_bars.dart';
import 'novel_controller.dart';

Widget novelDivider(NovelController controller, int chapter) {
  final stack = controller.chapters;
  final after = chapter < stack.length - 1
      ? unitAfter(controller.units, stack[chapter].unit.number)
      : controller.afterStack;
  return ChapterDivider(
    current: stack[chapter].unit.number,
    next: after,
    kind: controller.dividerKind(chapter),
    onContinue: () => controller.extend(manual: true),
    onRetry: () => controller.extend(manual: true),
  );
}

String? translationCaption(NovelController controller) {
  if (!controller.hasTranslation) return null;
  return controller.showOriginal ? 'Teks asli' : 'Diterjemahkan otomatis';
}

class BarFade extends StatelessWidget {
  const BarFade({
    super.key,
    required this.top,
    required this.visible,
    required this.child,
  });

  final bool top;
  final bool visible;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top ? 0 : null,
      bottom: top ? null : 0,
      left: 0,
      right: 0,
      child: AnimatedOpacity(
        opacity: visible ? 1 : 0,
        duration: const Duration(milliseconds: 200),
        child: IgnorePointer(ignoring: !visible, child: child),
      ),
    );
  }
}

class NovelBottomBar extends StatelessWidget {
  const NovelBottomBar({super.key, required this.controller, required this.go});

  final NovelController controller;
  final ValueChanged<UnitDto?> go;

  @override
  Widget build(BuildContext context) {
    return ReaderBottomBar(
      page: controller.block,
      total: controller.total,
      onPrevious: controller.previous == null
          ? null
          : () => go(controller.previous),
      onNext: controller.next == null ? null : () => go(controller.next),
    );
  }
}
