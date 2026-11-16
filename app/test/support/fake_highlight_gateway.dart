import 'package:kolektaku/data/gateways/highlight_gateway.dart';
import 'package:kolektaku/src/rust/dto/highlight.dart';
import 'package:kolektaku/src/rust/dto/media.dart';

class FakeHighlightGateway implements HighlightGateway {
  final List<HighlightDto> stored = [];
  final List<HighlightInputDto> added = [];
  final List<int> removed = [];
  bool failing = false;
  int _next = 1;

  HighlightDto seed({
    required MediaRefDto reference,
    required double chapter,
    required int block,
    required int start,
    required String quote,
    String language = 'id',
    String title = 'Mushoku Tensei',
  }) {
    final item = HighlightDto(
      id: _next++,
      reference: reference,
      kind: MediaKindDto.novel,
      title: title,
      chapter: chapter,
      chapterLabel: 'Ch ${chapter.toInt()}',
      block: block,
      start: start,
      end: start + quote.length,
      quote: quote,
      language: language,
      createdAtSecs: BigInt.from(_next),
    );
    stored.add(item);
    return item;
  }

  @override
  Future<int> add(HighlightInputDto input) async {
    if (failing) throw StateError('offline');
    added.add(input);
    final item = seed(
      reference: input.reference,
      chapter: input.chapter,
      block: input.block,
      start: input.start,
      quote: input.quote,
      language: input.language,
      title: input.title,
    );
    return item.id;
  }

  @override
  Future<void> remove(int id) async {
    removed.add(id);
    stored.removeWhere((item) => item.id == id);
  }

  @override
  Future<List<HighlightDto>> ofChapter(
    MediaRefDto reference,
    double chapter,
  ) async {
    if (failing) throw StateError('offline');
    return stored
        .where((item) => item.reference == reference && item.chapter == chapter)
        .toList();
  }

  @override
  Future<List<HighlightDto>> all() async => List.of(stored.reversed);
}
