import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kolektaku/src/rust/dto/settings.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import 'novel_harness.dart';

Finder paragraphNumber(int number) => find.textContaining('paragraf $number.');

void main() {
  testWidgets('the chapter opens as readable paragraphs under a titled bar', (
    tester,
  ) async {
    await NovelHarness().open(tester);
    expect(paragraphNumber(1), findsOneWidget);
    expect(find.textContaining('Mushoku Tensei'), findsOneWidget);
    expect(find.textContaining('Ch 1'), findsOneWidget);
    expect(find.byKey(const Key('page-counter')), findsOneWidget);
  });

  testWidgets('the list is lazy so far paragraphs are not built', (
    tester,
  ) async {
    await NovelHarness(blockCount: 200).open(tester);
    expect(paragraphNumber(1), findsOneWidget);
    expect(paragraphNumber(190), findsNothing);
  });

  testWidgets('a failure offers a retry and another source', (tester) async {
    final harness = NovelHarness(failFirst: true);
    await harness.open(tester);
    expect(find.byKey(const Key('novel-retry')), findsOneWidget);
    expect(find.byKey(const Key('novel-other-source')), findsOneWidget);
    expect(find.text('Coba sumber lain'), findsOneWidget);
    await tester.tap(find.byKey(const Key('novel-retry')));
    await tester.pump();
    await tester.pump();
    expect(paragraphNumber(1), findsOneWidget);
    expect(harness.loads, 2);
  });

  testWidgets('another source is asked for without the failing one', (
    tester,
  ) async {
    final harness = NovelHarness(failFirst: true);
    await harness.open(tester);
    await tester.tap(find.byKey(const Key('novel-other-source')));
    await tester.pump();
    await tester.pump();
    expect(harness.loads, 2);
  });

  testWidgets('scrolling saves where the reader is, counted from one', (
    tester,
  ) async {
    final harness = NovelHarness(blockCount: 60);
    await harness.open(tester);
    await tester.drag(find.byType(ListView), const Offset(0, -2400));
    await tester.pumpAndSettle(const Duration(milliseconds: 400));
    final saved = harness.progress.saved;
    expect(saved, isNotEmpty);
    expect(saved.last.block, greaterThan(5));
    expect(saved.last.total, 60);
  });

  testWidgets('a saved place is where the chapter opens again', (tester) async {
    final harness = NovelHarness(blockCount: 60, resume: 25);
    await harness.open(tester);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    final shown = paragraphNumber(26);
    expect(shown, findsOneWidget);
    final top = tester.getTopLeft(shown).dy;
    expect(top, lessThan(400));
    expect(paragraphNumber(1), findsNothing);
  });

  testWidgets(
    'an English chapter shows its translation and can show the original',
    (tester) async {
      await NovelHarness(translated: true).open(tester);
      expect(find.textContaining('Terjemahan paragraf 1.'), findsOneWidget);
      expect(find.byKey(const Key('translation-caption')), findsOneWidget);
      expect(find.text('Diterjemahkan otomatis'), findsOneWidget);
      await tester.tap(find.byKey(const Key('toggle-original')));
      await tester.pump();
      expect(find.textContaining('Asli paragraf 1.'), findsOneWidget);
      expect(find.text('Teks asli'), findsOneWidget);
    },
  );

  testWidgets('a chapter without a translation has no toggle', (tester) async {
    await NovelHarness().open(tester);
    expect(find.byKey(const Key('toggle-original')), findsNothing);
    expect(find.byKey(const Key('translation-caption')), findsNothing);
  });

  testWidgets('the next chapter opens from the bottom bar', (tester) async {
    final harness = NovelHarness();
    await harness.open(tester);
    await tester.pump();
    await tester.tap(find.byKey(const Key('next-chapter')));
    await tester.pump();
    await tester.pump();
    expect(harness.opened, [1.0, 2.0]);
  });

  testWidgets('the first chapter has no previous one', (tester) async {
    await NovelHarness().open(tester);
    await tester.pump();
    final previous = tester.widget<ShadIconButton>(
      find.byKey(const Key('previous-chapter')),
    );
    expect(previous.onPressed, isNull);
    final next = tester.widget<ShadIconButton>(
      find.byKey(const Key('next-chapter')),
    );
    expect(next.onPressed, isNotNull);
  });

  testWidgets('the end of the chapter offers the next chapter', (tester) async {
    final harness = NovelHarness(blockCount: 8);
    await harness.open(tester);
    await tester.pump();
    await tester.drag(find.byType(ListView), const Offset(0, -9000));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Chapter 1 selesai'), findsOneWidget);
    await tester.tap(find.byKey(const Key('end-next')));
    await tester.pump();
    await tester.pump();
    expect(harness.opened.last, 2.0);
  });

  testWidgets('the look sheet previews and saves the chosen size', (
    tester,
  ) async {
    final harness = await NovelHarness().open(tester);
    await tester.tap(find.byKey(const Key('open-look')));
    await tester.pumpAndSettle();
    expect(find.text('Tampilan baca'), findsWidgets);
    expect(find.byKey(const Key('look-sample')), findsOneWidget);
    final before = tester
        .widget<Text>(find.byKey(const Key('look-sample')))
        .style!
        .fontSize!;
    await tester.tap(find.byKey(const Key('size-largest')));
    await tester.pumpAndSettle();
    final after = tester
        .widget<Text>(find.byKey(const Key('look-sample')))
        .style!
        .fontSize!;
    expect(after, greaterThan(before));
    expect(harness.settings.saves.last.readingSize, ReadingSizeDto.largest);
  });

  testWidgets('the line spacing is chosen the same way', (tester) async {
    final harness = await NovelHarness().open(tester);
    await tester.tap(find.byKey(const Key('open-look')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('spacing-loose')));
    await tester.pumpAndSettle();
    expect(harness.settings.saves.last.readingSpacing, ReadingSpacingDto.loose);
  });

  testWidgets('a translation that failed says so once and shows the original', (
    tester,
  ) async {
    await NovelHarness(translationFailed: true).open(tester);
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.textContaining('Terjemahan belum bisa dimuat'), findsOneWidget);
    expect(paragraphNumber(1), findsOneWidget);
  });
}
