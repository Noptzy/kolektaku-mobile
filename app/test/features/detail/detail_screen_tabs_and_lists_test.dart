import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:kolektaku/features/detail/detail_request.dart';
import 'package:kolektaku/features/detail/detail_screen.dart';
import 'package:kolektaku/platform/url_opener.dart';
import 'package:kolektaku/src/rust/dto/credits.dart';
import 'package:kolektaku/src/rust/dto/library.dart';
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
  group('tabs', () {
    testWidgets('a character without a voice actor shows only its own side', (
      tester,
    ) async {
      await open(
        tester,
        view: catalogView(
          head: detail(
            characters: [
              CharacterDto(
                id: BigInt.one,
                name: 'Taki',
                role: 'SUPPORTING',
                voiceActors: const [],
              ),
            ],
          ),
        ),
      );
      await tester.tap(find.text('Karakter'));
      await tester.pumpAndSettle();
      expect(find.text('Taki'), findsOneWidget);
      expect(find.text('Pendukung'), findsOneWidget);
      expect(find.textContaining('Jepang'), findsNothing);
    });
    testWidgets('info lists the facts in Indonesian', (tester) async {
      await open(tester);
      await tester.tap(find.text('Info'));
      await tester.pumpAndSettle();
      await scrollTo(tester, find.text('107 menit'));
      expect(find.text('CoMix Wave Films'), findsOneWidget);
      expect(find.text('26 Agu 2016'), findsWidgets);
      expect(find.text('107 menit'), findsOneWidget);
      expect(find.text('Musim panas'), findsOneWidget);
    });
    testWidgets('related names how each title is connected', (tester) async {
      await open(
        tester,
        view: catalogView(
          head: detail(
            relations: [
              RelationDto(
                relationType: 'SEQUEL',
                media: summary(id: 50, title: 'Lanjutan Film'),
              ),
            ],
          ),
        ),
      );
      await tester.ensureVisible(find.text('Terkait').first);
      await tester.tap(find.text('Terkait').first);
      await tester.pumpAndSettle();
      await scrollTo(tester, find.text('Lanjutan Film'));
      expect(find.text('Lanjutan'), findsOneWidget);
      expect(find.text('Lanjutan Film'), findsOneWidget);
    });
    testWidgets('empty tabs say so instead of staying blank', (tester) async {
      await open(tester);
      await tester.tap(find.text('Karakter'));
      await tester.pumpAndSettle();
      await scrollTo(tester, find.text('Data karakter belum tersedia.'));
      expect(find.text('Data karakter belum tersedia.'), findsOneWidget);
      await tester.ensureVisible(find.text('Terkait').first);
      await tester.tap(find.text('Terkait').first);
      await tester.pumpAndSettle();
      await scrollTo(tester, find.text('Belum ada judul terkait.'));
      expect(find.text('Belum ada judul terkait.'), findsOneWidget);
    });
  });
  group('long lists', () {
    testWidgets('are cut in windows of fifty', (tester) async {
      await open(tester, unitCount: 120);
      await scrollTo(tester, find.text('1-50'));
      expect(find.text('51-100'), findsOneWidget);
      expect(find.text('101-120'), findsOneWidget);
      await tester.tap(find.text('51-100'));
      await tester.pumpAndSettle();
      await scrollTo(tester, find.text('Episode 51'));
      expect(find.text('Episode 51'), findsOneWidget);
    });

    testWidgets('jumping to a number opens its window and marks it', (
      tester,
    ) async {
      await open(tester, unitCount: 120);
      await scrollTo(tester, find.text('Lompat'));
      await tester.enterText(find.byType(EditableText).last, '75');
      await tester.tap(find.text('Lompat'));
      await tester.pumpAndSettle();
      await scrollTo(tester, find.text('Episode 75'));
      expect(find.text('Episode 75'), findsOneWidget);
    });

    testWidgets('jumping to a number that is not there says so', (
      tester,
    ) async {
      await open(tester, unitCount: 120);
      await scrollTo(tester, find.text('Lompat'));
      await tester.enterText(find.byType(EditableText).last, '999');
      await tester.tap(find.text('Lompat'));
      await tester.pumpAndSettle();
      expect(find.text('Nomor itu tidak ada di daftar.'), findsOneWidget);
    });

    testWidgets('the order switch puts the newest first and is remembered', (
      tester,
    ) async {
      final opened = await open(tester);
      await scrollTo(tester, find.text('Terlama dulu'));
      await tester.tap(find.text('Terlama dulu'));
      await tester.pumpAndSettle();
      expect(opened.harness.library.order, UnitOrderDto.desc);
      expect(find.text('Terbaru dulu'), findsOneWidget);
    });

    testWidgets('a short list shows no windows or jump box', (tester) async {
      await open(tester);
      await scrollTo(tester, find.text('12 episode'));
      expect(find.text('Lompat'), findsNothing);
    });
  });
}
