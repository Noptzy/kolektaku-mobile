import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kolektaku/core/routes.dart';
import 'package:kolektaku/features/collection/collection_screen.dart';
import 'package:kolektaku/features/detail/detail_request.dart';
import 'package:kolektaku/src/rust/dto/library.dart';
import 'package:kolektaku/src/rust/dto/media.dart';

import '../../support/screen_harness.dart';
import '../detail/detail_support.dart';

const now = 2000000;

ProgressDto progress(
  int id, {
  MediaKindDto kind = MediaKindDto.anime,
  double unit = 2,
  String? title,
  bool completed = false,
  int savedAgo = 7200,
}) {
  return ProgressDto(
    reference: ref(id),
    kind: kind,
    unitNumber: unit,
    title: title ?? 'Judul $id',
    position: 600,
    length: 1200,
    updatedAtSecs: BigInt.from(now - savedAgo),
    completed: completed,
  );
}

FavoriteDto favorite(
  int id, {
  MediaKindDto kind = MediaKindDto.anime,
  String? title,
}) {
  return FavoriteDto(
    reference: ref(id),
    kind: kind,
    title: title ?? 'Favorit $id',
    addedAtSecs: BigInt.zero,
  );
}

Future<ScreenHarness> open(
  WidgetTester tester, {
  List<ProgressDto> history = const [],
  List<ProgressDto> resumable = const [],
  List<FavoriteDto> favorites = const [],
}) async {
  final harness = ScreenHarness();
  harness.library.historyResult = history;
  harness.library.continueResult = resumable;
  harness.library.favoriteResult = favorites;
  await harness.pump(tester, CollectionScreen(now: () => now));
  return harness;
}

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
    expect(find.text('Episode 2 · 50%'), findsOneWidget);
    expect(find.text('2 jam lalu'), findsOneWidget);
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
    expect(find.text('Chapter 2 · Hal. 600 dari 1200'), findsOneWidget);
  });

  testWidgets('a history row opens the detail of its title', (tester) async {
    final harness = await open(tester, history: [progress(5, title: 'Buka')]);
    await tester.tap(find.text('Buka'));
    await tester.pumpAndSettle();
    final visit = harness.visits.single;
    expect(visit.path, Routes.detail);
    final request = visit.extra! as DetailRequest;
    expect(request.kind, MediaKindDto.anime);
    expect(request.reference, ref(5));
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
    await tester.tap(find.byKey(Key('remove-history-${ref(1).id}|2.0')));
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
    await tester.tap(find.byKey(Key('remove-history-${ref(1).id}|2.0')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('undo')));
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
    await tester.tap(find.byKey(const Key('undo')));
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

  testWidgets('the settings button opens the settings', (tester) async {
    final harness = await open(tester);
    await tester.tap(find.byKey(const Key('open-settings')));
    await tester.pumpAndSettle();
    expect(harness.visits.single.path, Routes.settings);
  });

  testWidgets('a finished item shows no progress bar', (tester) async {
    await open(tester, history: [progress(1, completed: true)]);
    expect(find.text('Episode 2 · Selesai'), findsOneWidget);
  });
}
