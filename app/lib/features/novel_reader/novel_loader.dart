import '../../src/rust/api/detail.dart' as detail;
import '../../src/rust/api/play.dart' as core;
import '../../src/rust/dto/media.dart';
import '../../src/rust/dto/novel.dart';
import '../../src/rust/dto/sources.dart';
import '../watch/episode_loader.dart' show LoadUnits;

typedef OpenNovelCall = Future<NovelChapterDto> Function({
  required MediaRefDto reference,
  required double chapter,
  String? preferred,
  required List<String> exclude,
});

typedef PreloadNovelCall = Future<bool> Function({
  required MediaRefDto reference,
  required double chapter,
  String? preferred,
});

class NovelLoader {
  NovelLoader({
    OpenNovelCall? open,
    PreloadNovelCall? preload,
    LoadUnits? units,
  }) : _open = open ?? core.openNovelChapter,
       _preload = preload ?? core.preloadNovelChapter,
       _units = units ?? detail.units;

  final OpenNovelCall _open;
  final PreloadNovelCall _preload;
  final LoadUnits _units;

  Future<NovelChapterDto> open(
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

  Future<void> preload(
    MediaRefDto reference,
    double chapter, {
    String? preferred,
  }) async {
    try {
      await _preload(
        reference: reference,
        chapter: chapter,
        preferred: preferred,
      );
    } on Object {
      return;
    }
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
