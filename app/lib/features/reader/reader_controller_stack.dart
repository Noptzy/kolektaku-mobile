part of 'reader_controller.dart';

const maxConnectedChapters = 5;

enum DividerKind { followed, loading, failed, askToContinue, last }

extension ReaderStack on ReaderController {
  UnitDto? get afterStack =>
      chapters.isEmpty ? null : unitAfter(units, chapters.last.unit.number);

  bool get mustAsk => !autoContinue || connected >= maxConnectedChapters;

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

  void onSpot(int chapter, int index) {
    if (chapter < 0 || chapter >= chapters.length) return;
    if (chapter != visible) {
      _leaveFor(chapter, index);
    } else {
      onPage(index);
    }
    final pages = chapters[chapter].pages.length;
    if (wantsMore && index >= (pages * 0.8).floor()) unawaited(extend());
  }

  void _leaveFor(int chapter, int index) {
    final left = chapters[visible];
    final movedOn = chapter > visible;
    final at = movedOn ? left.pages.length - 1 : page;
    _saveTimer?.cancel();
    _dirty = false;
    unawaited(_save(left, at));
    visible = chapter;
    final last = chapters[chapter].pages.length - 1;
    page = last < 0 ? 0 : index.clamp(0, last).toInt();
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
