import '../../src/rust/api/library.dart' as shelf;
import '../../src/rust/dto/library.dart';
import '../../src/rust/dto/media.dart';
import 'read_request.dart';

abstract class ReadProgress {
  Future<int?> resumePage(ReadRequest request, double chapter);

  Future<void> save(
    ReadRequest request,
    double chapter, {
    required int page,
    required int total,
  });
}

class CoreReadProgress implements ReadProgress {
  const CoreReadProgress();

  @override
  Future<int?> resumePage(ReadRequest request, double chapter) async {
    final saved = await shelf.libraryProgressFor(
      kind: MediaKindDto.manga,
      reference: request.reference,
      unitNumber: chapter,
    );
    if (saved == null || saved.completed) return null;
    final page = saved.position.round();
    return page <= 1 ? null : page - 1;
  }

  @override
  Future<void> save(
    ReadRequest request,
    double chapter, {
    required int page,
    required int total,
  }) {
    return shelf.librarySaveProgress(
      progress: ProgressDto(
        reference: request.reference,
        kind: MediaKindDto.manga,
        unitNumber: chapter,
        title: request.title,
        coverUrl: request.coverUrl,
        position: page.toDouble(),
        length: total.toDouble(),
        updatedAtSecs: BigInt.from(
          DateTime.now().millisecondsSinceEpoch ~/ 1000,
        ),
        completed: total > 0 && page >= total,
      ),
    );
  }
}
