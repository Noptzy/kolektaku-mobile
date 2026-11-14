import '../../src/rust/api/detail.dart' as detail;
import '../../src/rust/api/play.dart' as core;
import '../../src/rust/dto/media.dart';
import '../../src/rust/dto/sources.dart';
import '../../src/rust/dto/stream.dart';
import '../watch/episode_loader.dart' show LoadUnits;

typedef OpenChapterCall = Future<ChapterViewDto> Function({
  required MediaRefDto reference,
  required double chapter,
  String? preferred,
  required List<String> exclude,
});

class ChapterLoader {
  ChapterLoader({OpenChapterCall? open, LoadUnits? units})
    : _open = open ?? core.openChapter,
      _units = units ?? detail.units;

  final OpenChapterCall _open;
  final LoadUnits _units;

  Future<ChapterViewDto> open(
    MediaRefDto reference,
    double chapter, {
    String? preferred,
    List<String> exclude = const [],
  }) {
    return _open(
      reference: reference,
      chapter: chapter,
      preferred: preferred,
      exclude: exclude,
    );
  }

  Future<List<UnitDto>> unitsOrEmpty(
    MediaRefDto reference, {
    String? source,
  }) async {
    try {
      final result = await _units(reference: reference, source: source);
      return result.units;
    } on Object {
      return const [];
    }
  }
}
