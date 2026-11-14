import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kolektaku/features/detail/episode_info_map.dart';
import 'package:kolektaku/features/detail/episode_row.dart';
import 'package:kolektaku/src/rust/dto/episodes.dart';
import 'package:kolektaku/src/rust/dto/media.dart';
import 'package:kolektaku/src/rust/dto/sources.dart';
import 'package:kolektaku/widgets/poster.dart';

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
  group('artOf', () {
    test('the banner is the first choice', () {
      final view = catalogView(
        head: detail(banner: 'https://img.test/banner.jpg', head: summary()),
      );
      expect(artOf(view), 'https://img.test/banner.jpg');
    });

    test('without a banner the cover stands in', () {
      final view = catalogView(head: detail(head: summary()));
      final cover = view.catalog!.detail.summary.coverUrl;
      expect(artOf(view), cover);
    });

    test('an empty banner counts as none', () {
      final view = catalogView(
        head: detail(banner: '', head: summary()),
      );
      expect(artOf(view), view.catalog!.detail.summary.coverUrl);
    });

    test('a site only detail has no art', () {
      expect(artOf(siteView()), isNull);
      expect(artOf(null), isNull);
    });
  });
  group('episode picture fallback', () {
    testWidgets('an episode without its own picture shows the anime art', (
      tester,
    ) async {
      await show(
        tester,
        EpisodeRow(
          unit: unit(7),
          kind: MediaKindDto.anime,
          onTap: () {},
          art: 'https://img.test/banner.jpg',
        ),
      );
      final poster = tester.widget<Poster>(find.byType(Poster));
      expect(poster.url, 'https://img.test/banner.jpg');
      expect(poster.aspectRatio, 16 / 9);
      expect(find.text('7'), findsOneWidget);
    });

    testWidgets('the art is dimmed so it does not pose as the episode', (
      tester,
    ) async {
      await show(
        tester,
        EpisodeRow(
          unit: unit(7),
          kind: MediaKindDto.anime,
          onTap: () {},
          art: 'https://img.test/banner.jpg',
        ),
      );
      final dim = find.descendant(
        of: find.byType(Poster),
        matching: find.byWidgetPredicate(
          (widget) =>
              widget is ColoredBox && widget.color == const Color(0x73000000),
        ),
      );
      expect(dim, findsOneWidget);
    });

    testWidgets('the episode own picture always wins and is not dimmed', (
      tester,
    ) async {
      await show(
        tester,
        EpisodeRow(
          unit: unit(5),
          kind: MediaKindDto.anime,
          info: info,
          onTap: () {},
          art: 'https://img.test/banner.jpg',
        ),
      );
      final poster = tester.widget<Poster>(find.byType(Poster));
      expect(poster.url, 'https://img.test/5.jpg');
      final dim = find.descendant(
        of: find.byType(Poster),
        matching: find.byWidgetPredicate(
          (widget) =>
              widget is ColoredBox && widget.color == const Color(0x73000000),
        ),
      );
      expect(dim, findsNothing);
    });

    testWidgets('with no art at all the number tile stays', (tester) async {
      await show(
        tester,
        EpisodeRow(unit: unit(7), kind: MediaKindDto.anime, onTap: () {}),
      );
      final poster = tester.widget<Poster>(find.byType(Poster));
      expect(poster.url, isNull);
      expect(find.text('7'), findsOneWidget);
    });

    testWidgets('an empty art address is the same as none', (tester) async {
      await show(
        tester,
        EpisodeRow(
          unit: unit(7),
          kind: MediaKindDto.anime,
          onTap: () {},
          art: '',
        ),
      );
      expect(find.text('7'), findsOneWidget);
    });
  });
}
