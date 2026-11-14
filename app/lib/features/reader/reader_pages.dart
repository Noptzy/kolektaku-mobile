import 'package:flutter/widgets.dart';

import '../../src/rust/dto/sources.dart';
import '../../src/rust/dto/stream.dart';
import '../../widgets/poster.dart';
import 'chapter_end.dart';
import 'page_image.dart';
import 'page_heights.dart';

const readerCacheExtent = 1600.0;

class ReaderPages extends StatelessWidget {
  const ReaderPages({
    super.key,
    required this.view,
    required this.scroll,
    required this.metrics,
    required this.imageFor,
    required this.next,
    required this.onAspect,
    required this.onNext,
    required this.onTap,
    required this.onScroll,
  });

  final ChapterViewDto view;
  final ScrollController scroll;
  final PageHeights metrics;
  final PageImageFactory imageFor;
  final UnitDto? next;
  final void Function(int index, double aspect) onAspect;
  final VoidCallback onNext;
  final VoidCallback onTap;
  final bool Function(ScrollNotification notification) onScroll;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final ratio = MediaQuery.devicePixelRatioOf(context);
    final decode = decodeWidth(width, ratio);
    return NotificationListener<ScrollNotification>(
      onNotification: onScroll,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: ListView.builder(
          key: ValueKey(view),
          controller: scroll,
          cacheExtent: readerCacheExtent,
          itemCount: view.pages.length + 1,
          itemBuilder: (context, index) {
            if (index == view.pages.length) {
              return ChapterEnd(
                current: view.unit.number,
                next: next,
                onNext: onNext,
              );
            }
            return PageImage(
              key: ValueKey('${view.unit.id}#$index'),
              provider: imageFor(view.pages[index], decode),
              aspect: metrics.aspectOf(index),
              onAspect: (aspect) => onAspect(index, aspect),
            );
          },
        ),
      ),
    );
  }
}
