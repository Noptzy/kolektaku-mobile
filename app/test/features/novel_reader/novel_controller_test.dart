import 'package:flutter_test/flutter_test.dart';
import 'package:kolektaku/features/novel_reader/novel_controller.dart';
import 'package:kolektaku/features/novel_reader/novel_request.dart';

import 'novel_harness.dart';

NovelController build(
  NovelHarness harness, {
  double chapter = 1,
  bool autoContinue = true,
}) {
  final controller = NovelController(
    request: NovelRequest(
      reference: reference,
      title: 'Mushoku Tensei',
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
  testWidgets('loading opens the chapter and lists the others', (tester) async {
    final controller = build(NovelHarness(blockCount: 6));
    await controller.load();
    await tester.pump();
    await tester.pump();
    expect(controller.total, 6);
    expect(controller.current, 1);
    expect(controller.units.length, 4);
    expect(controller.error, isNull);
  });

  testWidgets('a saved block becomes the starting block', (tester) async {
    final controller = build(NovelHarness(resume: 7));
    await controller.load();
    expect(controller.startBlock, 7);
    expect(controller.block, 7);
  });

  testWidgets('a saved block past the end is pulled back to the last', (
    tester,
  ) async {
    final controller = build(NovelHarness(blockCount: 4, resume: 90));
    await controller.load();
    expect(controller.startBlock, 3);
  });

  testWidgets('a failure is kept and a retry opens it', (tester) async {
    final controller = build(NovelHarness(failFirst: true));
    await controller.load();
    expect(controller.error, isNotNull);
    expect(controller.view, isNull);
    await controller.load();
    expect(controller.error, isNull);
    expect(controller.view, isNotNull);
  });

  testWidgets('trying another source excludes the one that was read', (
    tester,
  ) async {
    final harness = NovelHarness();
    final controller = build(harness);
    await controller.load();
    await controller.tryOtherSource();
    expect(harness.excluded.last, ['n']);
  });

  testWidgets('moving saves the block after a pause, counted from one', (
    tester,
  ) async {
    final harness = NovelHarness(blockCount: 10);
    final controller = build(harness);
    await controller.load();
    controller.onBlock(4);
    expect(harness.progress.saved, isEmpty);
    await tester.pump(const Duration(milliseconds: 250));
    expect(harness.progress.saved.single.block, 5);
    expect(harness.progress.saved.single.total, 10);
  });

  testWidgets('leaving saves at once', (tester) async {
    final harness = NovelHarness(blockCount: 10);
    final controller = build(harness);
    await controller.load();
    controller.onBlock(6);
    await controller.flush();
    expect(harness.progress.saved.single.block, 7);
  });

  testWidgets('the next chapter is preloaded once past seventy percent', (
    tester,
  ) async {
    final harness = NovelHarness(blockCount: 11);
    final controller = build(harness, autoContinue: false);
    await controller.load();
    await tester.pump();
    controller.onBlock(5);
    expect(harness.preloaded, isEmpty);
    controller.onBlock(8);
    controller.onBlock(9);
    controller.onBlock(10);
    expect(harness.preloaded, [2.0]);
  });

  testWidgets('the last chapter preloads nothing', (tester) async {
    final harness = NovelHarness(blockCount: 11, unitCount: 1);
    final controller = build(harness);
    await controller.load();
    await tester.pump();
    controller.onBlock(10);
    expect(harness.preloaded, isEmpty);
  });

  testWidgets('a translated chapter shows the translation until asked', (
    tester,
  ) async {
    final controller = build(NovelHarness(translated: true));
    await controller.load();
    expect(controller.hasTranslation, isTrue);
    expect(controller.blocks.first.text, startsWith('Terjemahan'));
    controller.toggleOriginal();
    expect(controller.blocks.first.text, startsWith('Asli'));
    controller.toggleOriginal();
    expect(controller.blocks.first.text, startsWith('Terjemahan'));
  });

  testWidgets('without a translation the toggle does nothing', (tester) async {
    final controller = build(NovelHarness());
    await controller.load();
    controller.toggleOriginal();
    expect(controller.showOriginal, isFalse);
    expect(controller.blocks.first.text, startsWith('Asli'));
  });
}
