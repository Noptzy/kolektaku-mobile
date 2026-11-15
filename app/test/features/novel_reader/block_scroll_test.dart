import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kolektaku/features/novel_reader/block_scroll.dart';

const _padding = 88.0;
const _height = 100.0;

Future<(GlobalKey, ScrollController)> list(
  WidgetTester tester, {
  int count = 80,
}) async {
  final key = GlobalKey();
  final controller = ScrollController();
  addTearDown(controller.dispose);
  await tester.pumpWidget(
    Directionality(
      textDirection: TextDirection.ltr,
      child: ListView.builder(
        key: key,
        controller: controller,
        padding: const EdgeInsets.only(top: _padding),
        itemCount: count,
        itemBuilder: (context, index) =>
            SizedBox(height: _height, child: Text('b$index')),
      ),
    ),
  );
  return (key, controller);
}

void main() {
  testWidgets('at the top the first block is the first visible', (
    tester,
  ) async {
    final (key, _) = await list(tester);
    expect(firstVisibleBlock(key.currentContext), 0);
  });

  testWidgets('the block under the top edge is found after scrolling', (
    tester,
  ) async {
    final (key, controller) = await list(tester);
    controller.jumpTo(_padding + 10 * _height + 30);
    await tester.pump();
    expect(firstVisibleBlock(key.currentContext), 10);
    controller.jumpTo(_padding + 10 * _height + 130);
    await tester.pump();
    expect(firstVisibleBlock(key.currentContext), 11);
  });

  testWidgets('a block already built is jumped to exactly', (tester) async {
    final (key, controller) = await list(tester);
    await jumpToBlock(controller, () => key.currentContext, 3);
    await tester.pump();
    expect(controller.position.pixels, _padding + 3 * _height);
    expect(firstVisibleBlock(key.currentContext), 3);
  });

  testWidgets('a block far down is reached in a few steps', (tester) async {
    final (key, controller) = await list(tester);
    final jumping = jumpToBlock(controller, () => key.currentContext, 60);
    for (var frame = 0; frame < 10; frame++) {
      await tester.pump();
    }
    await jumping;
    await tester.pump();
    expect(firstVisibleBlock(key.currentContext), 60);
  });

  testWidgets('a block past the end lands at the end without failing', (
    tester,
  ) async {
    final (key, controller) = await list(tester, count: 30);
    final jumping = jumpToBlock(controller, () => key.currentContext, 500);
    for (var frame = 0; frame < 10; frame++) {
      await tester.pump();
    }
    await jumping;
    expect(controller.position.pixels, controller.position.maxScrollExtent);
  });

  testWidgets('with no list there is nothing to find or jump to', (
    tester,
  ) async {
    expect(firstVisibleBlock(null), isNull);
    final controller = ScrollController();
    addTearDown(controller.dispose);
    await jumpToBlock(controller, () => null, 4);
  });
}
