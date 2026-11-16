import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'novel_harness.dart';

Finder paragraphOf(int chapter, int block) => find.descendant(
  of: find.byKey(ValueKey('block-$chapter-$block')),
  matching: find.byKey(const Key('marked-paragraph')),
);

List<TextSpan> spansIn(WidgetTester tester, Finder finder) {
  final text = tester.widget<Text>(finder);
  return ((text.textSpan! as TextSpan).children ?? const []).cast<TextSpan>();
}

void main() {
  testWidgets('a saved highlight shows behind its words when the page opens', (
    tester,
  ) async {
    final harness = NovelHarness();
    harness.highlights.seed(
      reference: reference,
      chapter: 1,
      block: 0,
      start: 6,
      quote: 'paragraf',
    );
    await harness.open(tester);
    await tester.pump();
    final spans = spansIn(tester, paragraphOf(0, 0));
    final marked = spans.where((s) => s.style?.backgroundColor != null);
    expect(marked.map((s) => s.text), ['paragraf']);
    expect(spansIn(tester, paragraphOf(0, 1)), hasLength(1));
  });

  testWidgets('a highlight in the other language of the text is not shown', (
    tester,
  ) async {
    final harness = NovelHarness();
    harness.highlights.seed(
      reference: reference,
      chapter: 1,
      block: 0,
      start: 6,
      quote: 'paragraf',
      language: 'en',
    );
    await harness.open(tester);
    await tester.pump();
    expect(spansIn(tester, paragraphOf(0, 0)), hasLength(1));
  });

  testWidgets('selecting a word saves it with where it is', (tester) async {
    final harness = NovelHarness();
    await harness.open(tester);
    final corner = tester.getTopLeft(paragraphOf(0, 0));
    await tester.longPressAt(corner + const Offset(4, 6));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sorot'));
    await tester.pumpAndSettle();
    final saved = harness.highlights.added.single;
    expect(saved.chapter, 1);
    expect(saved.block, 0);
    expect(saved.language, 'id');
    expect(saved.title, 'Mushoku Tensei');
    expect(saved.chapterLabel, isNotEmpty);
    expect(
      'Asli paragraf 1. Kalimat panjang. '.substring(saved.start, saved.end),
      saved.quote,
    );
    expect(find.text('Tersimpan di Koleksi.'), findsOneWidget);
    final marked = spansIn(
      tester,
      paragraphOf(0, 0),
    ).where((s) => s.style?.backgroundColor != null);
    expect(marked.map((s) => s.text), [saved.quote]);
  });

  testWidgets('tapping a highlight offers to remove it', (tester) async {
    final harness = NovelHarness();
    harness.highlights.seed(
      reference: reference,
      chapter: 1,
      block: 0,
      start: 0,
      quote: 'Asli paragraf 1.',
    );
    await harness.open(tester);
    await tester.pump();
    final corner = tester.getTopLeft(paragraphOf(0, 0));
    await tester.tapAt(corner + const Offset(4, 14));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();
    expect(find.text('Hapus sorotan?'), findsOneWidget);
    await tester.tap(find.byKey(const Key('remove-highlight')));
    await tester.pumpAndSettle();
    expect(harness.highlights.removed, hasLength(1));
    final marked = spansIn(
      tester,
      paragraphOf(0, 0),
    ).where((s) => s.style?.backgroundColor != null);
    expect(marked, isEmpty);
  });

  testWidgets('a failing store never breaks reading', (tester) async {
    final harness = NovelHarness();
    harness.highlights.failing = true;
    await harness.open(tester);
    await tester.pump();
    expect(find.textContaining('paragraf 1.'), findsOneWidget);
  });
}
