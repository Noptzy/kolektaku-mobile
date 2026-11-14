import 'package:flutter_test/flutter_test.dart';
import 'package:kolektaku/features/watch/player/end_watcher.dart';
import 'package:kolektaku/features/watch/player/episode_end.dart';
import 'package:kolektaku/features/watch/player/playback_engine.dart';

PlaybackSnapshot at(int seconds, {int length = 100}) => PlaybackSnapshot(
  position: Duration(seconds: seconds),
  duration: Duration(seconds: length),
);

void main() {
  group('hasEnded', () {
    test('the very end counts as ended', () {
      expect(hasEnded(at(100)), isTrue);
      expect(hasEnded(at(99)), isFalse);
    });

    test('a position within the tolerance counts as ended', () {
      const near = PlaybackSnapshot(
        position: Duration(milliseconds: 99400),
        duration: Duration(seconds: 100),
      );
      expect(hasEnded(near), isTrue);
    });

    test('an unknown length never counts as ended', () {
      expect(hasEnded(const PlaybackSnapshot()), isFalse);
    });
  });

  group('leftTheEnd', () {
    test('seeking back a few seconds counts as leaving', () {
      expect(leftTheEnd(at(90)), isTrue);
      expect(leftTheEnd(at(98)), isFalse);
      expect(leftTheEnd(const PlaybackSnapshot()), isFalse);
    });
  });

  group('EndWatcher', () {
    test('fires once at the end however many updates follow', () {
      var ends = 0;
      final watcher = EndWatcher(onEnd: () => ends++, onLeave: () {});
      watcher.feed(at(100));
      watcher.feed(at(100));
      watcher.feed(at(100));
      expect(ends, 1);
    });

    test('leaving the end fires once and allows another end', () {
      var ends = 0;
      var leaves = 0;
      final watcher = EndWatcher(onEnd: () => ends++, onLeave: () => leaves++);
      watcher.feed(at(100));
      watcher.feed(at(50));
      watcher.feed(at(40));
      expect(leaves, 1);
      watcher.feed(at(100));
      expect(ends, 2);
    });

    test('moving around the middle does nothing', () {
      var calls = 0;
      final watcher = EndWatcher(onEnd: () => calls++, onLeave: () => calls++);
      watcher.feed(at(10));
      watcher.feed(at(60));
      expect(calls, 0);
    });

    test('reset lets the same end fire again', () {
      var ends = 0;
      final watcher = EndWatcher(onEnd: () => ends++, onLeave: () {});
      watcher.feed(at(100));
      watcher.reset();
      watcher.feed(at(100));
      expect(ends, 2);
    });
  });
}
