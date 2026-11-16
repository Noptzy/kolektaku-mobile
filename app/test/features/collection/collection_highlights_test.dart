import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kolektaku/core/routes.dart';
import 'package:kolektaku/features/collection/history_launch.dart';
import 'package:kolektaku/features/novel_reader/novel_request.dart';

import '../../support/fake_highlight_gateway.dart';
import '../detail/detail_support.dart' show ref;
import 'collection_support.dart';

Future<void> openNovels(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('kind-novel')));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('only novels have a highlights part', (tester) async {
    final harness = await open(tester);
    harness.highlights.seed(
      reference: ref(1),
      chapter: 2,
      block: 3,
      start: 0,
      quote: 'Kalimat sorotan',
    );
    expect(find.text('Sorotan'), findsNothing);
    await tester.tap(find.byKey(const Key('kind-novel')));
    await tester.pumpAndSettle();
    expect(find.text('Sorotan'), findsOneWidget);
  });

  testWidgets('a highlight shows its words, its novel and its chapter', (
    tester,
  ) async {
    final harness = await open(tester);
    harness.highlights.seed(
      reference: ref(1),
      chapter: 2,
      block: 3,
      start: 0,
      quote: 'Kalimat sorotan',
      title: 'Hyouka',
    );
    await openNovels(tester);
    expect(find.text('Kalimat sorotan'), findsOneWidget);
    expect(find.text('Hyouka  ·  Ch 2'), findsOneWidget);
  });

  testWidgets('without highlights it says how to make one', (tester) async {
    await open(tester);
    await openNovels(tester);
    expect(find.textContaining('Belum ada sorotan'), findsOneWidget);
  });

  testWidgets('tapping a highlight opens the novel at that paragraph', (
    tester,
  ) async {
    final harness = await open(tester);
    harness.highlights.seed(
      reference: ref(1),
      chapter: 2,
      block: 3,
      start: 0,
      quote: 'Kalimat sorotan',
    );
    await openNovels(tester);
    await tester.tap(find.text('Kalimat sorotan'));
    await tester.pumpAndSettle();
    final visit = harness.visits.single;
    expect(visit.path, Routes.novel);
    final request = visit.extra! as NovelRequest;
    expect(request.chapter, 2);
    expect(request.block, 3);
  });

  testWidgets('removing a highlight asks first and then forgets it', (
    tester,
  ) async {
    final harness = await open(tester);
    final item = harness.highlights.seed(
      reference: ref(1),
      chapter: 2,
      block: 3,
      start: 0,
      quote: 'Kalimat sorotan',
    );
    await openNovels(tester);
    await tester.tap(find.byKey(Key('remove-highlight-${item.id}')));
    await tester.pumpAndSettle();
    expect(find.text('Hapus sorotan?'), findsOneWidget);
    await tester.tap(find.byKey(const Key('confirm-cancel')));
    await tester.pumpAndSettle();
    expect(harness.highlights.removed, isEmpty);
    await tester.tap(find.byKey(Key('remove-highlight-${item.id}')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('confirm-ok')));
    await tester.pumpAndSettle();
    expect(harness.highlights.removed, [item.id]);
    expect(find.text('Kalimat sorotan'), findsNothing);
  });

  test('a highlight request carries its place and drops it after a move', () {
    final request = NovelRequest(
      reference: ref(1),
      title: 'Hyouka',
      chapter: 2,
      block: 3,
    );
    expect(request.copyWith(preferredSource: 'a').block, 3);
    expect(request.copyWith(chapter: 3).block, isNull);
  });

  test('a highlight maps to a novel request', () {
    final item = FakeHighlightGateway().seed(
      reference: ref(4),
      chapter: 6,
      block: 5,
      start: 0,
      quote: 'x',
    );
    final request = highlightRequest(item);
    expect(request.block, 5);
    expect(request.chapter, 6);
    expect(request.reference, ref(4));
  });
}
