import 'package:flutter/semantics.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kolektaku/features/dev/gallery/sample_media.dart';
import 'package:kolektaku/features/home/top10_section.dart';
import 'package:kolektaku/src/rust/dto/cards.dart';
import 'package:kolektaku/src/rust/dto/media.dart';
import 'package:kolektaku/widgets/top10_rail.dart';

import '../../widgets/widget_harness.dart';

List<MediaCardDto> _cards(String prefix, int count) => [
  for (var i = 1; i <= count; i++) sampleCard(i, title: '$prefix $i'),
];

Future<List<(MediaKindDto, MediaCardDto)>> _show(
  WidgetTester tester,
  Map<MediaKindDto, List<MediaCardDto>> cards,
) async {
  final tapped = <(MediaKindDto, MediaCardDto)>[];
  await pumpAtSize(
    tester,
    Align(
      alignment: Alignment.topLeft,
      child: Top10Section(
        cards: cards,
        onTap: (kind, card) => tapped.add((kind, card)),
      ),
    ),
  );
  return tapped;
}

void main() {
  testWidgets('one rail under one title, with a switch between kinds', (
    tester,
  ) async {
    await _show(tester, {
      MediaKindDto.anime: _cards('Anime', 3),
      MediaKindDto.manga: _cards('Komik', 3),
    });
    expect(find.text(top10Title), findsOneWidget);
    expect(find.byKey(const Key('top10-switch-anime')), findsOneWidget);
    expect(find.byKey(const Key('top10-switch-manga')), findsOneWidget);
    expect(find.byType(Top10List), findsOneWidget);
  });

  testWidgets('starts on the first kind given', (tester) async {
    await _show(tester, {
      MediaKindDto.manga: _cards('Komik', 3),
      MediaKindDto.anime: _cards('Anime', 3),
    });
    expect(find.text('Komik 1'), findsOneWidget);
    expect(find.text('Anime 1'), findsNothing);
  });

  testWidgets('the switch changes which kind is ranked', (tester) async {
    await _show(tester, {
      MediaKindDto.anime: _cards('Anime', 3),
      MediaKindDto.manga: _cards('Komik', 3),
    });
    expect(find.text('Anime 1'), findsOneWidget);
    await tester.tap(find.byKey(const Key('top10-switch-manga')));
    await tester.pumpAndSettle();
    expect(find.text('Komik 1'), findsOneWidget);
    expect(find.text('Anime 1'), findsNothing);
    await tester.tap(find.byKey(const Key('top10-switch-anime')));
    await tester.pumpAndSettle();
    expect(find.text('Anime 1'), findsOneWidget);
  });

  testWidgets('a tap reports the kind it was ranked under', (tester) async {
    final tapped = await _show(tester, {
      MediaKindDto.anime: _cards('Anime', 3),
      MediaKindDto.manga: _cards('Komik', 3),
    });
    await tester.tap(find.byKey(const Key('top10-switch-manga')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Komik 2'));
    expect(tapped.single.$1, MediaKindDto.manga);
    expect(tapped.single.$2.title, 'Komik 2');
  });

  testWidgets('with only one kind ranked there is no switch', (tester) async {
    await _show(tester, {
      MediaKindDto.anime: _cards('Anime', 3),
      MediaKindDto.manga: const [],
    });
    expect(find.byKey(const Key('top10-switch-anime')), findsNothing);
    expect(find.text('Anime 1'), findsOneWidget);
  });

  testWidgets('with nothing ranked it takes no room', (tester) async {
    await _show(tester, {
      MediaKindDto.anime: const [],
      MediaKindDto.manga: const [],
    });
    expect(find.text(top10Title), findsNothing);
    expect(tester.getSize(find.byType(Top10Section)).height, 0);
  });

  testWidgets('the switch segments are at least 48 dp tall', (tester) async {
    await _show(tester, {
      MediaKindDto.anime: _cards('Anime', 3),
      MediaKindDto.manga: _cards('Komik', 3),
    });
    for (final kind in ['anime', 'manga']) {
      final size = tester.getSize(find.byKey(Key('top10-switch-$kind')));
      expect(size.height, greaterThanOrEqualTo(48), reason: kind);
    }
  });

  testWidgets('the chosen segment is announced as selected', (tester) async {
    await _show(tester, {
      MediaKindDto.anime: _cards('Anime', 3),
      MediaKindDto.manga: _cards('Komik', 3),
    });
    bool selected(String kind) => tester
        .getSemantics(find.byKey(Key('top10-switch-$kind')))
        .hasFlag(SemanticsFlag.isSelected);
    expect(selected('anime'), isTrue);
    expect(selected('manga'), isFalse);
    await tester.tap(find.byKey(const Key('top10-switch-manga')));
    await tester.pumpAndSettle();
    expect(selected('manga'), isTrue);
    expect(selected('anime'), isFalse);
  });
}
