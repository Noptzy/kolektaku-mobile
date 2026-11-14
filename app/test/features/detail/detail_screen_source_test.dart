import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:kolektaku/features/detail/detail_request.dart';
import 'package:kolektaku/features/detail/detail_screen.dart';
import 'package:kolektaku/platform/url_opener.dart';
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
  group('source', () {
    testWidgets('never names the site behind the list', (tester) async {
      await open(tester);
      expect(find.textContaining('Kuramanime'), findsNothing);
      expect(find.textContaining('Sumber:'), findsNothing);
      expect(find.text('Ganti sumber'), findsNothing);
    });

    testWidgets('with several sources a neutral switch appears', (
      tester,
    ) async {
      await open(
        tester,
        prepare: (harness) => harness.catalog.detailResult = catalogView(
          sources: [
            link('kura', name: 'Kuramanime'),
            link('lain', name: 'Sumber Lain', units: 12),
          ],
        ),
      );
      expect(find.text('Ganti sumber'), findsOneWidget);
      expect(find.textContaining('Kuramanime'), findsNothing);
    });

    testWidgets('choosing another source reloads the list from it', (
      tester,
    ) async {
      final opened = await open(
        tester,
        prepare: (harness) => harness.catalog.detailResult = catalogView(
          sources: [
            link('kura', name: 'Kuramanime'),
            link('lain', name: 'Sumber Lain', units: 12),
          ],
        ),
      );
      await tester.tap(find.text('Ganti sumber'));
      await tester.pumpAndSettle();
      expect(find.text('Pilih sumber'), findsOneWidget);
      expect(find.text('Sumber 1'), findsOneWidget);
      expect(find.textContaining('Kuramanime'), findsNothing);
      await tester.tap(find.text('Sumber 2'));
      await tester.pumpAndSettle();
      expect(opened.harness.catalog.unitSources.last, 'lain');
    });

    testWidgets('"Bukan ini?" lets the user pick the right title', (
      tester,
    ) async {
      final opened = await open(
        tester,
        prepare: (harness) {
          harness.sources.statuses = const [
            SourceStatusDto(
              id: 'kura',
              name: 'Kuramanime',
              kind: MediaKindDto.anime,
              enabled: true,
              skipped: false,
              summary: '',
            ),
          ];
          harness.catalog.candidateResult = const [
            SourceItemDto(source: 'kura', item: 'benar', title: 'Judul Benar'),
          ];
        },
      );
      await tester.tap(find.text('Bukan ini?'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Judul Benar'));
      await tester.pumpAndSettle();
      expect(opened.harness.catalog.selected, ['kura|benar']);
      expect(opened.harness.catalog.detailCalls, 2);
    });

    testWidgets('a manual choice can be forgotten', (tester) async {
      final opened = await open(
        tester,
        prepare: (harness) {
          harness.catalog.detailResult = catalogView(
            sources: [link('kura', name: 'Kuramanime', manual: true)],
          );
          harness.sources.statuses = const [
            SourceStatusDto(
              id: 'kura',
              name: 'Kuramanime',
              kind: MediaKindDto.anime,
              enabled: true,
              skipped: false,
              summary: '',
            ),
          ];
        },
      );
      await tester.tap(find.text('Bukan ini?'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Lupakan pilihan saya'));
      await tester.pumpAndSettle();
      expect(opened.harness.catalog.forgotten, [filmId.toString()]);
    });
  });
  group('limited data', () {
    testWidgets('a site-only title says so and still lists episodes', (
      tester,
    ) async {
      await open(tester, view: siteView());
      expect(find.text('Judul Situs'), findsOneWidget);
      expect(find.text('Data terbatas'), findsOneWidget);
      expect(find.text('Sinopsis belum tersedia.'), findsOneWidget);
      expect(find.text('Tonton Episode 1'), findsOneWidget);
    });

    testWidgets('its info tab shows what the site knows', (tester) async {
      await open(tester, view: siteView());
      await tester.tap(find.text('Info'));
      await tester.pumpAndSettle();
      await scrollTo(tester, find.text('Terbaru'));
      expect(find.text('Tipe'), findsOneWidget);
      expect(find.text('Terbaru'), findsOneWidget);
    });
  });
}
