import 'package:flutter_test/flutter_test.dart';
import 'package:kolektaku/features/watch/episode_cache.dart';
import 'package:kolektaku/features/watch/episode_loader.dart';
import 'package:kolektaku/src/rust/dto/media.dart';
import 'package:kolektaku/src/rust/dto/sources.dart';

import '../../core/ttl_cache_test.dart' show FakeClock;
import 'watch_fixtures.dart';

class Rig {
  Rig() {
    cache = EpisodeCache(now: () => clock.now);
    loader = EpisodeLoader(
      cache: cache,
      open:
          ({
            required MediaRefDto reference,
            required double episode,
            String? preferred,
            required List<String> exclude,
            String? audio,
          }) async {
            opens.add('$episode|${preferred ?? ''}|${exclude.join(',')}');
            final source = ['a', 'b'].firstWhere((id) => !exclude.contains(id));
            return playbackOn(source);
          },
      resolve:
          ({
            required String source,
            required String episodeId,
            required String server,
          }) async {
            resolves.add('$source/$server');
            if (workingServers[server] != true) {
              throw StateError('$server down');
            }
            return streamOf('$source#${resolves.length}');
          },
      units: ({required MediaRefDto reference, String? source}) async {
        unitAsks.add(source ?? '');
        return UnitsDto(
          source: source ?? 'a',
          item: 'i',
          units: [
            for (final n in unitsToGive)
              UnitDto(id: '$n', number: n.toDouble(), label: 'E$n'),
          ],
        );
      },
    );
  }

  final Map<String, bool> workingServers = {'srv1': true, 'srv2': true};
  final FakeClock clock = FakeClock();
  final List<String> opens = [];
  final List<String> resolves = [];
  final List<String> unitAsks = [];
  List<int> unitsToGive = [1, 2, 3];
  late final EpisodeCache cache;
  late final EpisodeLoader loader;
}

const _over = Duration(seconds: 1);

void main() {
  group('opening an episode again', () {
    test('asks the sources and the servers only once', () async {
      final rig = Rig();
      await rig.loader.load(reference, 1);
      await rig.loader.load(reference, 1);
      expect(rig.opens, hasLength(1));
      expect(rig.resolves, hasLength(1));
    });

    test('gives back the same stream both times', () async {
      final rig = Rig();
      final first = await rig.loader.load(reference, 1);
      final second = await rig.loader.load(reference, 1);
      expect(second.stream, same(first.stream));
      expect(second.serverId, first.serverId);
    });

    test('another episode is asked for on its own', () async {
      final rig = Rig();
      await rig.loader.load(reference, 1);
      await rig.loader.load(reference, 2);
      expect(rig.opens, hasLength(2));
    });

    test('another preferred source is asked for on its own', () async {
      final rig = Rig();
      await rig.loader.load(reference, 1);
      await rig.loader.load(reference, 1, preferred: 'b');
      expect(rig.opens, hasLength(2));
    });

    test('asks again once the cached answer is too old', () async {
      final rig = Rig();
      await rig.loader.load(reference, 1);
      rig.clock.advance(playbackLifetime + _over);
      await rig.loader.load(reference, 1);
      expect(rig.opens, hasLength(2));
      expect(rig.resolves, hasLength(2));
    });

    test('the stream expires before the playback does', () async {
      final rig = Rig();
      await rig.loader.load(reference, 1);
      rig.clock.advance(streamLifetime + _over);
      await rig.loader.load(reference, 1);
      expect(rig.opens, hasLength(1));
      expect(rig.resolves, hasLength(2));
    });
  });

  group('trying another source', () {
    test('never reuses or stores the cached answer', () async {
      final rig = Rig();
      await rig.loader.load(reference, 1);
      final other = await rig.loader.load(reference, 1, exclude: ['a']);
      expect(other.playback.source, 'b');
      expect(rig.opens, hasLength(2));
      final again = await rig.loader.load(reference, 1);
      expect(again.playback.source, 'a');
      expect(rig.opens, hasLength(2));
    });
  });

  group('a cached playback whose servers stopped working', () {
    test('is forgotten so the next load asks the sources again', () async {
      final rig = Rig();
      await rig.loader.load(reference, 1);
      rig.workingServers
        ..['srv1'] = false
        ..['srv2'] = false;
      rig.clock.advance(streamLifetime + _over);
      await expectLater(rig.loader.load(reference, 1), throwsA(anything));
      final key = EpisodeCache.playback(reference, 1, null);
      expect(rig.cache.playbacks.get(key), isNull);
    });
  });

  group('switching servers and refreshing', () {
    test('a server resolved before is not resolved again', () async {
      final rig = Rig();
      final loaded = await rig.loader.load(reference, 1);
      final before = rig.resolves.length;
      await rig.loader.useServer(loaded, loaded.serverId);
      expect(rig.resolves.length, before);
    });

    test('a new server is resolved once and then remembered', () async {
      final rig = Rig();
      final loaded = await rig.loader.load(reference, 1);
      await rig.loader.useServer(loaded, 'srv2');
      await rig.loader.useServer(loaded, 'srv2');
      final asked = rig.resolves.where((entry) => entry.endsWith('srv2'));
      expect(asked, hasLength(1));
    });

    test('refresh resolves again and replaces the stored stream', () async {
      final rig = Rig();
      final loaded = await rig.loader.load(reference, 1);
      final fresh = await rig.loader.refresh(loaded);
      expect(fresh, isNot(same(loaded.stream)));
      expect(rig.resolves, hasLength(2));
      final next = await rig.loader.load(reference, 1);
      expect(next.stream, same(fresh));
    });
  });

  group('the episode list', () {
    test('is asked for once per source', () async {
      final rig = Rig();
      await rig.loader.unitsOrEmpty(reference, source: 'a');
      final again = await rig.loader.unitsOrEmpty(reference, source: 'a');
      expect(rig.unitAsks, ['a']);
      expect(again, hasLength(3));
      await rig.loader.unitsOrEmpty(reference, source: 'b');
      expect(rig.unitAsks, ['a', 'b']);
    });

    test('an empty answer is not kept', () async {
      final rig = Rig()..unitsToGive = [];
      await rig.loader.unitsOrEmpty(reference);
      rig.unitsToGive = [1];
      final later = await rig.loader.unitsOrEmpty(reference);
      expect(later, hasLength(1));
      expect(rig.unitAsks, hasLength(2));
    });
  });
}
