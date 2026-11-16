part of 'novel_controller.dart';

extension NovelNavigation on NovelController {
  Future<void> goTo(UnitDto unit) {
    request = request.copyWith(chapter: unit.number);
    return load();
  }

  Future<void> tryOtherSource() {
    final source = view?.source;
    return load(exclude: source == null ? const [] : [source]);
  }

  void toggleOriginal() {
    if (!hasTranslation) return;
    showOriginal = !showOriginal;
    _notify();
  }
}
