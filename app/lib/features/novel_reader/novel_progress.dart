import '../../src/rust/api/library.dart' as shelf;
import '../../src/rust/dto/library.dart';
import '../../src/rust/dto/media.dart';
import 'novel_request.dart';

abstract class NovelProgress {
  Future<int?> resumeBlock(NovelRequest request, double chapter);

  Future<void> save(
    NovelRequest request,
    double chapter, {
    required int block,
    required int total,
  });
}

class CoreNovelProgress implements NovelProgress {
  const CoreNovelProgress();

  @override
  Future<int?> resumeBlock(NovelRequest request, double chapter) async {
    final saved = await shelf.libraryProgressFor(
      kind: MediaKindDto.novel,
      reference: request.reference,
      unitNumber: chapter,
    );
    if (saved == null || saved.completed) return null;
    final block = saved.position.round();
    return block <= 1 ? null : block - 1;
  }

  @override
  Future<void> save(
    NovelRequest request,
    double chapter, {
    required int block,
    required int total,
  }) {
    return shelf.librarySaveProgress(
      progress: ProgressDto(
        reference: request.reference,
        kind: MediaKindDto.novel,
        unitNumber: chapter,
        title: request.title,
        coverUrl: request.coverUrl,
        position: block.toDouble(),
        length: total.toDouble(),
        updatedAtSecs: BigInt.from(
          DateTime.now().millisecondsSinceEpoch ~/ 1000,
        ),
        completed: total > 0 && block >= total,
      ),
    );
  }
}
