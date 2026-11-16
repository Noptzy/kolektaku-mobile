import 'package:flutter_test/flutter_test.dart';
import 'package:kolektaku/features/novel_reader/novel_controller.dart';
import 'package:kolektaku/features/novel_reader/novel_request.dart';
import 'package:kolektaku/features/reader/reader_controller.dart';

import 'novel_harness.dart';

NovelController build(NovelHarness harness, {bool autoContinue = true}) {
  final controller = NovelController(
    request: NovelRequest(
      reference: reference,
      title: 'Mushoku Tensei',
      chapter: 1,
    ),
    loader: harness.loader,
    progress: harness.progress,
    saveDelay: const Duration(milliseconds: 200),
    autoContinue: autoContinue,
  );
  addTearDown(controller.dispose);
  return controller;
}

void main() {
  group('locateFlat', () {
    test('blocks come first and the divider closes each chapter', () {
      const counts = [3, 2];
      expect(locateFlat(counts, 0), (chapter: 0, block: 0, divider: false));
      expect(locateFlat(counts, 2), (chapter: 0, block: 2, divider: false));
      expect(locateFlat(counts, 3), (chapter: 0, block: 2, divider: true));
      expect(locateFlat(counts, 4), (chapter: 1, block: 0, divider: false));
      expect(locateFlat(counts, 6), (chapter: 1, block: 1, divider: true));
    });

    test('far past the end stays on the last chapter', () {
      expect(locateFlat(const [3, 2], 99), (
        chapter: 1,
        block: 1,
        divider: true,
      ));
      expect(locateFlat(const [], 4), (chapter: 0, block: 0, divider: true));
    });

    test('a negative index is the first block', () {
      expect(locateFlat(const [3], -2), (chapter: 0, block: 0, divider: false));
    });
  });

  testWidgets('reaching seventy percent opens the next chapter once', (
    tester,
  ) async {
    final harness = NovelHarness(blockCount: 11, unitCount: 6);
    final controller = build(harness);
    await controller.load();
    await tester.pump();
    controller.onFlat(3);
    await tester.pump();
    expect(controller.chapters.length, 1);
    for (var i = 0; i < 4; i++) {
      controller.onFlat(9);
    }
    await tester.pump();
    await tester.pump();
    expect(harness.opened, [1.0, 2.0]);
    expect(controller.dividerKind(0), DividerKind.followed);
  });

  testWidgets('scrolling into the next chapter marks the old one finished', (
    tester,
  ) async {
    final harness = NovelHarness(blockCount: 5, unitCount: 6);
    final controller = build(harness);
    await controller.load();
    await tester.pump();
    controller.onFlat(4);
    await tester.pump();
    await tester.pump();
    controller.onFlat(7);
    await tester.pump(const Duration(milliseconds: 300));
    expect(controller.visible, 1);
    expect(controller.current, 2);
    final saved = harness.progress.saved;
    expect(saved.any((s) => s.chapter == 1 && s.block == s.total), isTrue);
  });

  testWidgets('with continuing off the divider asks and the button goes on', (
    tester,
  ) async {
    final harness = NovelHarness(blockCount: 5, unitCount: 6);
    final controller = build(harness, autoContinue: false);
    await controller.load();
    await tester.pump();
    controller.onFlat(4);
    await tester.pump();
    expect(harness.opened, [1.0]);
    expect(controller.dividerKind(0), DividerKind.askToContinue);
    await controller.extend(manual: true);
    expect(harness.opened, [1.0, 2.0]);
  });

  testWidgets('after five connected chapters the divider asks again', (
    tester,
  ) async {
    final harness = NovelHarness(blockCount: 4, unitCount: 12);
    final controller = build(harness);
    await controller.load();
    await tester.pump();
    for (var i = 0; i < maxConnectedNovelChapters; i++) {
      final last = controller.chapters.length - 1;
      controller.onFlat(
        controller.counts.take(last).fold(0, (a, b) => a + b + 1) + 3,
      );
      await tester.pump();
      await tester.pump();
    }
    expect(controller.chapters.length, maxConnectedNovelChapters + 1);
    expect(
      controller.dividerKind(controller.chapters.length - 1),
      DividerKind.askToContinue,
    );
  });
}
