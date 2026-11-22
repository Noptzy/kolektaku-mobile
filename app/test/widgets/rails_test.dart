import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kolektaku/features/dev/gallery/sample_media.dart';
import 'package:kolektaku/src/rust/dto/cards.dart';
import 'package:kolektaku/widgets/genre_card.dart';
import 'package:kolektaku/widgets/media_card.dart';
import 'package:kolektaku/widgets/media_rail.dart';
import 'package:kolektaku/widgets/rank_number.dart';
import 'package:kolektaku/widgets/rail.dart';
import 'package:kolektaku/core/theme/kolektaku_tokens.dart';
import 'package:kolektaku/widgets/score_badge.dart';
import 'package:kolektaku/widgets/score_meta.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:kolektaku/widgets/top10_rail.dart';

import 'widget_harness.dart';

void main() {
  group('MediaRail', () {
    testWidgets('titles the rail and lists the cards', (tester) async {
      await pumpAtSize(
        tester,
        MediaRail(title: 'Populer', cards: sampleCards(4)),
      );
      expect(find.text('Populer'), findsOneWidget);
      expect(find.byType(MediaCard), findsWidgets);
    });

    testWidgets('taps carry the tapped card', (tester) async {
      MediaCardDto? tapped;
      final cards = sampleCards(3);
      await pumpAtSize(
        tester,
        MediaRail(title: 'Populer', cards: cards, onTap: (c) => tapped = c),
      );
      await tester.tap(find.byType(MediaCard).first);
      expect(tapped, cards.first);
    });

    testWidgets('progress is looked up per card', (tester) async {
      await pumpAtSize(
        tester,
        MediaRail(
          title: 'Lanjut nonton',
          cards: sampleCards(2),
          progressOf: (card) => 0.5,
        ),
      );
      expect(
        tester.widget<MediaCard>(find.byType(MediaCard).first).progress,
        0.5,
      );
    });

    testWidgets('the new flag reaches every card', (tester) async {
      await pumpAtSize(
        tester,
        MediaRail(title: 'Episode baru', cards: sampleCards(2), newOnly: true),
      );
      expect(find.text('Baru'), findsWidgets);
    });
  });

  group('Top10Rail', () {
    testWidgets('shows at most ten ranks', (tester) async {
      await pumpAtSize(
        tester,
        Top10Rail(title: 'Top 10', cards: sampleCards(14)),
      );
      expect(tester.widget<Rail>(find.byType(Rail)).itemCount, 10);
    });

    testWidgets('numbers start at one and follow the order', (tester) async {
      await pumpAtSize(
        tester,
        Top10Rail(title: 'Top 10', cards: sampleCards(3)),
      );
      expect(find.text('1'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
    });

    testWidgets('each poster has its title and star score underneath', (
      tester,
    ) async {
      final cards = sampleCards(2);
      await pumpAtSize(tester, Top10Rail(title: 'Top 10', cards: cards));
      for (final card in cards) {
        expect(find.text(card.title), findsOneWidget);
      }
      expect(
        find.byType(ScoreMeta),
        findsNWidgets(cards.where((card) => card.score != null).length),
      );
      expect(find.byType(ScoreBadge), findsNothing);
    });

    testWidgets('a card without a score has no score line', (tester) async {
      final card = sampleCard(1, score: null);
      await pumpAtSize(tester, Top10Rail(title: 'Top 10', cards: [card]));
      expect(find.byType(ScoreMeta), findsNothing);
      expect(find.text(card.title), findsOneWidget);
    });

    testWidgets('the rail is tall enough for a two line title and the score', (
      tester,
    ) async {
      await pumpAtSize(
        tester,
        Top10Rail(title: 'Top 10', cards: sampleCards(2)),
      );
      expect(tester.takeException(), isNull);
      final rail = tester.widget<Rail>(find.byType(Rail));
      expect(
        rail.height,
        greaterThan(Sizes.railPosterWidth / Sizes.posterAspect + 40),
      );
    });

    testWidgets('a tap reports the card behind the rank', (tester) async {
      MediaCardDto? tapped;
      final cards = sampleCards(3);
      await pumpAtSize(
        tester,
        Top10Rail(title: 'Top 10', cards: cards, onTap: (c) => tapped = c),
      );
      await tester.tap(find.text('1'));
      expect(tapped, cards.first);
    });

    testWidgets('only the first rank is gold', (tester) async {
      await pumpAtSize(
        tester,
        const Row(children: [RankNumber(rank: 1), RankNumber(rank: 2)]),
      );
      Color colorOf(String text) =>
          tester.widget<Text>(find.text(text)).style!.color!;
      final primary = ShadTheme.of(tester.element(find.text('1')))
          .colorScheme
          .primary;
      expect(colorOf('1'), primary);
      expect(colorOf('2'), isNot(primary));
    });

    test('the rank is a solid number and only the first is highlighted', () {
      expect(RankNumber.isTop(1), isTrue);
      expect(RankNumber.isTop(2), isFalse);
    });

    test('a two digit rank takes more room', () {
      expect(RankNumber.widthFor(10), greaterThan(RankNumber.widthFor(9)));
    });
  });

  group('GenreCard', () {
    testWidgets('shows the label and reports taps', (tester) async {
      var taps = 0;
      await pumpAtSize(
        tester,
        SizedBox(
          width: 170,
          child: GenreCard(label: 'Aksi', onTap: () => taps++),
        ),
      );
      expect(find.text('Aksi'), findsOneWidget);
      await tester.tap(find.byType(GenreCard));
      expect(taps, 1);
    });
  });
}
