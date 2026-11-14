import '../../src/rust/api/library.dart' as shelf;
import '../../src/rust/dto/library.dart';
import 'watch_request.dart';

const _minimumResume = Duration(seconds: 5);

abstract class WatchProgress {
  Future<Duration?> resumeAt(WatchRequest request);

  Future<void> save(WatchRequest request, Duration position, Duration length);
}

class CoreWatchProgress implements WatchProgress {
  const CoreWatchProgress();

  @override
  Future<Duration?> resumeAt(WatchRequest request) async {
    final saved = await shelf.libraryProgressFor(
      kind: request.kind,
      reference: request.reference,
      unitNumber: request.episode,
    );
    if (saved == null || saved.completed) return null;
    final position = Duration(milliseconds: (saved.position * 1000).round());
    return position < _minimumResume ? null : position;
  }

  @override
  Future<void> save(WatchRequest request, Duration position, Duration length) {
    return shelf.librarySaveProgress(
      progress: ProgressDto(
        reference: request.reference,
        kind: request.kind,
        unitNumber: request.episode,
        title: request.title,
        coverUrl: request.coverUrl,
        position: position.inMilliseconds / 1000,
        length: length.inMilliseconds / 1000,
        updatedAtSecs: BigInt.from(
          DateTime.now().millisecondsSinceEpoch ~/ 1000,
        ),
        completed: false,
      ),
    );
  }
}
