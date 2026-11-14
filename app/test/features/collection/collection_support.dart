import 'package:flutter_test/flutter_test.dart';
import 'package:kolektaku/features/collection/collection_screen.dart';
import 'package:kolektaku/src/rust/dto/library.dart';
import 'package:kolektaku/src/rust/dto/media.dart';

import '../../support/screen_harness.dart';
import '../detail/detail_support.dart' show ref;

const now = 2000000;

ProgressDto progress(
  int id, {
  MediaKindDto kind = MediaKindDto.anime,
  double unit = 2,
  String? title,
  bool completed = false,
  int savedAgo = 7200,
  double position = 600,
}) {
  return ProgressDto(
    reference: ref(id),
    kind: kind,
    unitNumber: unit,
    title: title ?? 'Judul $id',
    position: position,
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
