import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kolektaku/features/home/home_actions.dart';
import 'package:kolektaku/features/home/resume_rail.dart';
import 'package:kolektaku/src/rust/dto/library.dart';
import 'package:kolektaku/src/rust/dto/media.dart';

import '../../support/screen_harness.dart';
import '../collection/collection_support.dart';

HomeActions noActions(List<ProgressDto> opened) => HomeActions(
  onOpen: (kind, card) {},
  onResume: opened.add,
  onGenre: (kind, genre) {},
  onAllGenres: (kind) {},
);

List<ProgressDto> mixed() => [
  progress(1, title: 'Tontonan Satu'),
  progress(2, kind: MediaKindDto.manga, title: 'Bacaan Dua'),
  progress(3, title: 'Tontonan Tiga'),
  progress(4, kind: MediaKindDto.novel, title: 'Novel Empat'),
];

void main() {
  group('resumeOf', () {
    test('no filter keeps everything in order', () {
      expect(resumeOf(mixed(), null).map((item) => item.title), [
        'Tontonan Satu',
        'Bacaan Dua',
        'Tontonan Tiga',
        'Novel Empat',
      ]);
    });

    test('a kind keeps only that kind', () {
      expect(resumeOf(mixed(), MediaKindDto.manga).map((item) => item.title), [
        'Bacaan Dua',
      ]);
      expect(resumeOf(mixed(), MediaKindDto.anime), hasLength(2));
      expect(resumeOf(mixed(), MediaKindDto.novel).map((item) => item.title), [
        'Novel Empat',
      ]);
    });
  });

  group('ResumeRail', () {
    Future<List<ProgressDto>> show(WidgetTester tester) async {
      final opened = <ProgressDto>[];
      await ScreenHarness().pump(
        tester,
        Align(
          alignment: Alignment.topCenter,
          child: ResumeRail(items: mixed(), actions: noActions(opened)),
        ),
      );
      return opened;
    }

    testWidgets('has the title with a filter for each kind on its right', (
      tester,
    ) async {
      await show(tester);
      final title = tester.getTopLeft(find.text('Lanjutkan'));
      final anime = tester.getTopLeft(
        find.byKey(const Key('resume-filter-anime')),
      );
      final comic = tester.getTopLeft(
        find.byKey(const Key('resume-filter-manga')),
      );
      final novel = tester.getTopRight(
        find.byKey(const Key('resume-filter-novel')),
      );
      expect(anime.dx, greaterThan(title.dx));
      expect(comic.dx, greaterThan(anime.dx));
      expect(novel.dx, greaterThan(300));
      expect((anime.dy - title.dy).abs(), lessThan(20));
    });

    testWidgets(
      'choosing a kind hides the other, choosing it again shows all',
      (tester) async {
        await show(tester);
        expect(find.text('Bacaan Dua'), findsOneWidget);
        await tester.tap(find.byKey(const Key('resume-filter-anime')));
        await tester.pump();
        expect(find.text('Bacaan Dua'), findsNothing);
        expect(find.text('Tontonan Satu'), findsOneWidget);
        await tester.tap(find.byKey(const Key('resume-filter-anime')));
        await tester.pump();
        expect(find.text('Bacaan Dua'), findsOneWidget);
      },
    );

    testWidgets('the novel filter shows only novels', (tester) async {
      await show(tester);
      await tester.tap(find.byKey(const Key('resume-filter-novel')));
      await tester.pump();
      expect(find.text('Novel Empat'), findsOneWidget);
      expect(find.text('Bacaan Dua'), findsNothing);
      expect(find.text('Tontonan Satu'), findsNothing);
    });

    testWidgets('a card reports the progress it belongs to', (tester) async {
      final opened = await show(tester);
      await tester.tap(find.byKey(const Key('resume-filter-manga')));
      await tester.pump();
      await tester.tap(find.text('Bacaan Dua'));
      expect(opened.single.title, 'Bacaan Dua');
    });
  });
}
