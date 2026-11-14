import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kolektaku/data/providers/settings_providers.dart';
import 'package:kolektaku/features/settings/settings_edit.dart';
import 'package:kolektaku/features/settings/settings_page_screen.dart';
import 'package:kolektaku/features/settings/settings_pages.dart';
import 'package:kolektaku/src/rust/dto/media.dart';
import 'package:kolektaku/src/rust/dto/settings.dart';
import 'package:kolektaku/src/rust/dto/sources.dart';
import 'package:kolektaku/widgets/option_chip.dart';

import '../../support/screen_harness.dart';

SourceStatusDto anime(String id, String summary) => SourceStatusDto(
  id: id,
  name: 'Rahasia $id',
  kind: MediaKindDto.anime,
  enabled: true,
  skipped: false,
  summary: summary,
);

Future<ScreenHarness> open(
  WidgetTester tester, {
  List<SourceStatusDto> sources = const [],
  SettingsPage page = SettingsPage.preference,
  SettingsDto? stored,
}) async {
  final harness = ScreenHarness();
  harness.sources.statuses = sources;
  if (stored != null) harness.settings.stored = stored;
  await harness.pump(
    tester,
    SettingsPageScreen(page: page),
    size: const Size(390, 3200),
  );
  return harness;
}

bool selected(WidgetTester tester, String label) =>
    tester.widget<OptionChip>(find.widgetWithText(OptionChip, label)).selected;

Future<void> tapChip(WidgetTester tester, String label) async {
  await tester.tap(find.widgetWithText(OptionChip, label));
  await tester.pumpAndSettle();
}

void main() {
  group('home preference', () {
    testWidgets('anime is the default choice', (tester) async {
      await open(tester);
      expect(selected(tester, 'Anime'), isTrue);
      expect(selected(tester, 'Manga'), isFalse);
    });

    testWidgets('choosing manga is saved', (tester) async {
      final harness = await open(tester);
      await tapChip(tester, 'Manga');
      expect(harness.settings.saves.single.prefersAnime, isFalse);
      expect(selected(tester, 'Manga'), isTrue);
    });

    testWidgets('a stored choice is shown when the screen opens', (
      tester,
    ) async {
      await open(tester, stored: defaultSettings.copyWith(prefersAnime: false));
      expect(selected(tester, 'Manga'), isTrue);
      expect(selected(tester, 'Anime'), isFalse);
    });

    testWidgets('a failed save puts the old choice back', (tester) async {
      final harness = await open(tester);
      harness.settings.failSaves = true;
      await tapChip(tester, 'Manga');
      expect(selected(tester, 'Anime'), isTrue);
    });
  });

  group('preferred anime source', () {
    final sources = [
      anime('first', 'Subtitle Indonesia selalu tersedia.'),
      anime('second', 'Kebanyakan subtitle Inggris.'),
    ];

    testWidgets('automatic is chosen until the user picks one', (tester) async {
      await open(tester, sources: sources, page: SettingsPage.sourceChoice);
      expect(find.text('Otomatis'), findsWidgets);
      expect(find.text('Subtitle Indonesia selalu tersedia.'), findsOneWidget);
      expect(find.text('Kebanyakan subtitle Inggris.'), findsOneWidget);
    });

    testWidgets('each source is numbered and its difference is explained', (
      tester,
    ) async {
      await open(tester, sources: sources, page: SettingsPage.sourceChoice);
      expect(find.byKey(const Key('source-choice-first')), findsOneWidget);
      expect(find.byKey(const Key('source-choice-second')), findsOneWidget);
      expect(find.textContaining('Rahasia'), findsNothing);
    });

    testWidgets('choosing the second source saves its id', (tester) async {
      final harness = await open(
        tester,
        sources: sources,
        page: SettingsPage.sourceChoice,
      );
      await tester.tap(find.byKey(const Key('source-choice-second')));
      await tester.pumpAndSettle();
      expect(harness.settings.saves.single.animeSource, 'second');
    });

    testWidgets('choosing automatic clears the preference', (tester) async {
      final harness = await open(
        tester,
        sources: sources,
        page: SettingsPage.sourceChoice,
      );
      await tester.tap(find.byKey(const Key('source-choice-second')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('source-choice-auto')));
      await tester.pumpAndSettle();
      expect(harness.settings.saves.last.animeSource, isNull);
    });

    testWidgets('the other settings survive a source change', (tester) async {
      final harness = await open(
        tester,
        sources: sources,
        page: SettingsPage.sourceChoice,
        stored: defaultSettings.copyWith(prefersAnime: false),
      );
      await tester.tap(find.byKey(const Key('source-choice-first')));
      await tester.pumpAndSettle();
      expect(harness.settings.saves.last.prefersAnime, isFalse);
      expect(harness.settings.saves.last.animeSource, 'first');
    });

    testWidgets('manga sources are not offered as a video source', (
      tester,
    ) async {
      await open(
        tester,
        sources: [
          SourceStatusDto(
            id: 'm',
            name: 'x',
            kind: MediaKindDto.manga,
            enabled: true,
            skipped: false,
            summary: '',
          ),
        ],
        page: SettingsPage.sourceChoice,
      );
      expect(find.byKey(const Key('source-choice-auto')), findsNothing);
    });
  });
}
