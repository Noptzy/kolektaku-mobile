import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kolektaku/features/dev/gallery/sample_media.dart';
import 'package:kolektaku/src/rust/dto/cards.dart';
import 'package:kolektaku/widgets/genre_card.dart';
import 'package:kolektaku/widgets/media_card.dart';
import 'package:kolektaku/widgets/media_rail.dart';
import 'package:kolektaku/widgets/outlined_rank.dart';
import 'package:kolektaku/widgets/rail.dart';
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

    test('a two digit rank takes more room', () {
      expect(OutlinedRank.widthFor(10), greaterThan(OutlinedRank.widthFor(9)));
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
