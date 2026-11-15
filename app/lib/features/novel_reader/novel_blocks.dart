import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../core/theme/kolektaku_tokens.dart';
import '../../src/rust/dto/novel.dart';
import '../../src/rust/dto/settings.dart';
import '../../src/rust/dto/sources.dart';
import '../reader/chapter_end.dart';
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
  });

  final NovelBlockDto block;
  final ReadingSizeDto size;
  final ReadingSpacingDto spacing;
  final NovelImageFactory imageFor;

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
          ? Image(
              image: imageFor(block.text),
              fit: BoxFit.fitWidth,
              errorBuilder: (context, error, stack) => Text(
                'Gambar tidak bisa dimuat.',
                style: ShadTheme.of(context).textTheme.muted,
              ),
            )
          : Text(block.text, style: style),
    );
  }
}

class NovelBlockList extends StatelessWidget {
  const NovelBlockList({
    super.key,
    required this.listKey,
    required this.scroll,
    required this.blocks,
    required this.size,
    required this.spacing,
    required this.current,
    required this.next,
    required this.onNext,
    required this.onTap,
    this.imageFor = networkIllustration,
  });

  final Key listKey;
  final ScrollController scroll;
  final List<NovelBlockDto> blocks;
  final ReadingSizeDto size;
  final ReadingSpacingDto spacing;
  final double current;
  final UnitDto? next;
  final VoidCallback onNext;
  final VoidCallback onTap;
  final NovelImageFactory imageFor;

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
        itemCount: blocks.length + 1,
        itemBuilder: (context, index) {
          if (index == blocks.length) {
            return ChapterEnd(current: current, next: next, onNext: onNext);
          }
          return NovelBlock(
            key: ValueKey('block-$index'),
            block: blocks[index],
            size: size,
            spacing: spacing,
            imageFor: imageFor,
          );
        },
      ),
    );
  }
}
