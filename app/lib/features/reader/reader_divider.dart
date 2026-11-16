import 'package:flutter/widgets.dart';

import '../detail/episode_window.dart' show unitAfter;
import 'chapter_divider.dart';
import 'reader_controller.dart';

Widget readerDivider(ReaderController controller, int chapter) {
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
