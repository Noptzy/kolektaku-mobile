import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kolektaku/data/providers/settings_providers.dart';
import 'package:kolektaku/features/dev/gallery/sample_media.dart';
import 'package:kolektaku/features/home/home_screen.dart';
import 'package:kolektaku/features/settings/settings_edit.dart';
import 'package:kolektaku/src/rust/dto/cards.dart';
import 'package:kolektaku/src/rust/dto/library.dart';
import 'package:kolektaku/src/rust/dto/media.dart';
import 'package:kolektaku/src/rust/dto/sources.dart';

import '../../support/screen_harness.dart';

List<MediaCardDto> _cards(String prefix, String word, int count, int base) => [
  for (var i = 1; i <= count; i++)
    sampleCard(base + i, title: '$prefix $word $i'),
];

HomeDto homeOf(String prefix, {int trending = 10, bool weekly = true}) {
  final base = prefix == 'M' ? 1000 : 0;
  return HomeDto(
    sections: [
      HomeSectionDto(
        id: 'trending',
        cards: _cards(prefix, 'top', trending, base),
      ),
      HomeSectionDto(
        id: 'latest',
        cards: _cards(prefix, 'baru', 4, base + 200),
      ),
      HomeSectionDto(
        id: 'seasonal',
        cards: _cards(prefix, 'musim', 4, base + 300),
      ),
      HomeSectionDto(
        id: 'popular',
        cards: _cards(prefix, 'populer', 4, base + 400),
      ),
      if (weekly) ...[
        HomeSectionDto(
          id: 'top_rated',
          cards: _cards(prefix, 'rating', 2, base + 500),
        ),
        HomeSectionDto(
          id: 'new_week',
          cards: _cards(prefix, 'terbaru', 2, base + 600),
        ),
        HomeSectionDto(
          id: 'finished_week',
          cards: _cards(prefix, 'tamat', 2, base + 700),
        ),
        HomeSectionDto(
          id: 'returning',
          cards: _cards(prefix, 'comeback', 2, base + 800),
        ),
      ],
    ],
    notices: const [],
  );
}

ProgressDto progress(
  MediaKindDto kind,
  String title, {
  int updated = 0,
  int id = 77,
}) => ProgressDto(
  reference: sampleCard(id).reference,
  kind: kind,
  unitNumber: 3,
  title: title,
  position: 600,
  length: 1200,
  updatedAtSecs: BigInt.from(updated),
  completed: false,
);

Future<ScreenHarness> openHome(
  WidgetTester tester, {
  bool prefersAnime = true,
  void Function(ScreenHarness harness)? prepare,
  Size size = const Size(390, 844),
}) async {
  final harness = ScreenHarness();
  harness.settings.stored = defaultSettings.copyWith(
    prefersAnime: prefersAnime,
  );
  harness.catalog.genreResult = const [
    GenreDto(slug: 'action', name: 'Action'),
    GenreDto(slug: 'comedy', name: 'Comedy'),
  ];
  prepare?.call(harness);
  if (harness.catalog.homeError == null) {
    harness.catalog.onHome ??= (kind) async =>
        kind == MediaKindDto.anime ? homeOf('A') : homeOf('M');
  }
  await harness.pump(tester, const HomeScreen(), size: size);
  return harness;
}
