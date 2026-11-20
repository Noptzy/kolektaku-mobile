import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kolektaku/data/providers/settings_providers.dart';
import 'package:kolektaku/features/watch/player/player_session.dart';
import 'package:kolektaku/features/watch/player/player_settings.dart';

import '../../widgets/widget_harness.dart';
import 'fake_engine.dart';
import 'player_extras_support.dart';
import 'subtitle_translation_support.dart' show streamWith;

Future<PlayerSession> openedSession({bool translated = true}) async {
  final stream = streamWith([sub('English', 'en')]);
  final session = PlayerSession(
    engine: FakeEngine(),
    stream: stream,
    refetch: () async => stream,
    cueLoader: (request) async => request.translate
        ? plan([cue(0, 1000, 'Halo')], translated: translated)
        : plan([cue(0, 1000, 'Hello')]),
  );
  await session.start(Duration.zero);
  await pumpEventQueue();
  return session;
}

SettingChoice subtitleChoice(PlayerSession session) {
  final choices = settingChoices(session: session, onInteract: () {});
  return choices.firstWhere((choice) => choice.id == 'subtitle');
}

void main() {
  test('the settings row names the translation after its language', () async {
    final session = await openedSession();
    expect(subtitleChoice(session).value, 'Indonesia · terjemahan otomatis');
  });

  test('an untranslated track keeps its plain name in the row', () async {
    final session = await openedSession(translated: false);
    expect(subtitleChoice(session).value, 'Inggris');
  });

  testWidgets('the menu marks the translated entry and offers the original', (
    tester,
  ) async {
    final session = (await tester.runAsync(openedSession))!;
    var closed = 0;
    await pumpAtSize(
      tester,
      Builder(
        builder: (context) => subtitleChoice(session).page(() => closed++),
      ),
    );
    expect(find.text('Indonesia · terjemahan otomatis  •'), findsOneWidget);
    expect(find.text('Tampilkan teks asli'), findsOneWidget);
    await tester.tap(find.byKey(const Key('toggle-original-subtitle')));
    await tester.pump();
    expect(closed, 1);
    expect(session.extras.cues.value.single.text, 'Hello');
  });

  testWidgets('without a translation there is no original toggle', (
    tester,
  ) async {
    final session = (await tester.runAsync(
      () => openedSession(translated: false),
    ))!;
    await pumpAtSize(
      tester,
      Builder(builder: (context) => subtitleChoice(session).page(() {})),
    );
    expect(find.byKey(const Key('toggle-original-subtitle')), findsNothing);
  });

  testWidgets('the toggle flips its wording after being used', (tester) async {
    final session = (await tester.runAsync(openedSession))!;
    session.extras.subtitleCues.toggleOriginal();
    await pumpAtSize(
      tester,
      Builder(builder: (context) => subtitleChoice(session).page(() {})),
    );
    expect(find.text('Tampilkan terjemahan'), findsOneWidget);
  });

  test('the defaults still translate into Indonesian', () {
    expect(defaultSettings.translation.name, 'indonesian');
  });
}
