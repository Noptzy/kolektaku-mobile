import 'package:flutter_test/flutter_test.dart';
import 'package:kolektaku/features/novel_reader/highlight_book.dart';
import 'package:kolektaku/src/rust/dto/highlight.dart';

import '../../support/fake_highlight_gateway.dart';
import 'novel_harness.dart';

HighlightInputDto input({
  double chapter = 1,
  int block = 2,
  int start = 4,
  String quote = 'Classics',
  String language = 'en',
}) {
  return HighlightInputDto(
    reference: reference,
    title: 'Hyouka',
    chapter: chapter,
    chapterLabel: 'Ch ${chapter.toInt()}',
    block: block,
    start: start,
    end: start + quote.length,
    quote: quote,
    language: language,
  );
}

void main() {
  late FakeHighlightGateway gateway;
  late HighlightBook book;

  setUp(() {
    gateway = FakeHighlightGateway();
    book = HighlightBook(gateway: gateway, reference: reference);
  });

  tearDown(() => book.dispose());

  test('a chapter that was not loaded has no marks', () {
    expect(book.of(1), isEmpty);
    expect(
      book.marksIn(chapter: 1, block: 2, text: 'the Classics', language: 'en'),
      isEmpty,
    );
  });

  test('loading a chapter notifies and finds its marks by block', () async {
    gateway.seed(
      reference: reference,
      chapter: 1,
      block: 2,
      start: 4,
      quote: 'Classics',
      language: 'en',
    );
    var told = 0;
    book.addListener(() => told++);
    await book.load(1);
    expect(told, 1);
    final marks = book.marksIn(
      chapter: 1,
      block: 2,
      text: 'the Classics Club',
      language: 'en',
    );
    expect(marks.map((mark) => (mark.start, mark.end)), [(4, 12)]);
    expect(
      book.marksIn(chapter: 1, block: 3, text: 'the Classics', language: 'en'),
      isEmpty,
    );
  });

  test('a mark in another language does not show on this text', () async {
    gateway.seed(
      reference: reference,
      chapter: 1,
      block: 2,
      start: 4,
      quote: 'Classics',
      language: 'en',
    );
    await book.load(1);
    expect(
      book.marksIn(chapter: 1, block: 2, text: 'the Classics', language: 'id'),
      isEmpty,
    );
  });

  test('a chapter is asked for once however often it is shown', () async {
    await book.load(1);
    await book.load(1);
    gateway.seed(
      reference: reference,
      chapter: 1,
      block: 0,
      start: 0,
      quote: 'x',
    );
    await book.load(1);
    expect(book.of(1), isEmpty);
  });

  test('a failed load can be tried again', () async {
    gateway.failing = true;
    await book.load(1);
    gateway.failing = false;
    gateway.seed(
      reference: reference,
      chapter: 1,
      block: 0,
      start: 0,
      quote: 'x',
    );
    await book.load(1);
    expect(book.of(1), hasLength(1));
  });

  test('adding stores it and shows it straight away', () async {
    await book.add(input());
    expect(gateway.added, hasLength(1));
    expect(book.of(1).single.quote, 'Classics');
  });

  test('removing forgets it', () async {
    await book.add(input());
    final id = book.of(1).single.id;
    await book.remove(id, 1);
    expect(gateway.removed, [id]);
    expect(book.of(1), isEmpty);
  });

  test('a book that was closed ignores a late answer', () async {
    final late = HighlightBook(gateway: gateway, reference: reference);
    final pending = late.load(1);
    late.dispose();
    await pending;
    expect(late.of(1), isEmpty);
  });
}
