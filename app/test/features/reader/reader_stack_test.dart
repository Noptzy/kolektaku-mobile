import 'package:flutter_test/flutter_test.dart';
import 'package:kolektaku/features/reader/read_request.dart';
import 'package:kolektaku/features/reader/reader_controller.dart';

import 'reader_harness.dart';

ReaderController build(
  ReaderHarness harness, {
  double chapter = 1,
  bool autoContinue = true,
}) {
  final controller = ReaderController(
    request: ReadRequest(
      reference: reference,
      title: 'Chainsaw Man',
      chapter: chapter,
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
  testWidgets('reaching most of the last chapter opens the one after it', (
    tester,
  ) async {
    final harness = ReaderHarness(pageCount: 10, unitCount: 6);
    final controller = build(harness);
    await controller.load();
    await tester.pump();
    controller.onSpot(0, 4);
    await tester.pump();
    expect(controller.chapters.length, 1);
    controller.onSpot(0, 8);
    await tester.pump();
    await tester.pump();
    expect(harness.opened, [1, 2]);
    expect(controller.chapters.map((c) => c.unit.number), [1, 2]);
    expect(controller.dividerKind(0), DividerKind.followed);
  });

  testWidgets(
    'the visible chapter follows the reader and the old one is done',
    (tester) async {
      final harness = ReaderHarness(pageCount: 4, unitCount: 6);
      final controller = build(harness);
      await controller.load();
      await tester.pump();
      controller.onSpot(0, 3);
      await tester.pump();
      await tester.pump();
      controller.onSpot(1, 1);
      await tester.pump();
      expect(controller.visible, 1);
      expect(controller.current, 2);
      expect(controller.page, 1);
      await tester.pump(const Duration(milliseconds: 300));
      final finished = harness.progress.saved.where((s) => s.chapter == 1);
      expect(finished.any((s) => s.page == s.total), isTrue);
      expect(
        harness.progress.saved.any((s) => s.chapter == 2 && s.page == 2),
        isTrue,
      );
    },
  );

  testWidgets('only the next chapter is fetched, once', (tester) async {
    final harness = ReaderHarness(pageCount: 5, unitCount: 6);
    final controller = build(harness);
    await controller.load();
    await tester.pump();
    for (var i = 0; i < 5; i++) {
      controller.onSpot(0, 4);
    }
    await tester.pump();
    await tester.pump();
    expect(harness.opened, [1, 2]);
  });

  testWidgets('with the setting off the divider asks instead of fetching', (
    tester,
  ) async {
    final harness = ReaderHarness(pageCount: 5, unitCount: 6);
    final controller = build(harness, autoContinue: false);
    await controller.load();
    await tester.pump();
    controller.onSpot(0, 4);
    await tester.pump();
    expect(harness.opened, [1]);
    expect(controller.dividerKind(0), DividerKind.askToContinue);
    await controller.extend(manual: true);
    expect(harness.opened, [1, 2]);
  });

  testWidgets('after five connected chapters the divider asks to continue', (
    tester,
  ) async {
    final harness = ReaderHarness(pageCount: 3, unitCount: 12);
    final controller = build(harness);
    await controller.load();
    await tester.pump();
    for (var chapter = 0; chapter < maxConnectedChapters; chapter++) {
      controller.onSpot(chapter, 2);
      await tester.pump();
      await tester.pump();
    }
    expect(controller.chapters.length, maxConnectedChapters + 1);
    expect(
      controller.dividerKind(controller.chapters.length - 1),
      DividerKind.askToContinue,
    );
    controller.onSpot(controller.chapters.length - 1, 2);
    await tester.pump();
    expect(controller.chapters.length, maxConnectedChapters + 1);
    await controller.extend(manual: true);
    expect(controller.chapters.length, maxConnectedChapters + 2);
  });

  testWidgets('the last chapter says it is the last', (tester) async {
    final harness = ReaderHarness(pageCount: 3, unitCount: 2);
    final controller = build(harness, chapter: 2);
    await controller.load();
    await tester.pump();
    expect(controller.dividerKind(0), DividerKind.last);
    controller.onSpot(0, 2);
    await tester.pump();
    expect(harness.opened, [2]);
  });

  testWidgets('a failure to fetch the next chapter can be retried', (
    tester,
  ) async {
    final harness = ReaderHarness(pageCount: 3, unitCount: 6, failOn: 2);
    final controller = build(harness);
    await controller.load();
    await tester.pump();
    controller.onSpot(0, 2);
    await tester.pump();
    await tester.pump();
    expect(controller.dividerKind(0), DividerKind.failed);
    harness.failOn = null;
    await controller.extend(manual: true);
    expect(controller.chapters.length, 2);
    expect(controller.extendError, isNull);
  });
}
