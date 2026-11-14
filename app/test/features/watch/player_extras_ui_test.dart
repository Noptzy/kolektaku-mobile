import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kolektaku/data/providers/settings_providers.dart';
import 'package:kolektaku/features/settings/settings_edit.dart';
import 'package:kolektaku/src/rust/dto/settings.dart';

import 'player_extras_ui_support.dart';

void main() {
  testWidgets('a cue is drawn only while it is on', (tester) async {
    final (engine, _) = await show(
      tester,
      subtitles: [sub('Indonesian', 'id')],
    );
    expect(find.byKey(const Key('subtitle-line')), findsNothing);
    engine.emit(position: const Duration(milliseconds: 1500), playing: true);
    await tester.pump();
    expect(find.text('Halo dunia'), findsOneWidget);
    engine.emit(position: const Duration(milliseconds: 4000), playing: true);
    await tester.pump();
    expect(find.byKey(const Key('subtitle-line')), findsNothing);
  });

  testWidgets('the line follows the size and outline chosen in settings', (
    tester,
  ) async {
    final (engine, _) = await show(
      tester,
      subtitles: [sub('Indonesian', 'id')],
      settings: defaultSettings.copyWith(
        subtitleSize: SubtitleSizeDto.large,
        subtitleEdge: SubtitleEdgeDto.none,
      ),
    );
    engine.emit(position: const Duration(milliseconds: 1500), playing: true);
    await tester.pump();
    final line = tester.widget<Text>(find.byKey(const Key('subtitle-line')));
    expect(line.style!.fontSize, greaterThan(16));
    expect(line.style!.shadows, isNull);
  });

  testWidgets('the line sits higher while the controls are shown', (
    tester,
  ) async {
    final (engine, _) = await show(
      tester,
      subtitles: [sub('Indonesian', 'id')],
    );
    engine.emit(position: const Duration(milliseconds: 1500), playing: true);
    await tester.pump();
    final withControls = tester
        .getBottomLeft(find.byKey(const Key('subtitle-line')))
        .dy;
    await show(
      tester,
      subtitles: [sub('Indonesian', 'id')],
      controlsVisible: false,
    ).then((rig) {
      rig.$1.emit(position: const Duration(milliseconds: 1500), playing: true);
    });
    await tester.pump();
    final without = tester
        .getBottomLeft(find.byKey(const Key('subtitle-line')))
        .dy;
    expect(without, greaterThan(withControls));
  });

  testWidgets('the subtitle button lists languages and picks one', (
    tester,
  ) async {
    final (_, session) = await show(
      tester,
      subtitles: [
        sub('French', 'fr'),
        sub('English', 'en'),
        sub('Indonesian', 'id'),
        sub('English - Forced', 'en', variant: 'forced'),
      ],
    );
    await tester.tap(find.byKey(const Key('subtitles')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('option-Mati')), findsOneWidget);
    expect(find.text('Indonesia  •'), findsOneWidget);
    expect(find.byKey(const Key('option-Inggris')), findsOneWidget);
    expect(
      find.byKey(const Key('option-Inggris (dialog asing)')),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const Key('option-Inggris')));
    await tester.pumpAndSettle();
    expect(session.extras.subtitle.value?.label, 'English');
  });

  testWidgets('switching subtitles off from the menu clears the line', (
    tester,
  ) async {
    final (engine, session) = await show(
      tester,
      subtitles: [sub('Indonesian', 'id')],
    );
    await tester.tap(find.byKey(const Key('subtitles')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('option-Mati')));
    await tester.pumpAndSettle();
    engine.emit(position: const Duration(milliseconds: 1500), playing: true);
    await tester.pump();
    expect(session.extras.subtitle.value, isNull);
    expect(find.byKey(const Key('subtitle-line')), findsNothing);
  });
}
