import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kolektaku/core/subtitle_style.dart';
import 'package:kolektaku/data/providers/settings_providers.dart';
import 'package:kolektaku/features/settings/settings_edit.dart';
import 'package:kolektaku/features/settings/settings_page_screen.dart';
import 'package:kolektaku/features/settings/settings_pages.dart';
import 'package:kolektaku/features/settings/subtitle_preview.dart';
import 'package:kolektaku/src/rust/dto/settings.dart';
import 'package:kolektaku/widgets/option_chip.dart';

import '../../support/screen_harness.dart';

Future<ScreenHarness> open(WidgetTester tester, {SettingsDto? stored}) async {
  final harness = ScreenHarness();
  if (stored != null) harness.settings.stored = stored;
  await harness.pump(
    tester,
    const SettingsPageScreen(page: SettingsPage.subtitle),
    size: const Size(390, 1800),
  );
  return harness;
}

Future<void> tapChip(WidgetTester tester, String label) async {
  await tester.tap(find.widgetWithText(OptionChip, label));
  await tester.pumpAndSettle();
}

Future<void> tapSwatch(WidgetTester tester, Object value) async {
  await tester.tap(find.byKey(Key('swatch-$value')));
  await tester.pumpAndSettle();
}

TextStyle previewStyle(WidgetTester tester) =>
    tester.widget<Text>(find.byKey(const Key('subtitle-preview'))).style!;

void main() {
  testWidgets('language and size are saved', (tester) async {
    final harness = await open(tester);
    await tapChip(tester, 'Inggris');
    await tapChip(tester, 'Besar');
    final saved = harness.settings.saves.last;
    expect(saved.subtitleLanguage, SubtitleLanguageDto.english);
    expect(saved.subtitleSize, SubtitleSizeDto.large);
  });

  testWidgets('every size is offered, including a very large one', (
    tester,
  ) async {
    final harness = await open(tester);
    await tapChip(tester, 'Sangat besar');
    expect(harness.settings.saves.single.subtitleSize, SubtitleSizeDto.huge);
  });

  testWidgets('the preview grows with the size', (tester) async {
    await open(tester);
    final medium = previewStyle(tester).fontSize!;
    await tapChip(tester, 'Besar');
    expect(previewStyle(tester).fontSize, greaterThan(medium));
    await tapChip(tester, 'Kecil');
    expect(previewStyle(tester).fontSize, lessThan(medium));
  });

  testWidgets('the text colour is picked from swatches and shown live', (
    tester,
  ) async {
    final harness = await open(tester);
    expect(previewStyle(tester).color, subtitleInk(SubtitleColorDto.white));
    await tapSwatch(tester, SubtitleColorDto.yellow);
    expect(previewStyle(tester).color, subtitleInk(SubtitleColorDto.yellow));
    expect(
      harness.settings.saves.single.subtitleColor,
      SubtitleColorDto.yellow,
    );
  });

  testWidgets('the edge is a dark outline until another style is chosen', (
    tester,
  ) async {
    final harness = await open(tester);
    final outline = previewStyle(tester).shadows!;
    expect(outline.length, greaterThan(4));
    expect(
      outline.every((shadow) => shadow.color == const Color(0xFF000000)),
      isTrue,
    );
    await tapChip(tester, 'Bayangan');
    expect(previewStyle(tester).shadows!.length, lessThan(outline.length));
    await tapChip(tester, 'Tanpa');
    expect(previewStyle(tester).shadows, isNull);
    expect(harness.settings.saves.last.subtitleEdge, SubtitleEdgeDto.none);
  });

  testWidgets('the background has a colour and a strength', (tester) async {
    final harness = await open(tester);
    DecoratedBox box() => tester.widget<DecoratedBox>(
      find
          .ancestor(
            of: find.byKey(const Key('subtitle-preview')),
            matching: find.byType(DecoratedBox),
          )
          .first,
    );
    expect((box().decoration as BoxDecoration).color, isNull);
    await tester.tap(find.widgetWithText(OptionChip, 'Sedang').last);
    await tester.pumpAndSettle();
    await tapSwatch(tester, SubtitleBoxColorDto.navy);
    final decoration = box().decoration as BoxDecoration;
    expect(decoration.color, isNotNull);
    expect(decoration.color!.a, closeTo(0.7, 0.01));
    final saved = harness.settings.saves.last;
    expect(saved.subtitleBoxColor, SubtitleBoxColorDto.navy);
    expect(saved.subtitleBoxOpacity, SubtitleBoxOpacityDto.medium);
  });

  testWidgets('turning subtitles off replaces the preview', (tester) async {
    await open(tester);
    await tapChip(tester, 'Mati');
    expect(find.byKey(const Key('subtitle-preview')), findsNothing);
    expect(find.text(subtitleOffText), findsOneWidget);
  });

  testWidgets('the reset button brings the default look back', (tester) async {
    final harness = await open(
      tester,
      stored: defaultSettings.copyWith(
        subtitleSize: SubtitleSizeDto.huge,
        subtitleColor: SubtitleColorDto.pink,
        subtitleEdge: SubtitleEdgeDto.none,
        subtitleBoxOpacity: SubtitleBoxOpacityDto.full,
      ),
    );
    await tester.ensureVisible(find.byKey(const Key('subtitle-reset')));
    await tester.tap(find.byKey(const Key('subtitle-reset')));
    await tester.pumpAndSettle();
    final saved = harness.settings.saves.last;
    expect(saved.subtitleSize, SubtitleSizeDto.medium);
    expect(saved.subtitleColor, SubtitleColorDto.white);
    expect(saved.subtitleEdge, SubtitleEdgeDto.outline);
    expect(saved.subtitleBoxOpacity, SubtitleBoxOpacityDto.off);
  });

  testWidgets('the preview stays on screen while the options scroll', (
    tester,
  ) async {
    await open(tester);
    expect(find.byKey(const Key('subtitle-preview')), findsOneWidget);
    expect(find.byKey(const Key('settings-back')), findsOneWidget);
  });

  test('sizes scale, the colours differ and the box strength grows', () {
    expect(subtitleScale(SubtitleSizeDto.small), lessThan(1));
    expect(subtitleScale(SubtitleSizeDto.huge), greaterThan(1.5));
    expect({
      for (final color in SubtitleColorDto.values) subtitleInk(color),
    }, hasLength(SubtitleColorDto.values.length));
    expect(subtitleBoxAlpha(SubtitleBoxOpacityDto.off), 0);
    expect(subtitleBoxAlpha(SubtitleBoxOpacityDto.full), 1);
    expect(subtitleBoxDecoration(defaultSettings), isNull);
    expect(
      subtitleBoxDecoration(
        defaultSettings.copyWith(
          subtitleBoxOpacity: SubtitleBoxOpacityDto.light,
        ),
      ),
      isNotNull,
    );
  });
}
