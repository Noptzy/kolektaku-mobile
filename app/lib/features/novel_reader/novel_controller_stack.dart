part of 'novel_controller.dart';

typedef FlatSpot = ({int chapter, int block, bool divider});

FlatSpot locateFlat(List<int> counts, int flat) {
  var left = flat < 0 ? 0 : flat;
  for (var chapter = 0; chapter < counts.length; chapter++) {
    final count = counts[chapter];
    if (left < count) return (chapter: chapter, block: left, divider: false);
    if (left == count) {
      final last = count == 0 ? 0 : count - 1;
      return (chapter: chapter, block: last, divider: true);
    }
    left -= count + 1;
  }
  final tail = counts.isEmpty ? 0 : counts.length - 1;
  final end = counts.isEmpty || counts.last == 0 ? 0 : counts.last - 1;
  return (chapter: tail, block: end, divider: true);
}

extension NovelStack on NovelController {
  List<int> get counts => [
    for (var i = 0; i < chapters.length; i++) blocksOf(i).length,
  ];

  String languageOf(int chapter) {
    final opened = chapters[chapter];
    final translated = opened.translatedBlocks.isNotEmpty && !showOriginal;
    return translated ? opened.translatedLanguage ?? 'id' : opened.language;
  }

  UnitDto? get afterStack =>
      chapters.isEmpty ? null : unitAfter(units, chapters.last.unit.number);

  bool get mustAsk => !autoContinue || connected >= maxConnectedNovelChapters;

  DividerKind dividerKind(int chapter) {
    if (chapter < chapters.length - 1) return DividerKind.followed;
    if (afterStack == null) return DividerKind.last;
    if (extending) return DividerKind.loading;
    if (extendError != null) return DividerKind.failed;
    return mustAsk ? DividerKind.askToContinue : DividerKind.loading;
  }

  bool get wantsMore =>
      chapters.isNotEmpty &&
      visible == chapters.length - 1 &&
      !extending &&
      extendError == null &&
      afterStack != null &&
      !mustAsk;

  void onFlat(int flat) {
    if (chapters.isEmpty) return;
    final spot = locateFlat(counts, flat);
    if (spot.chapter != visible) {
      _leaveFor(spot.chapter, spot.block);
    } else {
      onBlock(spot.block);
    }
    final last = total - 1;
    if (wantsMore && last > 0 && spot.block / last >= preloadFrom) {
      unawaited(extend());
    }
  }

  void _leaveFor(int chapter, int index) {
    final left = chapters[visible];
    final movedOn = chapter > visible;
    final at = movedOn ? left.blocks.length - 1 : block;
    _saveTimer?.cancel();
    _dirty = false;
    unawaited(_save(left, at));
    visible = chapter;
    final last = blocksOf(chapter).length - 1;
    block = last < 0 ? 0 : index.clamp(0, last).toInt();
    _dirty = true;
    _saveTimer = Timer(saveDelay, flush);
    _notify();
  }

  Future<void> extend({bool manual = false}) async {
    if (extending || chapters.isEmpty) return;
    final target = afterStack;
    if (target == null) return;
    if (manual) connected = 0;
    if (!manual && mustAsk) return;
    final generation = _generation;
    extending = true;
    extendError = null;
    _notify();
    try {
      final opened = await loader.open(
        request.reference,
        target.number,
        preferred: chapters.last.source,
        exclude: const [],
      );
      if (generation != _generation || _disposed) return;
      chapters = [...chapters, opened];
      connected += 1;
    } on Object catch (failure) {
      if (generation != _generation || _disposed) return;
      extendError = failure;
    } finally {
      if (generation == _generation) {
        extending = false;
        _notify();
      }
    }
  }
}
