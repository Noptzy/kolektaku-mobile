import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:kolektaku/features/detail/detail_request.dart';
import 'package:kolektaku/features/detail/detail_screen.dart';
import 'package:kolektaku/platform/url_opener.dart';
import 'package:kolektaku/src/rust/dto/credits.dart';
import 'package:kolektaku/src/rust/dto/links.dart';
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
  testWidgets('official links sit next to the trailer and open outside', (
    tester,
  ) async {
    final opened = await open(
      tester,
      view: catalogView(
        head: detail(
          trailer: const TrailerDto(site: 'youtube', videoId: 'abc123'),
          links: const [
            ExternalLinkDto(
              site: 'Official Site',
              url: 'https://a.test/',
              kind: 'INFO',
            ),
            ExternalLinkDto(
              site: 'Twitter',
              url: 'https://twitter.com/a',
              kind: 'SOCIAL',
            ),
          ],
        ),
      ),
    );
    expect(find.text('Trailer'), findsOneWidget);
    expect(find.text('Situs resmi'), findsOneWidget);
    expect(find.text('Twitter'), findsOneWidget);
    await tester.tap(find.byKey(const Key('link-https://twitter.com/a')));
    await tester.pumpAndSettle();
    expect(opened.opener.opened, ['https://twitter.com/a']);
  });
  testWidgets('links show even when there is no trailer', (tester) async {
    await open(
      tester,
      view: catalogView(
        head: detail(
          links: const [
            ExternalLinkDto(
              site: 'Official Site',
              url: 'https://a.test/',
              kind: 'INFO',
            ),
          ],
        ),
      ),
    );
    expect(find.text('Trailer'), findsNothing);
    expect(find.text('Situs resmi'), findsOneWidget);
  });
  testWidgets('an unsafe address never becomes a button', (tester) async {
    await open(
      tester,
      view: catalogView(
        head: detail(
          links: const [
            ExternalLinkDto(
              site: 'Bad',
              url: 'javascript:alert(1)',
              kind: 'INFO',
            ),
          ],
        ),
      ),
    );
    expect(find.text('Bad'), findsNothing);
  });
  testWidgets('without links the row stays as it was', (tester) async {
    await open(tester);
    expect(find.text('Situs resmi'), findsNothing);
  });
}
