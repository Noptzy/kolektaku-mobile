import 'package:flutter_test/flutter_test.dart';
import 'package:kolektaku/features/watch/episode_cache.dart';
import 'package:kolektaku/src/rust/dto/media.dart';

import 'watch_fixtures.dart';

void main() {
  group('keys', () {
    test('the same episode of the same title always has the same key', () {
      expect(
        EpisodeCache.playback(reference, 1, null),
        EpisodeCache.playback(reference, 1, null),
      );
    });

    test('another episode or another preferred source is another key', () {
      final base = EpisodeCache.playback(reference, 1, null);
      expect(EpisodeCache.playback(reference, 2, null), isNot(base));
      expect(EpisodeCache.playback(reference, 1, 'b'), isNot(base));
    });

    test('another title is another key', () {
      final other = MediaRefDto(
        kind: reference.kind,
        id: reference.id + BigInt.one,
        source: reference.source,
        item: reference.item,
      );
      expect(
        EpisodeCache.playback(other, 1, null),
        isNot(EpisodeCache.playback(reference, 1, null)),
      );
    });

    test('streams are told apart by source, episode and server', () {
      final base = EpisodeCache.stream('a', '1', 'srv1');
      expect(EpisodeCache.stream('b', '1', 'srv1'), isNot(base));
      expect(EpisodeCache.stream('a', '2', 'srv1'), isNot(base));
      expect(EpisodeCache.stream('a', '1', 'srv2'), isNot(base));
    });

    test('unit lists depend on the source asked for', () {
      expect(
        EpisodeCache.units(reference, null),
        isNot(EpisodeCache.units(reference, 'a')),
      );
    });
  });

  test('clear empties all three caches', () {
    final cache = EpisodeCache();
    cache.playbacks.put('p', playbackOn('a'));
    cache.streams.put('s', streamOf('a'));
    cache.unitLists.put('u', const []);
    cache.clear();
    final left =
        cache.playbacks.length + cache.streams.length + cache.unitLists.length;
    expect(left, 0);
  });

  test('there is one shared cache for the app', () {
    expect(identical(EpisodeCache.shared, EpisodeCache.shared), isTrue);
  });
}
