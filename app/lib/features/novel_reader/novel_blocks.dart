import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../core/theme/kolektaku_tokens.dart';
import '../../src/rust/dto/novel.dart';
import '../../src/rust/dto/settings.dart';
import 'highlight_ranges.dart';
import 'illustration_view.dart';
import 'marked_paragraph.dart';
import 'reading_look.dart';

typedef NovelImageFactory = ImageProvider Function(String url);

ImageProvider networkIllustration(String url) => NetworkImage(url);

class NovelBlock extends StatelessWidget {
  const NovelBlock({
    super.key,
    required this.block,
    required this.size,
    required this.spacing,
    this.imageFor = networkIllustration,
    this.marks = const [],
    this.onHighlight,
    this.onTapMark,
  });

  final NovelBlockDto block;
  final ReadingSizeDto size;
  final ReadingSpacingDto spacing;
  final NovelImageFactory imageFor;
  final List<Marked> marks;
  final HighlightPicked? onHighlight;
  final ValueChanged<int>? onTapMark;

  @override
  Widget build(BuildContext context) {
    final style = paragraphStyle(
      ShadTheme.of(context).textTheme.p,
      size,
      spacing,
    );
    return Padding(
      padding: EdgeInsets.fromLTRB(
        Spacing.screenGutter,
        0,
        Spacing.screenGutter,
        fontSizeOf(size) * 0.9,
      ),
      child: block.isImage
          ? GestureDetector(
              key: const Key('illustration'),
              onTap: () => showIllustration(context, imageFor(block.text)),
              child: Image(
                image: imageFor(block.text),
                fit: BoxFit.fitWidth,
                errorBuilder: (context, error, stack) => Text(
                  'Gambar tidak bisa dimuat.',
                  style: ShadTheme.of(context).textTheme.muted,
                ),
              ),
            )
          : MarkedParagraph(
              text: block.text,
              style: style,
              marks: marks,
              onHighlight: onHighlight,
              onTapMark: onTapMark,
            ),
    );
  }
}

class NovelBlockList extends StatelessWidget {
  const NovelBlockList({
    super.key,
    required this.listKey,
    required this.scroll,
    required this.chapters,
    required this.size,
    required this.spacing,
    required this.dividerAt,
    required this.onTap,
    this.imageFor = networkIllustration,
    this.marksFor,
    this.onHighlight,
    this.onTapMark,
  });

  final Key listKey;
  final ScrollController scroll;
  final List<List<NovelBlockDto>> chapters;
  final ReadingSizeDto size;
  final ReadingSpacingDto spacing;
  final Widget Function(int chapter) dividerAt;
  final VoidCallback onTap;
  final NovelImageFactory imageFor;
  final List<Marked> Function(int chapter, int block, String text)? marksFor;
  final void Function(int chapter, int block, int start, int end, String quote)?
  onHighlight;
  final void Function(int chapter, int id)? onTapMark;

  @override
  Widget build(BuildContext context) {
    final inset = MediaQuery.paddingOf(context);
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: onTap,
      child: ListView.builder(
        key: listKey,
        controller: scroll,
        padding: EdgeInsets.only(
          top: inset.top + 88,
          bottom: inset.bottom + 96,
        ),
        itemCount: chapters.fold<int>(
          0,
          (sum, blocks) => sum + blocks.length + 1,
        ),
        itemBuilder: (context, flat) {
          var left = flat;
          for (var chapter = 0; chapter < chapters.length; chapter++) {
            final blocks = chapters[chapter];
            if (left < blocks.length) {
              final index = left;
              final owner = chapter;
              final block = blocks[index];
              return NovelBlock(
                key: ValueKey('block-$owner-$index'),
                block: block,
                size: size,
                spacing: spacing,
                imageFor: imageFor,
                marks: block.isImage
                    ? const []
                    : marksFor?.call(owner, index, block.text) ?? const [],
                onHighlight: onHighlight == null
                    ? null
                    : (start, end, quote) =>
                          onHighlight!(owner, index, start, end, quote),
                onTapMark: onTapMark == null
                    ? null
                    : (id) => onTapMark!(owner, id),
              );
            }
            if (left == blocks.length) return dividerAt(chapter);
            left -= blocks.length + 1;
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}
