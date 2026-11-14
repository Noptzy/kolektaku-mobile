import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kolektaku/features/detail/episode_info_map.dart';
import 'package:kolektaku/features/detail/episode_row.dart';
import 'package:kolektaku/src/rust/dto/episodes.dart';
import 'package:kolektaku/src/rust/dto/media.dart';
import 'package:kolektaku/src/rust/dto/sources.dart';
import 'package:kolektaku/widgets/poster.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../widgets/widget_harness.dart';
import 'detail_support.dart';

UnitDto unit(double number) =>
    UnitDto(id: 'u$number', number: number, label: 'Ep ${number.round()}');

const info = EpisodeInfoDto(
  number: 5,
  title: 'Cruelty',
  thumbnailUrl: 'https://img.test/5.jpg',
);

Future<void> show(
  WidgetTester tester,
  EpisodeRow row, {
  Size size = const Size(390, 844),
}) {
  return pumpAtSize(tester, SingleChildScrollView(child: row), size: size);
}

void main() {
  group('rowTitle and rowSubtitle', () {
    test('a named episode shows its name and the number beneath', () {
      expect(rowTitle(unit(5), info, MediaKindDto.anime), 'Cruelty');
      expect(rowSubtitle(unit(5), info, MediaKindDto.anime), 'Episode 5');
    });

    test('an unnamed episode shows the number as its title only', () {
      expect(rowTitle(unit(5), null, MediaKindDto.anime), 'Episode 5');
      expect(rowSubtitle(unit(5), null, MediaKindDto.anime), isNull);
    });

    test('an empty name counts as unnamed', () {
      const empty = EpisodeInfoDto(number: 5, title: '  ');
      expect(rowTitle(unit(5), empty, MediaKindDto.anime), 'Episode 5');
      expect(rowSubtitle(unit(5), empty, MediaKindDto.anime), isNull);
    });

    test('chapters are named as chapters', () {
      expect(rowTitle(unit(12), null, MediaKindDto.manga), 'Chapter 12');
    });

    test('the badge drops a pointless decimal', () {
      expect(numberBadge(1086), '1086');
      expect(numberBadge(6.5), '6.5');
    });
  });
  group('episodeInfosOf', () {
    test('indexes the catalog episodes by number', () {
      final view = catalogView(
        head: detail(
          episodes: const [
            EpisodeInfoDto(number: 1, title: 'A'),
            EpisodeInfoDto(number: 2, title: 'B'),
          ],
        ),
      );
      final map = episodeInfosOf(view);
      expect(map.keys, [1, 2]);
      expect(map[2]!.title, 'B');
    });

    test('a site-only or missing detail has none', () {
      expect(episodeInfosOf(siteView()), isEmpty);
      expect(episodeInfosOf(null), isEmpty);
    });
  });
  group('EpisodeRow', () {
    testWidgets('shows the name, the number line and the picture', (
      tester,
    ) async {
      await show(
        tester,
        EpisodeRow(
          unit: unit(5),
          kind: MediaKindDto.anime,
          info: info,
          onTap: () {},
        ),
      );
      expect(find.text('Cruelty'), findsOneWidget);
      expect(find.text('Episode 5'), findsOneWidget);
      expect(find.text('5'), findsOneWidget);
      final poster = tester.widget<Poster>(find.byType(Poster));
      expect(poster.url, 'https://img.test/5.jpg');
    });

    testWidgets('without a picture the number sits on a tile', (tester) async {
      await show(
        tester,
        EpisodeRow(unit: unit(7), kind: MediaKindDto.anime, onTap: () {}),
      );
      expect(find.text('Episode 7'), findsOneWidget);
      expect(find.text('7'), findsOneWidget);
    });

    testWidgets('four digit numbers stay on one line inside their box', (
      tester,
    ) async {
      await show(
        tester,
        EpisodeRow(unit: unit(1086), kind: MediaKindDto.anime, onTap: () {}),
        size: const Size(320, 700),
      );
      expect(find.text('1086'), findsOneWidget);
      final size = tester.getSize(find.text('1086'));
      expect(size.height, lessThan(40));
      expect(tester.takeException(), isNull);
    });

    testWidgets('a four digit number over a picture also fits', (tester) async {
      await show(
        tester,
        EpisodeRow(
          unit: unit(1101),
          kind: MediaKindDto.anime,
          info: const EpisodeInfoDto(
            number: 1101,
            title: 'A very long episode title that needs two lines to read',
            thumbnailUrl: 'https://img.test/x.jpg',
          ),
          onTap: () {},
        ),
        size: const Size(320, 700),
      );
      expect(find.text('1101'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('the row keeps a fixed height whatever it holds', (
      tester,
    ) async {
      await show(
        tester,
        EpisodeRow(unit: unit(1), kind: MediaKindDto.anime, onTap: () {}),
      );
      expect(tester.getSize(find.byType(EpisodeRow)).height, episodeRowHeight);
    });

    testWidgets('the playing episode says so', (tester) async {
      await show(
        tester,
        EpisodeRow(
          unit: unit(5),
          kind: MediaKindDto.anime,
          info: info,
          nowPlaying: true,
          onTap: () {},
        ),
      );
      expect(find.text('Sedang diputar'), findsOneWidget);
      expect(find.text('Episode 5'), findsNothing);
    });

    testWidgets('a partly watched episode shows its progress bar', (
      tester,
    ) async {
      await show(
        tester,
        EpisodeRow(
          unit: unit(5),
          kind: MediaKindDto.anime,
          progress: progress(5, position: 300, length: 1200),
          onTap: () {},
        ),
      );
      expect(find.byType(ShadProgress), findsOneWidget);
    });

    testWidgets('a finished episode shows no progress bar', (tester) async {
      await show(
        tester,
        EpisodeRow(
          unit: unit(5),
          kind: MediaKindDto.anime,
          progress: progress(5, completed: true),
          onTap: () {},
        ),
      );
      expect(find.byType(ShadProgress), findsNothing);
    });

    testWidgets('a tap reaches the callback', (tester) async {
      var taps = 0;
      await show(
        tester,
        EpisodeRow(
          unit: unit(5),
          kind: MediaKindDto.anime,
          onTap: () => taps++,
        ),
      );
      await tester.tap(find.byType(EpisodeRow));
      expect(taps, 1);
    });
  });
}
