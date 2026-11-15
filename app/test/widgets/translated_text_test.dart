import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kolektaku/data/providers/translation_providers.dart';
import 'package:kolektaku/features/home/translated_hero.dart';
import 'package:kolektaku/features/settings/settings_edit.dart';
import 'package:kolektaku/data/providers/settings_providers.dart';
import 'package:kolektaku/src/rust/dto/settings.dart';
import 'package:kolektaku/widgets/hero_slide.dart';
import 'package:kolektaku/widgets/translated_text.dart';

import '../support/fake_translation_gateway.dart';
import '../support/screen_harness.dart';

Future<ScreenHarness> show(
  WidgetTester tester,
  Widget child, {
  void Function(FakeTranslationGateway gateway)? prepare,
  SettingsDto? settings,
}) async {
  final harness = ScreenHarness();
  if (settings != null) harness.settings.stored = settings;
  prepare?.call(harness.translation);
  await harness.pump(tester, child);
  return harness;
}

void indonesian(FakeTranslationGateway gateway) =>
    gateway.translating = (text) => 'ID: $text';

void main() {
  const key = Key('text');

  testWidgets('the translation replaces the text and says so', (tester) async {
    await show(
      tester,
      const TranslatedText(text: 'Hello', textKey: key),
      prepare: indonesian,
    );
    expect(tester.widget<Text>(find.byKey(key)).data, 'ID: Hello');
    expect(
      find.textContaining('Diterjemahkan otomatis', findRichText: true),
      findsOneWidget,
    );
    expect(
      find.textContaining('Lihat asli', findRichText: true),
      findsOneWidget,
    );
  });

  testWidgets('the original is one tap away and the translation too', (
    tester,
  ) async {
    await show(
      tester,
      const TranslatedText(text: 'Hello', textKey: key),
      prepare: indonesian,
    );
    await tester.tap(find.byKey(const Key('translation-note')));
    await tester.pump();
    expect(tester.widget<Text>(find.byKey(key)).data, 'Hello');
    expect(
      find.textContaining('Lihat terjemahan', findRichText: true),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const Key('translation-note')));
    await tester.pump();
    expect(tester.widget<Text>(find.byKey(key)).data, 'ID: Hello');
  });

  testWidgets('a compact use can leave the note out', (tester) async {
    await show(
      tester,
      const TranslatedText(text: 'Hello', showNote: false, textKey: key),
      prepare: indonesian,
    );
    expect(tester.widget<Text>(find.byKey(key)).data, 'ID: Hello');
    expect(find.byKey(const Key('translation-note')), findsNothing);
  });

  testWidgets('text already in the target language gets no label', (
    tester,
  ) async {
    await show(tester, const TranslatedText(text: 'Halo', textKey: key));
    expect(tester.widget<Text>(find.byKey(key)).data, 'Halo');
    expect(find.byKey(const Key('translation-note')), findsNothing);
  });

  testWidgets('a failing service leaves the original without a label', (
    tester,
  ) async {
    await show(
      tester,
      const TranslatedText(text: 'Hello', textKey: key),
      prepare: (gateway) => gateway.failure = StateError('down'),
    );
    expect(tester.widget<Text>(find.byKey(key)).data, 'Hello');
    expect(find.byKey(const Key('translation-note')), findsNothing);
  });

  testWidgets('with translation off nothing is asked', (tester) async {
    final harness = await show(
      tester,
      const TranslatedText(text: 'Hello', textKey: key),
      prepare: indonesian,
      settings: defaultSettings.copyWith(
        translation: TranslationLanguageDto.off,
      ),
    );
    expect(tester.widget<Text>(find.byKey(key)).data, 'Hello');
    expect(harness.translation.asked, isEmpty);
  });

  testWidgets('blank text is never sent', (tester) async {
    final harness = await show(
      tester,
      const TranslatedText(text: '   ', textKey: key),
      prepare: indonesian,
    );
    expect(harness.translation.asked, isEmpty);
  });

  testWidgets('the same text shown twice is asked once', (tester) async {
    final harness = await show(
      tester,
      const Column(
        children: [
          TranslatedText(text: 'Hello', showNote: false),
          TranslatedText(text: 'Hello'),
        ],
      ),
      prepare: indonesian,
    );
    expect(harness.translation.asked, hasLength(1));
  });

  test('batches with the same texts are equal', () {
    expect(const TextBatch(['a', 'b']), const TextBatch(['a', 'b']));
    expect(const TextBatch(['a']), isNot(const TextBatch(['a', 'b'])));
    expect(const TextBatch(['a']).hashCode, const TextBatch(['a']).hashCode);
  });

  group('the home hero', () {
    List<HeroSlide> slides() => const [
      HeroSlide(title: 'One', meta: '2024', synopsis: 'First story'),
      HeroSlide(title: 'Two', meta: '2023', synopsis: 'Second story'),
      HeroSlide(title: 'Three', meta: '2022'),
    ];

    testWidgets('all synopses travel in one request', (tester) async {
      final harness = await show(
        tester,
        SizedBox(
          height: 600,
          child: TranslatedHeroCarousel(slides: slides(), onWatch: (_) {}),
        ),
        prepare: indonesian,
      );
      expect(harness.translation.asked, hasLength(1));
      expect(harness.translation.asked.single, [
        'First story',
        'Second story',
        '',
      ]);
    });

    testWidgets('the first slide shows its translated synopsis', (
      tester,
    ) async {
      await show(
        tester,
        SizedBox(
          height: 600,
          child: TranslatedHeroCarousel(slides: slides(), onWatch: (_) {}),
        ),
        prepare: indonesian,
      );
      expect(
        tester.widget<Text>(find.byKey(const Key('hero-synopsis'))).data,
        'ID: First story',
      );
    });

    testWidgets('without a translation the original synopsis stays', (
      tester,
    ) async {
      await show(
        tester,
        SizedBox(
          height: 600,
          child: TranslatedHeroCarousel(slides: slides(), onWatch: (_) {}),
        ),
      );
      expect(
        tester.widget<Text>(find.byKey(const Key('hero-synopsis'))).data,
        'First story',
      );
    });
  });
}
