import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kolektaku/features/reader/page_image.dart';
import 'package:kolektaku/features/reader/reader_screen.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../support/decode.dart';
import 'reader_harness.dart';

double barOpacity(WidgetTester tester, String key) {
  final fade = find.ancestor(
    of: find.byKey(Key(key)),
    matching: find.byType(AnimatedOpacity),
  );
  return tester.widget<AnimatedOpacity>(fade.first).opacity;
}

Future<void> scrollBy(WidgetTester tester, double pixels) async {
  await tester.drag(find.byType(ListView), Offset(0, -pixels));
  await tester.pump(const Duration(milliseconds: 300));
  await decoded(tester);
}

void main() {
  testWidgets('a spinner shows while the chapter is prepared', (tester) async {
    final hold = Completer<void>();
    final harness = ReaderHarness(hold: hold);
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(harness.app());
    await tester.pump();
    expect(find.text('Menyiapkan chapter…'), findsOneWidget);
    expect(find.byKey(const Key('back')), findsOneWidget);
    hold.complete();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Menyiapkan chapter…'), findsNothing);
  });

  testWidgets('the chapter shows its pages with a counter and a title', (
    tester,
  ) async {
    final harness = ReaderHarness();
    await harness.open(tester);
    expect(find.byType(PageImage), findsWidgets);
    expect(find.text('1 / 5'), findsOneWidget);
    expect(find.textContaining('Chainsaw Man'), findsOneWidget);
    expect(find.textContaining('Ch 1'), findsOneWidget);
  });

  testWidgets('a tap hides the bars and another brings them back', (
    tester,
  ) async {
    final harness = ReaderHarness();
    await harness.open(tester);
    expect(barOpacity(tester, 'page-counter'), 1);
    await tester.tapAt(const Offset(195, 400));
    await tester.pump(const Duration(milliseconds: 300));
    expect(barOpacity(tester, 'page-counter'), 0);
    expect(barOpacity(tester, 'back'), 0);
    await tester.tapAt(const Offset(195, 400));
    await tester.pump(const Duration(milliseconds: 300));
    expect(barOpacity(tester, 'page-counter'), 1);
  });

  testWidgets('scrolling hides the bars on its own', (tester) async {
    final harness = ReaderHarness();
    await harness.open(tester);
    await scrollBy(tester, 300);
    expect(barOpacity(tester, 'page-counter'), 0);
  });

  testWidgets('the counter follows the page being read', (tester) async {
    final harness = ReaderHarness(pageCount: 6);
    await harness.open(tester);
    await scrollBy(tester, 1000);
    final counter = tester.widget<Text>(find.byKey(const Key('page-counter')));
    expect(counter.data, isNot('1 / 6'));
    expect(counter.data, endsWith('/ 6'));
  });

  testWidgets('reading on saves the page after a pause', (tester) async {
    final harness = ReaderHarness(pageCount: 6);
    await harness.open(tester);
    await scrollBy(tester, 1000);
    await tester.pump(const Duration(seconds: 1));
    expect(harness.progress.saved, isNotEmpty);
    expect(harness.progress.saved.last.chapter, 1);
    expect(harness.progress.saved.last.total, 6);
    expect(harness.progress.saved.last.page, greaterThan(1));
  });

  testWidgets('a saved page is where reading starts', (tester) async {
    final harness = ReaderHarness(resume: 3);
    await harness.open(tester);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('4 / 5'), findsOneWidget);
  });

  testWidgets('the next chapter button opens the next chapter', (tester) async {
    final harness = ReaderHarness();
    await harness.open(tester);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.byKey(const Key('next-chapter')));
    await tester.pump();
    await tester.pump();
    await decoded(tester);
    expect(harness.opened, [1, 2]);
    expect(find.textContaining('Ch 2'), findsOneWidget);
    expect(find.text('1 / 5'), findsOneWidget);
  });

  testWidgets('the first chapter has no previous chapter button', (
    tester,
  ) async {
    final harness = ReaderHarness();
    await harness.open(tester);
    await tester.pump(const Duration(milliseconds: 300));
    final previous = tester.widget<ShadIconButton>(
      find.byKey(const Key('previous-chapter')),
    );
    expect(previous.onPressed, isNull);
    final next = tester.widget<ShadIconButton>(
      find.byKey(const Key('next-chapter')),
    );
    expect(next.onPressed, isNotNull);
  });

  testWidgets('the last chapter has no next chapter button', (tester) async {
    final harness = ReaderHarness(chapter: 4);
    await harness.open(tester);
    await tester.pump(const Duration(milliseconds: 300));
    final next = tester.widget<ShadIconButton>(
      find.byKey(const Key('next-chapter')),
    );
    expect(next.onPressed, isNull);
    final previous = tester.widget<ShadIconButton>(
      find.byKey(const Key('previous-chapter')),
    );
    expect(previous.onPressed, isNotNull);
  });

  testWidgets('the end of a chapter offers the next one', (tester) async {
    final harness = ReaderHarness(pageCount: 2);
    await harness.open(tester);
    await scrollBy(tester, 3000);
    expect(find.text('Chapter 1 selesai'), findsOneWidget);
    await tester.tap(find.byKey(const Key('end-next')));
    await tester.pump();
    await tester.pump();
    expect(harness.opened.last, 2);
  });

  testWidgets('the last chapter says there is nothing after it', (
    tester,
  ) async {
    final harness = ReaderHarness(pageCount: 2, chapter: 4);
    await harness.open(tester);
    await scrollBy(tester, 3000);
    expect(find.text('Ini chapter terakhir.'), findsOneWidget);
    expect(find.byKey(const Key('end-next')), findsNothing);
  });

  testWidgets('the chapter list opens in a sheet and picks a chapter', (
    tester,
  ) async {
    final harness = ReaderHarness();
    await harness.open(tester);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.byKey(const Key('chapters')));
    await tester.pumpAndSettle();
    expect(find.text('Chapter'), findsOneWidget);
    expect(find.byKey(const Key('episodes-list')), findsOneWidget);
    await tester.tap(
      find.descendant(
        of: find.byKey(const Key('episodes-list')),
        matching: find.text('Chapter 3'),
      ),
    );
    await tester.pump();
    await tester.pump();
    expect(harness.opened.last, 3);
  });

  testWidgets('a failed chapter says so and can be retried', (tester) async {
    final harness = ReaderHarness(failFirst: true);
    await harness.open(tester);
    expect(find.text('Chapter tidak bisa dibuka'), findsOneWidget);
    await tester.tap(find.byKey(const Key('retry')));
    await tester.pump();
    await tester.pump();
    await decoded(tester);
    expect(find.text('Chapter tidak bisa dibuka'), findsNothing);
    expect(find.byType(PageImage), findsWidgets);
  });

  testWidgets('reading from another source is announced', (tester) async {
    final harness = ReaderHarness(switchedFrom: 'x');
    await harness.open(tester);
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Dibaca dari sumber lain.'), findsOneWidget);
  });

  testWidgets('without a chapter list there is no list button', (tester) async {
    final harness = ReaderHarness(unitCount: 0);
    await harness.open(tester);
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byKey(const Key('chapters')), findsNothing);
  });

  test('a failure message is Indonesian', () {
    expect(readFailureMessage(StateError('x')), contains('chapter'));
  });
}
