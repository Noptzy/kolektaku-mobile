import 'package:flutter_test/flutter_test.dart';
import 'package:kolektaku/features/reader/reader_notices.dart';

import 'reader_harness.dart';

void main() {
  group('readerStartNotice', () {
    test(
      'says nothing when reading starts at the top from the same source',
      () {
        expect(readerStartNotice(switchedFrom: null, startPage: 0), isNull);
      },
    );

    test('names the page when resuming, counting from one', () {
      expect(
        readerStartNotice(switchedFrom: null, startPage: 6),
        'Melanjutkan dari halaman 7.',
      );
    });

    test('mentions a source switch on its own', () {
      expect(
        readerStartNotice(switchedFrom: 'a', startPage: 0),
        'Dibaca dari sumber lain.',
      );
    });

    test('says both in one line when both happened', () {
      expect(
        readerStartNotice(switchedFrom: 'a', startPage: 2),
        'Dibaca dari sumber lain. Melanjutkan dari halaman 3.',
      );
    });
  });

  group('on the reader screen', () {
    testWidgets('resuming announces the page it continues from', (
      tester,
    ) async {
      final harness = ReaderHarness(resume: 3);
      await harness.open(tester);
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Melanjutkan dari halaman 4.'), findsOneWidget);
    });

    testWidgets('a fresh chapter announces nothing', (tester) async {
      final harness = ReaderHarness();
      await harness.open(tester);
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.textContaining('Melanjutkan'), findsNothing);
    });
  });
}
