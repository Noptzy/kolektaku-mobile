import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:kolektaku/core/routes.dart';
import 'package:kolektaku/features/detail/detail_request.dart';
import 'package:kolektaku/features/detail/detail_screen.dart';
import 'package:kolektaku/features/detail/trailer_player.dart';
import 'package:kolektaku/platform/url_opener.dart';
import 'package:kolektaku/src/rust/dto/credits.dart';
import 'package:kolektaku/src/rust/dto/media.dart';
import 'package:kolektaku/src/rust/dto/sources.dart';

import '../../support/fake_url_opener.dart';
import '../../support/screen_harness.dart';
import 'detail_support.dart';

final request = DetailRequest(kind: MediaKindDto.anime, reference: ref(filmId));

class Opened {
  Opened(this.harness, this.opener);

  final ScreenHarness harness;
  final FakeUrlOpener opener;
}

Future<Opened> open(
  WidgetTester tester, {
  String? notice,
  DetailViewDto? view,
  int unitCount = 12,
  void Function(ScreenHarness harness)? prepare,
  List<Override> extra = const [],
}) async {
  final harness = ScreenHarness();
  final opener = FakeUrlOpener();
  harness.catalog.detailResult = view ?? catalogView();
  harness.catalog.unitsResult = units(unitCount);
  prepare?.call(harness);
  await harness.pump(
    tester,
    DetailScreen(
      request: DetailRequest(
        kind: MediaKindDto.anime,
        reference: ref(filmId),
        notice: notice,
      ),
    ),
    extra: [urlOpenerProvider.overrideWithValue(opener), ...extra],
  );
  return Opened(harness, opener);
}

Future<void> scrollTo(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(
    finder,
    300,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pumpAndSettle();
}

void main() {
  group('extras', () {
    final fakePlayer = trailerPlayerProvider.overrideWithValue(
      (context, trailer) => Text('player ${trailer.site}/${trailer.videoId}'),
    );

    testWidgets('the trailer plays in a modal inside the app', (tester) async {
      final opened = await open(
        tester,
        extra: [fakePlayer],
        view: catalogView(
          head: detail(
            trailer: const TrailerDto(site: 'youtube', videoId: 'abc123'),
          ),
        ),
      );
      await tester.tap(find.text('Trailer'));
      await tester.pumpAndSettle();
      expect(find.text('player youtube/abc123'), findsOneWidget);
      expect(opened.opener.opened, isEmpty);
    });

    testWidgets('tapping outside the sheet dismisses the trailer', (
      tester,
    ) async {
      await open(
        tester,
        extra: [fakePlayer],
        view: catalogView(
          head: detail(
            trailer: const TrailerDto(site: 'dailymotion', videoId: 'x8abc'),
          ),
        ),
      );
      await tester.tap(find.text('Trailer'));
      await tester.pumpAndSettle();
      expect(find.text('player dailymotion/x8abc'), findsOneWidget);
      await tester.tapAt(const Offset(195, 40));
      await tester.pumpAndSettle();
      expect(find.text('player dailymotion/x8abc'), findsNothing);
    });

    testWidgets('the sheet always offers to open the trailer elsewhere', (
      tester,
    ) async {
      final opened = await open(
        tester,
        extra: [fakePlayer],
        view: catalogView(
          head: detail(
            trailer: const TrailerDto(site: 'youtube', videoId: 'abc123'),
          ),
        ),
      );
      await tester.tap(find.text('Trailer'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('trailer-external')));
      await tester.pumpAndSettle();
      expect(opened.opener.opened, ['https://www.youtube.com/watch?v=abc123']);
    });

    testWidgets('a trailer id that cannot be embedded opens outside', (
      tester,
    ) async {
      final opened = await open(
        tester,
        extra: [fakePlayer],
        view: catalogView(
          head: detail(
            trailer: const TrailerDto(site: 'youtube', videoId: 'a b'),
          ),
        ),
      );
      await tester.tap(find.text('Trailer'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('trailer-external')), findsNothing);
      expect(opened.opener.opened, ['https://www.youtube.com/watch?v=a b']);
    });

    testWidgets('no trailer, no button', (tester) async {
      await open(tester);
      expect(find.text('Trailer'), findsNothing);
    });

    testWidgets('an anime with a manga adaptation offers to read it', (
      tester,
    ) async {
      final opened = await open(
        tester,
        view: catalogView(
          head: detail(
            relations: [
              RelationDto(
                relationType: 'ADAPTATION',
                media: summary(
                  id: 99,
                  kind: MediaKindDto.manga,
                  title: 'Manga Asli',
                  format: 'MANGA',
                ),
              ),
            ],
          ),
        ),
      );
      await tester.tap(find.text('Baca komiknya'));
      await tester.pumpAndSettle();
      final visit = opened.harness.visits.single;
      expect(visit.path, Routes.detail);
      final next = visit.extra! as DetailRequest;
      expect(next.kind, MediaKindDto.manga);
      expect(next.reference, ref(99));
    });
  });
}
