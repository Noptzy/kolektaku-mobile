import '../../core/routes.dart';
import '../../src/rust/dto/highlight.dart';
import '../../src/rust/dto/library.dart';
import '../../src/rust/dto/media.dart';
import '../novel_reader/novel_request.dart';
import '../reader/read_request.dart';
import '../watch/watch_request.dart';

const _minimumResumeSecs = 5.0;

String historyRoute(ProgressDto item) => switch (item.kind) {
  MediaKindDto.anime => Routes.watch,
  MediaKindDto.manga => Routes.read,
  MediaKindDto.novel => Routes.novel,
};

Duration? historyStart(ProgressDto item) {
  if (item.completed || item.position < _minimumResumeSecs) return null;
  return Duration(milliseconds: (item.position * 1000).round());
}

Object historyRequest(ProgressDto item) => switch (item.kind) {
  MediaKindDto.anime => WatchRequest(
    reference: item.reference,
    kind: item.kind,
    title: item.title,
    episode: item.unitNumber,
    coverUrl: item.coverUrl,
    startAt: historyStart(item),
  ),
  MediaKindDto.manga => ReadRequest(
    reference: item.reference,
    title: item.title,
    chapter: item.unitNumber,
    coverUrl: item.coverUrl,
  ),
  MediaKindDto.novel => NovelRequest(
    reference: item.reference,
    title: item.title,
    chapter: item.unitNumber,
    coverUrl: item.coverUrl,
  ),
};

NovelRequest highlightRequest(HighlightDto item) => NovelRequest(
  reference: item.reference,
  title: item.title,
  chapter: item.chapter,
  coverUrl: item.coverUrl,
  block: item.block,
);
