import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kolektaku/features/watch/awake_guard.dart';
import 'package:kolektaku/features/watch/player/playback_engine.dart';
import 'package:kolektaku/platform/screen_awake.dart';

import 'watch_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AwakeGuard', () {
    late FakeAwake awake;
    late AwakeGuard guard;
    late ValueNotifier<PlaybackSnapshot> snapshot;

    setUp(() {
      awake = FakeAwake();
      guard = AwakeGuard(awake);
      snapshot = ValueNotifier(const PlaybackSnapshot());
    });

    tearDown(() {
      guard.dispose();
      snapshot.dispose();
    });

    test('stays quiet until something plays', () {
      guard.follow(snapshot);
      expect(awake.calls, isEmpty);
    });

    test('keeps the screen on while playing and lets go when paused', () {
      guard.follow(snapshot);
      snapshot.value = const PlaybackSnapshot(playing: true);
      expect(awake.calls, [true]);
      snapshot.value = const PlaybackSnapshot();
      expect(awake.calls, [true, false]);
    });

    test('buffering still counts as watching', () {
      guard.follow(snapshot);
      snapshot.value = const PlaybackSnapshot(buffering: true);
      expect(awake.on, isTrue);
    });

    test('asks only when the answer changes', () {
      guard.follow(snapshot);
      snapshot.value = const PlaybackSnapshot(playing: true);
      snapshot.value = const PlaybackSnapshot(
        playing: true,
        position: Duration(seconds: 5),
      );
      expect(awake.calls, [true]);
    });

    test('following the same source twice changes nothing', () {
      snapshot.value = const PlaybackSnapshot(playing: true);
      guard.follow(snapshot);
      guard.follow(snapshot);
      expect(awake.calls, [true]);
    });

    test('losing the source lets the screen sleep again', () {
      snapshot.value = const PlaybackSnapshot(playing: true);
      guard.follow(snapshot);
      guard.follow(null);
      expect(awake.calls, [true, false]);
    });

    test('disposing while the screen is held releases it once', () {
      snapshot.value = const PlaybackSnapshot(playing: true);
      guard.follow(snapshot);
      guard.dispose();
      guard.dispose();
      expect(awake.calls, [true, false]);
      snapshot.value = const PlaybackSnapshot();
      expect(awake.calls, [true, false]);
    });
  });

  group('WatchScreen', () {
    testWidgets('holds the screen while the video plays', (tester) async {
      final harness = WatchHarness();
      await harness.open(tester);
      expect(harness.awake.on, isTrue);
      harness.engine.emit(playing: false);
      await tester.pump();
      expect(harness.awake.on, isFalse);
      harness.engine.emit(playing: true);
      await tester.pump();
      expect(harness.awake.on, isTrue);
    });

    testWidgets('lets the screen sleep when the player is left', (
      tester,
    ) async {
      final harness = WatchHarness();
      await harness.open(tester);
      expect(harness.awake.on, isTrue);
      await tester.pumpWidget(const SizedBox());
      expect(harness.awake.on, isFalse);
    });

    testWidgets('does not hold the screen while only preparing', (
      tester,
    ) async {
      final hold = Completer<void>();
      final harness = WatchHarness(hold: hold);
      await harness.open(tester);
      expect(harness.awake.calls, isEmpty);
      hold.complete();
      await tester.pump();
    });
  });

  group('ChannelScreenAwake', () {
    const channel = MethodChannel(ChannelScreenAwake.channelName);

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });

    test('sends the wish to the platform', () async {
      final calls = <MethodCall>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            calls.add(call);
            return null;
          });
      await ChannelScreenAwake().keepOn(true);
      await ChannelScreenAwake().keepOn(false);
      expect(calls.map((call) => call.method), ['keepOn', 'keepOn']);
      expect(calls.map((call) => call.arguments), [true, false]);
    });

    test('without a platform side it quietly does nothing', () async {
      await expectLater(ChannelScreenAwake().keepOn(true), completes);
    });
  });
}
