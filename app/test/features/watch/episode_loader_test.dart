import 'package:flutter_test/flutter_test.dart';
import 'package:kolektaku/features/watch/episode_loader.dart';
import 'package:kolektaku/src/rust/dto/media.dart';

import 'watch_fixtures.dart';

class Calls {
  final List<String> opened = [];
  final List<List<String>> excluded = [];
  final List<String> resolved = [];
}

EpisodeLoader loader(
  Calls calls, {
  required Map<String, List<bool>> serverWorks,
  List<String> sourceOrder = const ['a', 'b'],
  int servers = 2,
}) {
  return EpisodeLoader(
    open:
        ({
          required MediaRefDto reference,
          required double episode,
          String? preferred,
          required List<String> exclude,
        }) async {
          calls.excluded.add(exclude);
          final next = sourceOrder.where((id) => !exclude.contains(id));
          if (next.isEmpty) throw StateError('no more sources');
          calls.opened.add(next.first);
          return playbackOn(next.first, servers: servers);
        },
    resolve:
        ({
          required String source,
          required String episodeId,
          required String server,
        }) async {
          calls.resolved.add('$source/$server');
          final index = int.parse(server.substring(3)) - 1;
          if (serverWorks[source]![index]) return streamOf(source);
          throw StateError('$source $server failed');
        },
  );
}

void main() {
  test('the first source and first server win when they work', () async {
    final calls = Calls();
    final loaded = await loader(
      calls,
      serverWorks: {
        'a': [true, true],
      },
    ).load(reference, 1);
    expect(loaded.playback.source, 'a');
    expect(loaded.switchedFrom, isNull);
    expect(calls.resolved, ['a/srv1']);
  });

  test(
    'a failing server hands over to the next server of the same source',
    () async {
      final calls = Calls();
      final loaded = await loader(
        calls,
        serverWorks: {
          'a': [false, true],
        },
      ).load(reference, 1);
      expect(loaded.playback.source, 'a');
      expect(calls.resolved, ['a/srv1', 'a/srv2']);
      expect(loaded.switchedFrom, isNull);
    },
  );

  test('when every server of a source fails the next source is used', () async {
    final calls = Calls();
    final loaded = await loader(
      calls,
      serverWorks: {
        'a': [false, false],
        'b': [true, true],
      },
    ).load(reference, 1);
    expect(loaded.playback.source, 'b');
    expect(loaded.switchedFrom, 'a');
    expect(calls.excluded, [
      <String>[],
      ['a'],
    ]);
  });

  test('only a few servers per source are tried', () async {
    final calls = Calls();
    await expectLater(
      loader(
        calls,
        servers: 5,
        sourceOrder: const ['a'],
        serverWorks: {
          'a': [false, false, false, false, false],
        },
      ).load(reference, 1),
      throwsA(isA<StateError>()),
    );
    expect(calls.resolved, ['a/srv1', 'a/srv2', 'a/srv3']);
  });

  test('when nothing works the most informative error comes out', () async {
    final calls = Calls();
    await expectLater(
      loader(
        calls,
        serverWorks: {
          'a': [false, false],
          'b': [false, false],
        },
      ).load(reference, 1),
      throwsA(
        isA<StateError>().having(
          (e) => e.message,
          'message',
          contains('b srv2'),
        ),
      ),
    );
    expect(calls.opened, ['a', 'b']);
  });

  test('a preferred source is only asked for on the first round', () async {
    final asked = <String?>[];
    final episodes = EpisodeLoader(
      open:
          ({
            required MediaRefDto reference,
            required double episode,
            String? preferred,
            required List<String> exclude,
          }) async {
            asked.add(preferred);
            return playbackOn(exclude.isEmpty ? 'a' : 'b');
          },
      resolve: ({
        required String source,
        required String episodeId,
        required String server,
      }) async => source == 'a' ? throw StateError('x') : streamOf(source),
    );
    final loaded = await episodes.load(reference, 1, preferred: 'a');
    expect(asked, ['a', null]);
    expect(loaded.playback.source, 'b');
    expect(loaded.switchedFrom, 'a');
  });
}
