import 'package:flutter/widgets.dart';

import '../../src/rust/dto/stream.dart';
import '../../widgets/poster.dart';
import 'page_image.dart';
import 'stack_metrics.dart';

const readerCacheExtent = 1600.0;

typedef DividerBuilder = Widget Function(int chapter);

class ReaderPages extends StatelessWidget {
  const ReaderPages({
    super.key,
    required this.chapters,
    required this.scroll,
    required this.metrics,
    required this.imageFor,
    required this.dividerAt,
    required this.onAspect,
    required this.onTap,
    required this.onScroll,
    this.decodeScale = 1,
    this.physics,
  });

  final List<ChapterViewDto> chapters;
  final ScrollController scroll;
  final StackMetrics metrics;
  final PageImageFactory imageFor;
  final DividerBuilder dividerAt;
  final void Function(int chapter, int index, double aspect) onAspect;
  final VoidCallback onTap;
  final bool Function(ScrollNotification notification) onScroll;
  final double decodeScale;
  final ScrollPhysics? physics;

  int get _count =>
      chapters.fold(0, (sum, chapter) => sum + chapter.pages.length + 1);

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.sizeOf(context).width;
    final ratio = MediaQuery.devicePixelRatioOf(context);
    final decode = decodeWidth(screen * decodeScale, ratio);
    return NotificationListener<ScrollNotification>(
      onNotification: onScroll,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: ListView.builder(
          key: ValueKey(chapters.first),
          controller: scroll,
          physics: physics,
          cacheExtent: readerCacheExtent,
          itemCount: _count,
          itemBuilder: (context, flat) {
            var left = flat;
            for (var chapter = 0; chapter < chapters.length; chapter++) {
              final view = chapters[chapter];
              if (left < view.pages.length) {
                final index = left;
                return PageImage(
                  key: ValueKey('${view.unit.id}#$index'),
                  provider: imageFor(view.pages[index], decode),
                  aspect: metrics.heightsOf(chapter).aspectOf(index),
                  onAspect: (aspect) => onAspect(chapter, index, aspect),
                );
              }
              if (left == view.pages.length) return dividerAt(chapter);
              left -= view.pages.length + 1;
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }
}
