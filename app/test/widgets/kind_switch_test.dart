import 'package:flutter/semantics.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kolektaku/src/rust/dto/media.dart';
import 'package:kolektaku/widgets/kind_switch.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import 'widget_harness.dart';

Future<List<MediaKindDto>> show(WidgetTester tester, MediaKindDto value) async {
  final chosen = <MediaKindDto>[];
  await pumpAtSize(
    tester,
    Align(
      alignment: Alignment.topCenter,
      child: KindSwitch(value: value, onChanged: chosen.add),
    ),
  );
  return chosen;
}

Color? fillOf(WidgetTester tester, String key) {
  final box = tester.widget<DecoratedBox>(
    find.descendant(
      of: find.byKey(Key(key)),
      matching: find.byType(DecoratedBox),
    ),
  );
  return (box.decoration as BoxDecoration).color;
}

void main() {
  group('labels and icons', () {
    test('anime gets a film and comics get an open book', () {
      expect(kindSwitchLabel(MediaKindDto.anime), 'Anime');
      expect(kindSwitchLabel(MediaKindDto.manga), 'Komik');
      expect(kindSwitchIcon(MediaKindDto.anime), LucideIcons.film);
      expect(kindSwitchIcon(MediaKindDto.manga), LucideIcons.bookOpen);
    });

    test('novels are named and get their own icon', () {
      expect(kindSwitchLabel(MediaKindDto.novel), 'Novel');
      expect(kindSwitchIcon(MediaKindDto.novel), LucideIcons.bookText);
    });
  });

  group('KindSwitch', () {
    testWidgets('shows both kinds with their icons in two equal halves', (
      tester,
    ) async {
      await show(tester, MediaKindDto.anime);
      expect(find.text('Anime'), findsOneWidget);
      expect(find.text('Komik'), findsOneWidget);
      expect(find.byIcon(LucideIcons.film), findsOneWidget);
      expect(find.byIcon(LucideIcons.bookOpen), findsOneWidget);
      final anime = tester.getSize(find.byKey(const Key('kind-anime')));
      final comic = tester.getSize(find.byKey(const Key('kind-manga')));
      expect(anime.width, comic.width);
    });

    testWidgets('novels are the third equal part', (tester) async {
      await show(tester, MediaKindDto.novel);
      expect(find.text('Novel'), findsOneWidget);
      expect(find.byIcon(LucideIcons.bookText), findsOneWidget);
      final anime = tester.getSize(find.byKey(const Key('kind-anime')));
      final novel = tester.getSize(find.byKey(const Key('kind-novel')));
      expect(novel.width, anime.width);
      final comicAt = tester.getTopLeft(find.byKey(const Key('kind-manga')));
      final novelAt = tester.getTopLeft(find.byKey(const Key('kind-novel')));
      expect(novelAt.dx, greaterThan(comicAt.dx));
    });

    testWidgets('the active half is yellow and the other one is dark', (
      tester,
    ) async {
      await show(tester, MediaKindDto.anime);
      final active = fillOf(tester, 'kind-anime');
      final inactive = fillOf(tester, 'kind-manga');
      expect(active, isNot(inactive));
      await show(tester, MediaKindDto.manga);
      expect(fillOf(tester, 'kind-manga'), active);
      expect(fillOf(tester, 'kind-anime'), inactive);
    });

    testWidgets('tapping a half reports its kind', (tester) async {
      final chosen = await show(tester, MediaKindDto.anime);
      await tester.tap(find.byKey(const Key('kind-manga')));
      await tester.tap(find.byKey(const Key('kind-anime')));
      expect(chosen, [MediaKindDto.manga, MediaKindDto.anime]);
    });

    testWidgets('the selected half is announced as selected', (tester) async {
      await show(tester, MediaKindDto.manga);
      final selected = tester.getSemantics(find.byKey(const Key('kind-manga')));
      final other = tester.getSemantics(find.byKey(const Key('kind-anime')));
      expect(selected.label, contains('Komik'));
      expect(selected.hasFlag(SemanticsFlag.isSelected), isTrue);
      expect(selected.hasFlag(SemanticsFlag.isButton), isTrue);
      expect(other.hasFlag(SemanticsFlag.isSelected), isFalse);
    });
  });
}
