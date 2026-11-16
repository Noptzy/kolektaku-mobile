import '../../src/rust/api/highlights.dart' as core;
import '../../src/rust/dto/highlight.dart';
import '../../src/rust/dto/media.dart';

abstract interface class HighlightGateway {
  Future<int> add(HighlightInputDto input);

  Future<void> remove(int id);

  Future<List<HighlightDto>> ofChapter(MediaRefDto reference, double chapter);

  Future<List<HighlightDto>> all();
}

class BridgeHighlightGateway implements HighlightGateway {
  const BridgeHighlightGateway();

  @override
  Future<int> add(HighlightInputDto input) => core.highlightAdd(input: input);

  @override
  Future<void> remove(int id) => core.highlightRemove(id: id);

  @override
  Future<List<HighlightDto>> ofChapter(MediaRefDto reference, double chapter) =>
      core.highlightsOfChapter(reference: reference, chapter: chapter);

  @override
  Future<List<HighlightDto>> all() => core.highlightsAll();
}
