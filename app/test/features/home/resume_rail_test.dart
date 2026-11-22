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

    testWidgets('has the title and no kind filters beside it', (tester) async {
      await show(tester);
      expect(find.text('Lanjutkan'), findsOneWidget);
      for (final kind in ['anime', 'manga', 'novel']) {
        expect(find.byKey(Key('resume-filter-$kind')), findsNothing);
      }
    });

    testWidgets('lists the cards side by side in the order given', (
      tester,
    ) async {
      await show(tester);
      final first = tester.getTopLeft(find.text('Tontonan Satu')).dx;
      final second = tester.getTopLeft(find.text('Bacaan Dua')).dx;
      expect(second, greaterThan(first));
    });

    testWidgets('scrolling reaches the cards further along', (tester) async {
      await show(tester);
      expect(find.text('Novel Empat'), findsNothing);
      await tester.drag(find.byType(ListView), const Offset(-900, 0));
      await tester.pumpAndSettle();
      expect(find.text('Novel Empat'), findsOneWidget);
    });

    testWidgets('a card reports the progress it belongs to', (tester) async {
      final opened = await show(tester);
      await tester.drag(find.byType(ListView), const Offset(-320, 0));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Bacaan Dua'));
      expect(opened.single.title, 'Bacaan Dua');
      expect(opened.single.kind, MediaKindDto.manga);
    });

    testWidgets('each kind carries its own label on its card', (tester) async {
      await show(tester);
      expect(find.text('Anime'), findsOneWidget);
      expect(find.text('Komik'), findsOneWidget);
      await tester.drag(find.byType(ListView), const Offset(-900, 0));
      await tester.pumpAndSettle();
      expect(find.text('Novel'), findsOneWidget);
    });
  });
}
