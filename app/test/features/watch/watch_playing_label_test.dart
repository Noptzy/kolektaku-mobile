import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kolektaku/features/watch/episode_loader.dart';
import 'package:kolektaku/features/watch/server_choice.dart';
import 'package:kolektaku/features/watch/watch_labels.dart';
import 'package:kolektaku/src/rust/dto/stream.dart';

import 'watch_fixtures.dart';
import 'watch_harness.dart';

ServerDto server(String id, {String? variant, String? audio}) =>
    ServerDto(id: id, label: 'Rahasia $id', variant: variant, audio: audio);

LoadedEpisode loaded({
  String source = 'a',
  String serverId = 'srv1',
  bool variants = false,
  int servers = 2,
}) {
  return LoadedEpisode(
    playback: playbackOn(source, servers: servers, variants: variants),
    stream: streamOf('x'),
    serverId: serverId,
  );
}

void main() {
  group('serverLabel', () {
    test('servers without a variant are numbered by position', () {
      final servers = [server('a'), server('b'), server('c')];
      expect(
        [for (var i = 0; i < 3; i++) serverLabel(servers, i)],
        ['Server 1', 'Server 2', 'Server 3'],
      );
    });

    test('subs and dubs are numbered separately and say which they are', () {
      final servers = [
        server('s1', variant: 'sub'),
        server('s2', variant: 'sub'),
        server('d1', variant: 'dub'),
        server('d2', variant: 'dub'),
      ];
      expect(
        [for (var i = 0; i < 4; i++) serverLabel(servers, i)],
        [
          'Server 1 · Sub',
          'Server 2 · Sub',
          'Server 1 · Dub',
          'Server 2 · Dub',
        ],
      );
    });

    test('the audio language is named when the source knows it', () {
      final servers = [
        server('s1', variant: 'sub', audio: 'ja'),
        server('d1', variant: 'dub', audio: 'en'),
        server('d2', variant: 'dub', audio: 'xx'),
      ];
      expect(serverLabel(servers, 0), 'Server 1 · Sub · audio Jepang');
      expect(serverLabel(servers, 1), 'Server 1 · Dub · audio Inggris');
      expect(serverLabel(servers, 2), 'Server 2 · Dub');
      expect(audioName('id'), 'Indonesia');
      expect(audioName(null), isNull);
    });

    test('the label the site gave is never shown', () {
      final servers = [server('kuramadrive')];
      expect(serverLabel(servers, 0), isNot(contains('Rahasia')));
      expect(serverLabel(servers, 0), isNot(contains('kurama')));
    });

    test('variants are only mentioned when there are some', () {
      expect(hasVariants([server('a'), server('b')]), isFalse);
      expect(hasVariants([server('a', variant: 'dub')]), isTrue);
    });
  });

  group('playingLabel', () {
    const names = {'a': 'Sumber anime 1', 'b': 'Sumber anime 2'};

    test('names the source and the server being played', () {
      expect(playingLabel(loaded(), names), 'Sumber anime 1  ·  Server 1');
      expect(
        playingLabel(loaded(source: 'b', serverId: 'srv2'), names),
        'Sumber anime 2  ·  Server 2',
      );
    });

    test('says sub or dub when the source tells them apart', () {
      final dub = loaded(variants: true, servers: 4, serverId: 'srv3');
      expect(playingLabel(dub, names), 'Sumber anime 1  ·  Server 1 · Dub');
    });

    test('an unknown source leaves just the server', () {
      expect(playingLabel(loaded(source: 'zzz'), names), 'Server 1');
    });

    test('nothing is said before an episode is loaded', () {
      expect(playingLabel(null, names), isNull);
    });
  });

  group('on screen', () {
    testWidgets('the player says which source and server is playing', (
      tester,
    ) async {
      final harness = WatchHarness();
      await harness.open(tester);
      final label = tester.widget<Text>(find.byKey(const Key('playing-label')));
      expect(label.data, contains('Sumber anime 1'));
      expect(label.data, contains('Server 1'));
    });

    testWidgets('a dub server is named as a dub in the label and the sheet', (
      tester,
    ) async {
      final harness = WatchHarness(variants: true);
      await harness.open(tester);
      await tester.tap(find.byKey(const Key('change-server')));
      await tester.pumpAndSettle();
      expect(find.text('Server 1 · Sub'), findsWidgets);
      expect(find.text('Server 1 · Dub'), findsOneWidget);
      expect(find.textContaining('Dub: suara diganti'), findsOneWidget);
      await tester.tap(find.byKey(const Key('server-option-srv3')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      final label = tester.widget<Text>(find.byKey(const Key('playing-label')));
      expect(label.data, contains('Dub'));
    });

    testWidgets('a source that does not tell sub from dub keeps it simple', (
      tester,
    ) async {
      final harness = WatchHarness();
      await harness.open(tester);
      await tester.tap(find.byKey(const Key('change-server')));
      await tester.pumpAndSettle();
      expect(find.textContaining('Dub'), findsNothing);
      expect(find.text('Server 2'), findsOneWidget);
    });
  });

  group('other sources in the server sheet', () {
    testWidgets('each other source is listed by name with what it is like', (
      tester,
    ) async {
      final harness = WatchHarness(linked: const ['a', 'b']);
      await harness.open(tester);
      await tester.tap(find.byKey(const Key('change-server')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('source-option-b')), findsOneWidget);
      expect(find.byKey(const Key('source-option-a')), findsNothing);
      expect(find.text('Sumber anime 2'), findsWidgets);
      expect(find.text('Kebanyakan subtitle Inggris.'), findsOneWidget);
      expect(find.byKey(const Key('other-source-option')), findsNothing);
    });

    testWidgets('choosing one plays the same episode from that source', (
      tester,
    ) async {
      final harness = WatchHarness(linked: const ['a', 'b'], episode: 5);
      await harness.open(tester);
      await tester.tap(find.byKey(const Key('change-server')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('source-option-b')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(harness.openedEpisodes, [5, 5]);
      expect(harness.preferredAsked.last, 'b');
      final label = tester.widget<Text>(find.byKey(const Key('playing-label')));
      expect(label.data, contains('Sumber anime 2'));
    });

    testWidgets('without known links the generic button stays', (tester) async {
      final harness = WatchHarness();
      await harness.open(tester);
      await tester.tap(find.byKey(const Key('change-server')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('other-source-option')), findsOneWidget);
    });
  });

  group('otherSourcesOf', () {
    test('skips the playing source and unknown ones', () {
      final others = otherSourcesOf(
        linked: const ['a', 'b', 'zzz'],
        current: 'a',
        names: const {'a': 'Satu', 'b': 'Dua'},
        summaries: const {'b': 'Catatan'},
      );
      expect(others.map((o) => o.id), ['b']);
      expect(others.single.label, 'Dua');
      expect(others.single.summary, 'Catatan');
    });
  });
}
