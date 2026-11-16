import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../core/theme/kolektaku_tokens.dart';
import '../../src/rust/dto/highlight.dart';
import '../../src/rust/dto/media.dart';
import '../../widgets/swipe_sheet.dart';
import '../watch/episodes_sheet.dart';
import 'highlight_book.dart';
import 'highlight_ranges.dart';
import 'novel_controller.dart';
import 'novel_request.dart';

class HighlightActions {
  HighlightActions({
    required this.book,
    required this.controller,
    required this.request,
  });

  final HighlightBook book;
  final NovelController controller;
  final NovelRequest request;

  void loadAll() {
    for (final opened in controller.chapters) {
      book.load(opened.unit.number);
    }
  }

  List<Marked> marksFor(int chapter, int block, String text) {
    return book.marksIn(
      chapter: controller.chapters[chapter].unit.number,
      block: block,
      text: text,
      language: controller.languageOf(chapter),
    );
  }

  Future<void> add(
    BuildContext context,
    int chapter,
    int block,
    int start,
    int end,
    String quote,
  ) async {
    final opened = controller.chapters[chapter];
    await book.add(
      HighlightInputDto(
        reference: request.reference,
        title: request.title,
        coverUrl: request.coverUrl,
        chapter: opened.unit.number,
        chapterLabel: episodeTag(MediaKindDto.novel, opened.unit.number),
        block: block,
        start: start,
        end: end,
        quote: quote,
        language: controller.languageOf(chapter),
      ),
    );
    if (!context.mounted) return;
    ShadToaster.of(context)
        .show(const ShadToast(description: Text('Tersimpan di Koleksi.')));
  }

  Future<void> askRemove(BuildContext context, int chapter, int id) async {
    final number = controller.chapters[chapter].unit.number;
    final remove = await showSwipeSheet<bool>(
      context: context,
      builder: (sheetContext) => ShadSheet(
        title: const Text('Hapus sorotan?'),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: Spacing.md),
          child: ShadButton.destructive(
            key: const Key('remove-highlight'),
            onPressed: () => Navigator.of(sheetContext).pop(true),
            child: const Text('Hapus sorotan'),
          ),
        ),
      ),
    );
    if (remove ?? false) await book.remove(id, number);
  }
}
