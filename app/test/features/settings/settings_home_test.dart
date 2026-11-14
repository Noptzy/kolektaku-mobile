import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kolektaku/data/providers/settings_providers.dart';
import 'package:kolektaku/features/settings/settings_edit.dart';
import 'package:kolektaku/features/settings/settings_logic.dart';
import 'package:kolektaku/features/settings/settings_pages.dart';
import 'package:kolektaku/features/settings/settings_screen.dart';
import 'package:kolektaku/features/settings/settings_summary.dart';
import 'package:kolektaku/src/rust/dto/media.dart';
import 'package:kolektaku/src/rust/dto/settings.dart';
import 'package:kolektaku/src/rust/dto/sources.dart';
import 'package:kolektaku/widgets/option_chip.dart';

import '../../support/screen_harness.dart';

SourceStatusDto anime(String id, {bool enabled = true}) => SourceStatusDto(
  id: id,
  name: 'Rahasia $id',
  kind: MediaKindDto.anime,
  enabled: enabled,
  skipped: false,
  summary: '',
);

Future<ScreenHarness> open(
  WidgetTester tester, {
  List<SourceStatusDto> sources = const [],
  SettingsDto? stored,
}) async {
  final harness = ScreenHarness();
  harness.sources.statuses = sources;
  if (stored != null) harness.settings.stored = stored;
  await harness.pump(
    tester,
    const SettingsScreen(),
    size: const Size(390, 1200),
    extra: [appVersionProvider.overrideWith((ref) async => '2.0.0-rc1')],
  );
  return harness;
}

void main() {
  testWidgets('the home lists one row per page and nothing else', (
    tester,
  ) async {
    await open(tester, sources: [anime('a')]);
    expect(find.text('Pengaturan'), findsOneWidget);
    for (final page in SettingsPage.values) {
      expect(
        find.byKey(Key('settings-row-${page.slug}')),
        findsOneWidget,
        reason: page.slug,
      );
    }
    expect(find.byType(OptionChip), findsNothing);
  });

  testWidgets('rows are grouped under short labels', (tester) async {
    await open(tester, sources: [anime('a')]);
    for (final label in ['Tampilan', 'Menonton', 'Aplikasi']) {
      expect(find.text(label), findsOneWidget, reason: label);
    }
  });

  testWidgets('each row shows what is currently chosen', (tester) async {
    await open(tester, sources: [anime('a'), anime('b')]);
    expect(find.text('Lebih banyak anime'), findsOneWidget);
    expect(find.text('Otomatis'), findsOneWidget);
    expect(find.text('Indonesia · Sedang'), findsOneWidget);
    expect(
      find.text('Kualitas otomatis · berikutnya otomatis'),
      findsOneWidget,
    );
    expect(find.text('2 dari 2 sumber aktif'), findsOneWidget);
    expect(find.text('Versi 2.0.0-rc1'), findsOneWidget);
  });

  testWidgets('the summaries follow the stored settings', (tester) async {
    await open(
      tester,
      sources: [anime('a'), anime('b', enabled: false)],
      stored: defaultSettings
          .withAnimeSource('b')
          .copyWith(
            prefersAnime: false,
            subtitleLanguage: SubtitleLanguageDto.english,
            subtitleSize: SubtitleSizeDto.huge,
            autoSkip: true,
          ),
    );
    expect(find.text('Lebih banyak komik'), findsOneWidget);
    expect(find.text('Sumber anime 2'), findsOneWidget);
    expect(find.text('Inggris · Sangat besar'), findsOneWidget);
    expect(find.text('1 dari 2 sumber aktif'), findsOneWidget);
    expect(
      find.text('Kualitas otomatis · berikutnya otomatis · lewati otomatis'),
      findsOneWidget,
    );
  });

  testWidgets('tapping a row opens its own page', (tester) async {
    final harness = await open(tester, sources: [anime('a')]);
    await tester.tap(find.byKey(const Key('settings-row-subtitle')));
    await tester.pumpAndSettle();
    expect(harness.visits.single.path, SettingsPage.subtitle.path);
  });

  test('summaries say when subtitles are off or the list is empty', () {
    final off = defaultSettings.copyWith(
      subtitleLanguage: SubtitleLanguageDto.off,
    );
    expect(subtitleSummary(off), 'Mati');
    expect(sourcesSummary(const []), 'Memuat daftar sumber');
    expect(
      animeSourceSummary(defaultSettings.withAnimeSource('x'), []),
      'Otomatis',
    );
  });

  test('every page has a distinct address and can be found again', () {
    final slugs = {for (final page in SettingsPage.values) page.slug};
    expect(slugs, hasLength(SettingsPage.values.length));
    for (final page in SettingsPage.values) {
      expect(SettingsPage.fromSlug(page.slug), page);
      expect(page.path, '/pengaturan/${page.slug}');
    }
    expect(SettingsPage.fromSlug('tidak-ada'), isNull);
  });
}
