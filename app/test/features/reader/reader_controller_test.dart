import 'package:flutter_test/flutter_test.dart';
import 'package:kolektaku/features/reader/read_request.dart';
import 'package:kolektaku/features/reader/reader_controller.dart';

import 'reader_harness.dart';

ReaderController build(ReaderHarness harness, {double chapter = 1}) {
  final controller = ReaderController(
    request: ReadRequest(
      reference: reference,
      title: 'Chainsaw Man',
      chapter: chapter,
    ),
    loader: harness.loader,
    progress: harness.progress,
    saveDelay: const Duration(milliseconds: 200),
  );
  addTearDown(controller.dispose);
  return controller;
}

Future<void> settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump();
}

void main() {
  testWidgets('loading opens the chapter and lists the others', (tester) async {
    final harness = ReaderHarness(pageCount: 6);
    final controller = build(harness);
    await controller.load();
    await settle(tester);
    expect(controller.view?.pages.length, 6);
    expect(controller.total, 6);
    expect(controller.current, 1);
    expect(controller.units.length, 4);
    expect(controller.error, isNull);
  });

  testWidgets('a saved page becomes the starting page', (tester) async {
    final controller = build(ReaderHarness(resume: 3));
    await controller.load();
    expect(controller.startPage, 3);
    expect(controller.page, 3);
  });

  testWidgets('a saved page past the end is pulled back to the last', (
    tester,
  ) async {
    final controller = build(ReaderHarness(pageCount: 4, resume: 90));
    await controller.load();
    expect(controller.startPage, 3);
  });

  testWidgets('no saved page starts at the first', (tester) async {
    final controller = build(ReaderHarness());
    await controller.load();
    expect(controller.startPage, 0);
  });

  testWidgets('a failing progress store never blocks reading', (tester) async {
    final harness = ReaderHarness();
    harness.progress.resume = null;
    final controller = ReaderController(
      request: ReadRequest(reference: reference, title: 'T', chapter: 1),
      loader: harness.loader,
      progress: _Broken(),
    );
    addTearDown(controller.dispose);
    await controller.load();
    expect(controller.view, isNotNull);
    expect(controller.startPage, 0);
    controller.onPage(2);
    await controller.flush();
    expect(controller.page, 2);
  });

  testWidgets('moving to another page saves once after a short pause', (
    tester,
  ) async {
    final harness = ReaderHarness();
    final controller = build(harness);
    await controller.load();
    controller.onPage(1);
    controller.onPage(2);
    await tester.pump(const Duration(milliseconds: 100));
    expect(harness.progress.saved, isEmpty);
    await tester.pump(const Duration(milliseconds: 150));
    expect(harness.progress.saved.length, 1);
    final saved = harness.progress.saved.single;
    expect((saved.chapter, saved.page, saved.total), (1.0, 3, 5));
  });

  testWidgets('the same page again saves nothing', (tester) async {
    final harness = ReaderHarness();
    final controller = build(harness);
    await controller.load();
    controller.onPage(0);
    await tester.pump(const Duration(seconds: 1));
    expect(harness.progress.saved, isEmpty);
  });

  testWidgets('a page outside the chapter is pulled inside', (tester) async {
    final controller = build(ReaderHarness(pageCount: 3));
    await controller.load();
    controller.onPage(99);
    expect(controller.page, 2);
    controller.onPage(-4);
    expect(controller.page, 0);
  });

  testWidgets('leaving the screen saves what was pending', (tester) async {
    final harness = ReaderHarness();
    final controller = build(harness);
    await controller.load();
    controller.onPage(3);
    controller.dispose();
    await settle(tester);
    expect(harness.progress.saved.single.page, 4);
  });

  testWidgets('the next and the previous chapter follow the list', (
    tester,
  ) async {
    final harness = ReaderHarness();
    final controller = build(harness, chapter: 2);
    await controller.load();
    await settle(tester);
    expect(controller.next?.number, 3);
    expect(controller.previous?.number, 1);
  });

  testWidgets('going to a chapter opens it and saves the old page first', (
    tester,
  ) async {
    final harness = ReaderHarness();
    final controller = build(harness);
    await controller.load();
    await settle(tester);
    controller.onPage(2);
    await controller.goTo(controller.next!);
    expect(harness.opened, [1, 2]);
    expect(controller.current, 2);
    expect(controller.page, 0);
    expect(harness.progress.saved.single.chapter, 1);
    expect(harness.progress.saved.single.page, 3);
  });

  testWidgets('a failure is kept and a retry opens the chapter', (
    tester,
  ) async {
    final harness = ReaderHarness(failFirst: true);
    final controller = build(harness);
    await controller.load();
    expect(controller.error, isNotNull);
    expect(controller.view, isNull);
    await controller.load();
    expect(controller.error, isNull);
    expect(controller.view, isNotNull);
  });

  testWidgets('another source is asked for without the one that failed', (
    tester,
  ) async {
    final harness = ReaderHarness();
    final controller = build(harness);
    await controller.load();
    await controller.tryOtherSource();
    expect(harness.excluded.last, ['k']);
  });

  testWidgets('an empty chapter list leaves no next or previous', (
    tester,
  ) async {
    final controller = build(ReaderHarness(unitCount: 0));
    await controller.load();
    await settle(tester);
    expect(controller.next, isNull);
    expect(controller.previous, isNull);
  });
}

class _Broken extends FakeReadProgress {
  @override
  Future<int?> resumePage(ReadRequest request, double chapter) {
    throw StateError('storage down');
  }

  @override
  Future<void> save(
    ReadRequest request,
    double chapter, {
    required int page,
    required int total,
  }) {
    throw StateError('storage down');
  }
}
