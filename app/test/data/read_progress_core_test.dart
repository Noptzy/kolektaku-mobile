import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kolektaku/features/reader/read_progress.dart';
import 'package:kolektaku/features/reader/read_request.dart';
import 'package:kolektaku/src/rust/api/library.dart' as shelf;
import 'package:kolektaku/src/rust/dto/media.dart';

import 'core_library.dart';

void main() {
  late Directory folder;

  setUpAll(() async {
    if (hostLibraryMissing) return;
    folder = await startHostCore();
  });

  tearDownAll(() async {
    if (!hostLibraryMissing && folder.existsSync()) {
      await folder.delete(recursive: true);
    }
  });

  final skip = hostLibraryMissing ? missingReason : false;
  final request = ReadRequest(
    reference: MediaRefDto(
      kind: MediaRefKind.catalog,
      id: BigInt.from(87216),
      source: '',
      item: '',
    ),
    title: 'Chainsaw Man',
    chapter: 1,
    coverUrl: 'https://img.test/cover.jpg',
  );
  const progress = CoreReadProgress();

  test('nothing saved means no page to resume', () async {
    expect(await progress.resumePage(request, 1), isNull);
  }, skip: skip);

  test('a page in the middle comes back as a zero based index', () async {
    await progress.save(request, 1, page: 4, total: 10);
    expect(await progress.resumePage(request, 1), 3);
  }, skip: skip);

  test('the first page is not worth resuming', () async {
    await progress.save(request, 2, page: 1, total: 10);
    expect(await progress.resumePage(request, 2), isNull);
  }, skip: skip);

  test('a finished chapter starts again from the top', () async {
    await progress.save(request, 3, page: 10, total: 10);
    expect(await progress.resumePage(request, 3), isNull);
    final next = await shelf.libraryContinue(kind: MediaKindDto.manga);
    expect(next.any((item) => item.unitNumber == 3), isFalse);
  }, skip: skip);

  test('each chapter keeps its own page', () async {
    await progress.save(request, 5, page: 7, total: 12);
    await progress.save(request, 6, page: 2, total: 12);
    expect(await progress.resumePage(request, 5), 6);
    expect(await progress.resumePage(request, 6), 1);
  }, skip: skip);

  test('the title and cover travel with the progress', () async {
    await progress.save(request, 8, page: 3, total: 9);
    final history = await shelf.libraryHistory(kind: MediaKindDto.manga);
    final saved = history.firstWhere((item) => item.unitNumber == 8);
    expect(saved.title, 'Chainsaw Man');
    expect(saved.coverUrl, 'https://img.test/cover.jpg');
    expect(saved.kind, MediaKindDto.manga);
    expect(saved.position, 3);
    expect(saved.length, 9);
    expect(saved.completed, isFalse);
  }, skip: skip);
}
