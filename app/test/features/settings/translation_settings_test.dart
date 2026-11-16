import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kolektaku/core/translation_labels.dart';
import 'package:kolektaku/data/providers/settings_providers.dart';
import 'package:kolektaku/features/settings/settings_edit.dart';
import 'package:kolektaku/features/settings/settings_page_screen.dart';
import 'package:kolektaku/features/settings/settings_pages.dart';
import 'package:kolektaku/features/settings/settings_summary.dart';
import 'package:kolektaku/features/settings/translation_section.dart';
import 'package:kolektaku/src/rust/dto/settings.dart';

import '../../support/screen_harness.dart';

Future<ScreenHarness> open(
  WidgetTester tester, {
  SettingsDto? stored,
  int? pausedUntil,
}) async {
  final harness = ScreenHarness();
  if (stored != null) harness.settings.stored = stored;
  harness.translation.pausedUntil = pausedUntil;
  await harness.pump(
    tester,
    const SettingsPageScreen(page: SettingsPage.translation),
    size: const Size(390, 1200),
  );
  return harness;
}

void main() {
  test('the summary names the language or says it is off', () {
    expect(translationSummary(defaultSettings), 'Indonesia');
    final off = defaultSettings.copyWith(
      translation: TranslationLanguageDto.off,
    );
    expect(translationSummary(off), 'Mati');
  });

  test('every language has a name', () {
    for (final language in TranslationLanguageDto.values) {
      expect(translationLanguageNames[language], isNotEmpty);
    }
    expect(TranslationLanguageDto.values, hasLength(18));
  });

  test('the service state is normal or tells when it will be back', () {
    expect(serviceStateLabel(null), 'Normal');
    expect(
      serviceStateLabel(1700000000),
      startsWith('Sedang dibatasi, dicoba lagi pukul '),
    );
  });

  test('the clock reads hours and minutes with a dot', () {
    expect(clockLabel(DateTime(2026, 1, 1, 9, 5)), '09.05');
    expect(clockLabel(DateTime(2026, 1, 1, 21, 40)), '21.40');
  });

  test('the page explains itself without naming the technology', () {
    final intro = SettingsPage.translation.intro.toLowerCase();
    for (final word in ['mesin', 'model', 'google', ' ai ']) {
      expect(intro.contains(word), isFalse, reason: word);
    }
    expect(intro, contains('internet'));
    expect(intro, contains('layanan terjemahan'));
  });

  testWidgets('the page shows the chosen language and a normal service', (
    tester,
  ) async {
    await open(tester);
    expect(find.text('Terjemahan otomatis'), findsOneWidget);
    expect(find.text('Indonesia'), findsOneWidget);
    expect(find.text('Normal'), findsOneWidget);
  });

  testWidgets('a limited service says when it will be tried again', (
    tester,
  ) async {
    await open(tester, pausedUntil: 1700000000);
    expect(find.textContaining('dicoba lagi pukul'), findsOneWidget);
    expect(find.text('Normal'), findsNothing);
  });

  testWidgets('the languages are picked from a bottom sheet', (tester) async {
    final harness = await open(tester);
    await tester.tap(find.byKey(const Key('translation-language-row')));
    await tester.pumpAndSettle();
    expect(find.text('Bahasa terjemahan'), findsWidgets);
    await tester.tap(find.byKey(const Key('option-Jepang')));
    await tester.pumpAndSettle();
    expect(
      harness.settings.saves.single.translation,
      TranslationLanguageDto.japanese,
    );
    expect(find.byKey(const Key('option-Jepang')), findsNothing);
  });

  testWidgets('translation can be switched off from the sheet', (tester) async {
    final harness = await open(tester);
    await tester.tap(find.byKey(const Key('translation-language-row')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('option-Mati')));
    await tester.pumpAndSettle();
    expect(
      harness.settings.saves.single.translation,
      TranslationLanguageDto.off,
    );
  });

  testWidgets('the other settings survive a language change', (tester) async {
    final harness = await open(
      tester,
      stored: defaultSettings.copyWith(prefersAnime: false, accent: '#3B82F6'),
    );
    await tester.tap(find.byKey(const Key('translation-language-row')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('option-Korea')));
    await tester.pumpAndSettle();
    final saved = harness.settings.saves.single;
    expect(saved.prefersAnime, isFalse);
    expect(saved.accent, '#3B82F6');
    expect(saved.translation, TranslationLanguageDto.korean);
  });
}
