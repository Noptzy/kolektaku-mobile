import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kolektaku/features/detail/detail_request.dart';
import 'package:kolektaku/features/detail/detail_screen.dart';
import 'package:kolektaku/features/detail/source_names.dart';
import 'package:kolektaku/src/rust/dto/media.dart';
import 'package:kolektaku/src/rust/dto/sources.dart';

import '../../support/screen_harness.dart';
import 'detail_support.dart';

SourceStatusDto status(String id, {String summary = ''}) => SourceStatusDto(
  id: id,
  name: 'Rahasia $id',
  kind: MediaKindDto.anime,
  enabled: true,
  skipped: false,
  summary: summary,
);

Future<ScreenHarness> open(
  WidgetTester tester, {
  int unitCount = 12,
  int? expected,
  List<SourceStatusDto> statuses = const [],
}) async {
  final harness = ScreenHarness();
  harness.sources.statuses = statuses;
  harness.catalog.detailResult = catalogView(
    head: detail(head: summary(units: expected)),
    sources: [
      link('kura', units: unitCount),
      link('b', units: unitCount),
    ],
  );
  harness.catalog.unitsResult = units(unitCount);
  await harness.pump(
    tester,
    DetailScreen(
      request: DetailRequest(kind: MediaKindDto.anime, reference: ref(filmId)),
    ),
    size: const Size(390, 1600),
  );
  return harness;
}

void main() {
  group('logic', () {
    test('the names follow the numbering used in the settings', () {
      final names = sourceNamesOf([
        status('a', summary: 'Subtitle Indonesia.'),
        status('b'),
      ], MediaKindDto.anime);
      expect(names.labels, {'a': 'Sumber anime 1', 'b': 'Sumber anime 2'});
      expect(names.summaries, {'a': 'Subtitle Indonesia.'});
    });

    test('only sources of the right kind are numbered', () {
      final manga = SourceStatusDto(
        id: 'm',
        name: 'x',
        kind: MediaKindDto.manga,
        enabled: true,
        skipped: false,
        summary: '',
      );
      final names = sourceNamesOf([status('a'), manga], MediaKindDto.manga);
      expect(names.labels, {'m': 'Sumber manga 1'});
    });

    test('a short list says how much is missing', () {
      expect(
        completenessNote(
          kind: MediaKindDto.anime,
          loaded: 8,
          expected: 12,
          canSwitch: false,
        ),
        'Baru ada 8 dari 12 episode di sumber ini.',
      );
      expect(
        completenessNote(
          kind: MediaKindDto.manga,
          loaded: 8,
          expected: 12,
          canSwitch: true,
        ),
        'Baru ada 8 dari 12 chapter di sumber ini. Coba ganti sumber.',
      );
    });

    test('a complete or unknown list needs no note', () {
      for (final expected in [null, 0, 12, 10]) {
        expect(
          completenessNote(
            kind: MediaKindDto.anime,
            loaded: 12,
            expected: expected,
            canSwitch: true,
          ),
          isNull,
        );
      }
    });

    test('the source line joins the name and what the source is like', () {
      expect(
        sourceLine('Sumber anime 1', 'Subtitle Indonesia.'),
        'Sumber anime 1 · Subtitle Indonesia.',
      );
      expect(sourceLine('Sumber anime 1', null), 'Sumber anime 1');
      expect(sourceLine(null, 'x'), isNull);
    });
  });

  group('detail page', () {
    testWidgets(
      'says which source the episodes come from and what it is like',
      (tester) async {
        await open(
          tester,
          statuses: [
            status('kura', summary: 'Subtitle Indonesia selalu tersedia.'),
            status('b', summary: 'Kebanyakan subtitle Inggris.'),
          ],
        );
        final line = tester.widget<Text>(find.byKey(const Key('source-line')));
        expect(line.data, startsWith('Sumber anime'));
        expect(line.data, contains('·'));
        expect(find.textContaining('Rahasia'), findsNothing);
      },
    );

    testWidgets('warns when the source has fewer episodes than the catalog', (
      tester,
    ) async {
      await open(
        tester,
        unitCount: 8,
        expected: 12,
        statuses: [status('kura'), status('b')],
      );
      final note = tester.widget<Text>(
        find.byKey(const Key('source-completeness')),
      );
      expect(note.data, contains('8 dari 12 episode'));
      expect(note.data, contains('ganti sumber'));
    });

    testWidgets('stays quiet when the list is complete', (tester) async {
      await open(
        tester,
        unitCount: 12,
        expected: 12,
        statuses: [status('kura')],
      );
      expect(find.byKey(const Key('source-completeness')), findsNothing);
    });

    testWidgets('the source sheet uses the same names and descriptions', (
      tester,
    ) async {
      await open(
        tester,
        statuses: [
          status('kura', summary: 'Subtitle Indonesia selalu tersedia.'),
          status('b', summary: 'Kebanyakan subtitle Inggris.'),
        ],
      );
      await tester.tap(find.text('Ganti sumber'));
      await tester.pumpAndSettle();
      expect(find.text('Sumber anime 1'), findsWidgets);
      expect(find.text('Sumber anime 2'), findsWidgets);
      expect(find.byKey(const Key('source-summary-kura')), findsOneWidget);
      expect(find.byKey(const Key('source-summary-b')), findsOneWidget);
    });
  });
}
