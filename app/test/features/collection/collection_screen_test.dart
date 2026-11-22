import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:kolektaku/features/detail/detail_request.dart';
import 'package:kolektaku/src/rust/dto/media.dart';

import '../detail/detail_support.dart' show ref;
import 'collection_support.dart';

void main() {
  testWidgets('an empty collection says what is missing in each part', (
    tester,
  ) async {
    await open(tester);
    expect(find.text('Koleksiku'), findsOneWidget);
    expect(find.textContaining('Belum ada anime favorit'), findsOneWidget);
    expect(find.text('Belum ada yang ditonton.'), findsOneWidget);
    expect(find.byKey(const Key('clear-history')), findsNothing);
    expect(find.text('Lanjut nonton'), findsNothing);
  });

  testWidgets('favorites, history and the continue rail show their titles', (
    tester,
  ) async {
    await open(
      tester,
      history: [progress(1, title: 'Riwayat Satu')],
      resumable: [progress(2, title: 'Lanjutan Dua')],
      favorites: [favorite(3, title: 'Favorit Tiga')],
    );
    expect(find.text('Lanjut nonton'), findsOneWidget);
    expect(find.text('Lanjutan Dua'), findsOneWidget);
    expect(find.text('Favorit Tiga'), findsOneWidget);
    expect(find.text('Riwayat Satu'), findsOneWidget);
    expect(find.text('Episode 2'), findsNWidgets(2));
  });

  testWidgets('the kind switch shows the other kind only', (tester) async {
    await open(
      tester,
      history: [
        progress(1, title: 'Tontonan'),
        progress(2, kind: MediaKindDto.manga, title: 'Bacaan'),
      ],
      favorites: [favorite(3, kind: MediaKindDto.manga, title: 'Komik Fav')],
    );
    expect(find.text('Tontonan'), findsOneWidget);
    expect(find.text('Bacaan'), findsNothing);
    await tester.tap(find.byKey(const Key('kind-manga')));
    await tester.pumpAndSettle();
    expect(find.text('Bacaan'), findsOneWidget);
    expect(find.text('Komik Fav'), findsOneWidget);
    expect(find.text('Tontonan'), findsNothing);
    expect(find.text('Belum ada yang dibaca.'), findsNothing);
    expect(find.text('Chapter 2'), findsOneWidget);
  });

  testWidgets('novels have their own part of the collection', (tester) async {
    final harness = await open(
      tester,
      history: [
        progress(1, title: 'Tontonan'),
        progress(2, kind: MediaKindDto.novel, title: 'Bacaan Novel'),
      ],
      favorites: [favorite(3, kind: MediaKindDto.novel, title: 'Novel Fav')],
    );
    await tester.tap(find.byKey(const Key('kind-novel')));
    await tester.pumpAndSettle();
    expect(find.text('Bacaan Novel'), findsOneWidget);
    expect(find.text('Novel Fav'), findsOneWidget);
    expect(find.text('Tontonan'), findsNothing);
    expect(find.text('Chapter 2'), findsOneWidget);
    await tester.tap(find.text('Novel Fav'));
    await tester.pumpAndSettle();
    final request = harness.visits.single.extra! as DetailRequest;
    expect(request.kind, MediaKindDto.novel);
  });

  testWidgets('a favorite opens its detail too', (tester) async {
    final harness = await open(tester, favorites: [favorite(6, title: 'Fav')]);
    await tester.tap(find.text('Fav'));
    await tester.pumpAndSettle();
    expect((harness.visits.single.extra! as DetailRequest).reference, ref(6));
  });

  testWidgets('removing a history row hides it and offers an undo', (
    tester,
  ) async {
    final harness = await open(tester, history: [progress(1, title: 'Hapus')]);
    await tester.drag(find.text('Hapus'), const Offset(-600, 0));
    await tester.pumpAndSettle();
    expect(find.text('Hapus'), findsNothing);
    expect(find.text('Dihapus dari riwayat.'), findsOneWidget);
    expect(harness.library.removed, ['${ref(1).id}|2.0']);
  });

  testWidgets('the undo puts the history row back', (tester) async {
    final harness = await open(
      tester,
      history: [progress(1, title: 'Kembali')],
    );
    await tester.drag(find.text('Kembali'), const Offset(600, 0));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('toast-action')));
    await tester.pumpAndSettle();
    expect(harness.library.saved.single.title, 'Kembali');
  });

  testWidgets('removing a favorite hides it and the undo brings it back', (
    tester,
  ) async {
    final harness = await open(
      tester,
      favorites: [favorite(4, title: 'Lepas')],
    );
    await tester.tap(find.byKey(const Key('remove-card')));
    await tester.pumpAndSettle();
    expect(find.text('Lepas'), findsNothing);
    expect(find.text('Dihapus dari favorit.'), findsOneWidget);
    expect(harness.library.favoriteResult, isEmpty);
    await tester.tap(find.byKey(const Key('toast-action')));
    await tester.pumpAndSettle();
    expect(harness.library.favoriteResult.single.title, 'Lepas');
    expect(find.text('Lepas'), findsOneWidget);
  });

  testWidgets('delete all asks first and does nothing when cancelled', (
    tester,
  ) async {
    final harness = await open(tester, history: [progress(1, title: 'Tetap')]);
    await tester.tap(find.byKey(const Key('clear-history')));
    await tester.pumpAndSettle();
    expect(find.text('Hapus semua riwayat?'), findsOneWidget);
    await tester.tap(find.byKey(const Key('confirm-cancel')));
    await tester.pumpAndSettle();
    expect(harness.library.cleared, isEmpty);
    expect(find.text('Tetap'), findsOneWidget);
  });

  testWidgets('delete all clears only this kind once confirmed', (
    tester,
  ) async {
    final harness = await open(
      tester,
      history: [
        progress(1, title: 'Anime Satu'),
        progress(2, kind: MediaKindDto.manga, title: 'Manga Satu'),
      ],
    );
    await tester.tap(find.byKey(const Key('clear-history')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('confirm-ok')));
    await tester.pumpAndSettle();
    expect(harness.library.cleared, ['history|anime']);
    expect(find.text('Anime Satu'), findsNothing);
    expect(find.text('Belum ada yang ditonton.'), findsOneWidget);
    expect(harness.library.historyResult.single.title, 'Manga Satu');
  });

  testWidgets('a finished item reads Selesai with a full bar', (tester) async {
    await open(tester, history: [progress(1, completed: true)]);
    expect(find.text('Episode 2'), findsOneWidget);
    expect(find.text('Selesai'), findsOneWidget);
    final bar = tester.widget<ShadProgress>(find.byType(ShadProgress));
    expect(bar.value, 1);
  });
}
