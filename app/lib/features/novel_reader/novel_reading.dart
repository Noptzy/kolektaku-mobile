import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/providers/settings_providers.dart';
import '../../src/rust/dto/sources.dart';
import 'highlight_actions.dart';
import 'novel_bars.dart';
import 'novel_blocks.dart';
import 'novel_chrome.dart';
import 'novel_controller.dart';
import 'reading_look_sheet.dart';

class NovelReading extends ConsumerWidget {
  const NovelReading({
    super.key,
    required this.controller,
    required this.highlights,
    required this.scroll,
    required this.listKey,
    required this.barsVisible,
    required this.title,
    required this.imageFor,
    required this.onToggleBars,
    required this.onScroll,
    required this.onBack,
    required this.onChapters,
    required this.onGo,
  });

  final NovelController controller;
  final HighlightActions highlights;
  final ScrollController scroll;
  final Key listKey;
  final bool barsVisible;
  final String title;
  final NovelImageFactory imageFor;
  final VoidCallback onToggleBars;
  final NotificationListenerCallback<ScrollNotification> onScroll;
  final VoidCallback onBack;
  final VoidCallback onChapters;
  final ValueChanged<UnitDto?> onGo;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(currentSettingsProvider);
    return NotificationListener<ScrollNotification>(
      onNotification: onScroll,
      child: Stack(
        fit: StackFit.expand,
        children: [
          NovelBlockList(
            listKey: listKey,
            scroll: scroll,
            chapters: [
              for (var i = 0; i < controller.chapters.length; i++)
                controller.blocksOf(i),
            ],
            size: settings.readingSize,
            spacing: settings.readingSpacing,
            dividerAt: (chapter) => novelDivider(controller, chapter),
            onTap: onToggleBars,
            imageFor: imageFor,
            marksFor: highlights.marksFor,
            onHighlight: (chapter, block, start, end, quote) =>
                highlights.add(context, chapter, block, start, end, quote),
            onTapMark: (chapter, id) =>
                highlights.askRemove(context, chapter, id),
          ),
          BarFade(
            top: true,
            visible: barsVisible,
            child: NovelTopBar(
              title: title,
              caption: translationCaption(controller),
              onBack: onBack,
              onLook: () => showReadingLookSheet(context),
              onChapters: controller.units.isEmpty ? null : onChapters,
              onToggleOriginal: controller.hasTranslation
                  ? controller.toggleOriginal
                  : null,
              showingOriginal: controller.showOriginal,
            ),
          ),
          BarFade(
            top: false,
            visible: barsVisible,
            child: NovelBottomBar(controller: controller, go: onGo),
          ),
        ],
      ),
    );
  }
}
