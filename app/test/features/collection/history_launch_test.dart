import 'package:flutter_test/flutter_test.dart';
import 'package:kolektaku/core/routes.dart';
import 'package:kolektaku/features/collection/history_launch.dart';
import 'package:kolektaku/features/novel_reader/novel_request.dart';
import 'package:kolektaku/features/reader/read_request.dart';
import 'package:kolektaku/features/watch/watch_request.dart';
import 'package:kolektaku/src/rust/dto/media.dart';

import '../detail/detail_support.dart' show ref;
import 'collection_support.dart';

void main() {
  group('history launch', () {
    test('anime goes to the player and comics to the reader', () {
      expect(historyRoute(progress(1)), Routes.watch);
      expect(historyRoute(progress(1, kind: MediaKindDto.manga)), Routes.read);
    });

    test('a novel opens the text reader at the chapter it was left at', () {
      final item = progress(
        4,
        kind: MediaKindDto.novel,
        title: 'Novel',
        unit: 9,
      );
      expect(historyRoute(item), Routes.novel);
      final request = historyRequest(item);
      expect(request, isA<NovelRequest>());
      final novel = request as NovelRequest;
      expect(novel.chapter, 9);
      expect(novel.title, 'Novel');
      expect(novel.reference, ref(4));
    });

    test('a saved position becomes the start of the episode', () {
      expect(historyStart(progress(1)), const Duration(seconds: 600));
    });

    test('a finished episode or a blink of watching starts from zero', () {
      expect(historyStart(progress(1, completed: true)), isNull);
      expect(historyStart(progress(2, position: 2)), isNull);
    });

    test('the watch request carries the episode, title and start', () {
      final request = historyRequest(progress(7, title: 'Satu', unit: 3));
      expect(request, isA<WatchRequest>());
      final watch = request as WatchRequest;
      expect(watch.reference, ref(7));
      expect(watch.episode, 3);
      expect(watch.title, 'Satu');
      expect(watch.startAt, const Duration(seconds: 600));
    });

    test('the read request carries the chapter and title', () {
      final request = historyRequest(
        progress(9, kind: MediaKindDto.manga, title: 'Dua', unit: 12),
      );
      expect(request, isA<ReadRequest>());
      final read = request as ReadRequest;
      expect(read.chapter, 12);
      expect(read.title, 'Dua');
    });
  });
}
