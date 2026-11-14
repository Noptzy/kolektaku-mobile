import 'package:flutter/semantics.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kolektaku/features/dev/gallery/sample_media.dart';
import 'package:kolektaku/widgets/media_card.dart';
import 'package:kolektaku/widgets/media_meta.dart';
import 'package:kolektaku/widgets/score_badge.dart';
import 'package:kolektaku/widgets/tag_badge.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import 'widget_harness.dart';

Future<void> show(WidgetTester tester, Widget card) {
  return pumpAtSize(
    tester,
    Align(
      alignment: Alignment.topLeft,
      child: SizedBox(width: 120, child: card),
    ),
  );
}

void main() {
  group('mediaMeta', () {
    test('joins year and unit count', () {
      expect(mediaMeta(sampleCard(1)), '2016 · 12 eps');
    });

    test('uses the given unit label', () {
      expect(mediaMeta(sampleCard(1), unitLabel: 'ch'), '2016 · 12 ch');
    });

    test('skips what is unknown', () {
      expect(mediaMeta(sampleCard(1, units: null)), '2016');
      expect(mediaMeta(sampleCard(1, year: null, units: null)), '');
    });
  });

  group('scoreText', () {
    test('always shows one decimal', () {
      expect(scoreText(8), '8.0');
      expect(scoreText(8.66), '8.7');
    });
  });

  group('MediaCard', () {
    testWidgets('shows title, meta and score', (tester) async {
      await show(tester, MediaCard(card: sampleCard(7, title: 'Judul')));
      expect(find.text('Judul'), findsOneWidget);
      expect(find.text('2016 · 12 eps'), findsOneWidget);
      expect(find.text('8.6'), findsOneWidget);
      expect(find.text('Baru'), findsNothing);
      expect(find.text('Data terbatas'), findsNothing);
      expect(find.byType(ShadProgress), findsNothing);
    });

    testWidgets('marks new, limited and in progress cards', (tester) async {
      await show(
        tester,
        MediaCard(
          card: sampleCard(7, limited: true, score: null),
          isNew: true,
          progress: 0.4,
        ),
      );
      expect(find.text('Baru'), findsOneWidget);
      expect(find.text('Data terbatas'), findsOneWidget);
      expect(find.byType(ShadProgress), findsOneWidget);
      expect(find.byType(ScoreBadge), findsNothing);
    });

    testWidgets('shows the tag on the poster only when given', (tester) async {
      await show(tester, MediaCard(card: sampleCard(7)));
      expect(find.byType(TagBadge), findsNothing);
      await show(tester, MediaCard(card: sampleCard(7), tag: 'Lanjutan'));
      expect(find.byType(TagBadge), findsOneWidget);
      expect(find.text('Lanjutan'), findsOneWidget);
    });

    testWidgets('a tap reaches the callback', (tester) async {
      var taps = 0;
      await show(tester, MediaCard(card: sampleCard(7), onTap: () => taps++));
      await tester.tap(find.byType(MediaCard));
      expect(taps, 1);
    });

    testWidgets('exposes the title to screen readers', (tester) async {
      await show(
        tester,
        MediaCard(
          card: sampleCard(7, title: 'Judul'),
          onTap: () {},
        ),
      );
      final node = tester.getSemantics(find.byType(MediaCard));
      expect(node.label, 'Skor 8.6\nJudul\n2016 · 12 eps');
      expect(node.hasFlag(SemanticsFlag.isButton), isTrue);
      expect(node.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);
    });

    testWidgets('a long title stops at two lines', (tester) async {
      await show(tester, MediaCard(card: sampleCard(7)));
      final title = tester.widget<Text>(
        find.textContaining('Judul contoh nomor 7'),
      );
      expect(title.maxLines, 2);
      expect(title.overflow, TextOverflow.ellipsis);
    });
  });
}
