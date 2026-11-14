import 'package:flutter_test/flutter_test.dart';
import 'package:kolektaku/features/watch/player/player_session.dart';
import 'package:kolektaku/platform/stream_resolver.dart';
import 'package:kolektaku/src/rust/dto/stream.dart';

import 'fake_engine.dart';

StreamSourceDto source(int quality, {bool isDefault = false, String? host}) =>
    StreamSourceDto(
      url: 'https://${host ?? 'cdn'}.test/v-$quality.mp4',
      kind: 'mp4',
      quality: quality,
      label: '${quality}p',
      isDefault: isDefault,
    );

ResolvedStream stream({String? host}) => ResolvedStream(
  set: StreamSetDto(
    sources: [
      source(720, isDefault: true, host: host),
      source(480, host: host),
    ],
    headers: const [],
    subtitles: const [],
    skips: const [],
  ),
  headers: const {'Referer': 'https://site.test/ep'},
);

class Rig {
  Rig({Refetch? refetch}) {
    session = PlayerSession(
      engine: engine,
      stream: stream(),
      refetch:
          refetch ??
          () async {
            refetches++;
            return stream(host: 'fresh');
          },
      onProgress: (position, length) => reports.add(position.inSeconds),
    );
  }

  final FakeEngine engine = FakeEngine();
  final List<int> reports = [];
  int refetches = 0;
  late final PlayerSession session;
}

void main() {
  test('starts on the default quality at the requested position', () async {
    final rig = Rig();
    await rig.session.start(const Duration(seconds: 90));
    expect(rig.engine.opened.single.url, 'https://cdn.test/v-720.mp4');
    expect(rig.engine.opened.single.headers['Referer'], 'https://site.test/ep');
    expect(rig.engine.startedAt.single, const Duration(seconds: 90));
  });

  test('skipping moves ten seconds and never leaves the video', () async {
    final rig = Rig();
    await rig.session.start(const Duration(seconds: 5));
    await rig.session.skip(const Duration(seconds: 10));
    expect(rig.engine.snapshot.value.position, const Duration(seconds: 15));
    await rig.session.skip(const Duration(seconds: -10));
    await rig.session.skip(const Duration(seconds: -10));
    expect(rig.engine.snapshot.value.position, Duration.zero);
    await rig.session.skip(const Duration(hours: 5));
    expect(rig.engine.snapshot.value.position, rig.engine.length);
  });

  test('the speed and the play state are forwarded to the engine', () async {
    final rig = Rig();
    await rig.session.start(Duration.zero);
    await rig.session.setSpeed(1.5);
    await rig.session.togglePlay();
    await rig.session.togglePlay();
    expect(rig.engine.log, containsAllInOrder(['speed 1.5', 'pause', 'play']));
  });

  test('a seek bar fraction maps onto the length and is clamped', () async {
    final rig = Rig();
    await rig.session.start(Duration.zero);
    await rig.session.seekToFraction(0.5);
    expect(rig.engine.snapshot.value.position, const Duration(minutes: 12));
    await rig.session.seekToFraction(7);
    expect(rig.engine.snapshot.value.position, rig.engine.length);
  });

  test('changing quality reopens at the same position', () async {
    final rig = Rig();
    await rig.session.start(Duration.zero);
    rig.engine.emit(position: const Duration(seconds: 200), playing: true);
    await rig.session.selectQuality(1);
    expect(rig.engine.opened.last.url, 'https://cdn.test/v-480.mp4');
    expect(rig.engine.startedAt.last, const Duration(seconds: 200));
    expect(rig.session.quality.value, 1);
    await rig.session.selectQuality(1);
    await rig.session.selectQuality(9);
    expect(rig.engine.opened.length, 2);
  });

  test('an expired link is fetched once and playback resumes', () async {
    final rig = Rig();
    await rig.session.start(Duration.zero);
    rig.engine.emit(position: const Duration(seconds: 300), playing: true);
    rig.engine.emit(failure: 'http 403');
    await Future<void>.delayed(Duration.zero);
    expect(rig.refetches, 1);
    expect(rig.engine.opened.last.url, 'https://fresh.test/v-720.mp4');
    expect(rig.engine.startedAt.last, const Duration(seconds: 300));
    expect(rig.session.failure.value, isNull);
  });

  test(
    'a failure before reaching the start time resumes at the start',
    () async {
      final rig = Rig();
      rig.engine.reachesStart = false;
      await rig.session.start(const Duration(minutes: 10));
      rig.engine.emit(position: Duration.zero, failure: 'Source error');
      await Future<void>.delayed(Duration.zero);
      expect(rig.refetches, 1);
      expect(rig.engine.startedAt.last, const Duration(minutes: 10));
    },
  );

  test('a failure right after a seek resumes at the seek target', () async {
    final rig = Rig();
    await rig.session.start(Duration.zero);
    rig.engine.emit(position: const Duration(seconds: 30), playing: true);
    rig.engine.seeksLand = false;
    await rig.session.skip(const Duration(seconds: 10));
    rig.engine.emit(position: const Duration(seconds: 30), failure: 'x');
    await Future<void>.delayed(Duration.zero);
    expect(rig.engine.startedAt.last, const Duration(seconds: 40));
  });

  test('a second failure is shown instead of retrying forever', () async {
    final rig = Rig();
    await rig.session.start(Duration.zero);
    rig.engine.emit(failure: 'http 403');
    await Future<void>.delayed(Duration.zero);
    rig.engine.emit(failure: 'http 403 again');
    await Future<void>.delayed(Duration.zero);
    expect(rig.refetches, 1);
    expect(rig.session.failure.value, 'http 403 again');
  });

  test('retry allows one more fresh fetch', () async {
    final rig = Rig();
    await rig.session.start(Duration.zero);
    rig.engine.emit(failure: 'x');
    await Future<void>.delayed(Duration.zero);
    rig.engine.emit(failure: 'y');
    await Future<void>.delayed(Duration.zero);
    await rig.session.retry();
    expect(rig.refetches, 2);
    expect(rig.session.failure.value, isNull);
  });

  test('a refetch that fails is reported as the failure', () async {
    final rig = Rig(refetch: () async => throw StateError('offline'));
    await rig.session.start(Duration.zero);
    rig.engine.emit(failure: 'http 403');
    await Future<void>.delayed(Duration.zero);
    expect(rig.session.failure.value, contains('offline'));
  });

  test('progress is reported every five seconds and once on close', () async {
    final rig = Rig();
    await rig.session.start(Duration.zero);
    for (final second in [1, 3, 6, 8, 12, 13]) {
      rig.engine.emit(position: Duration(seconds: second), playing: true);
    }
    expect(rig.reports, [1, 6, 12]);
    await rig.session.close();
    expect(rig.reports.last, 13);
    expect(rig.engine.disposed, isTrue);
  });

  test('closing twice or before playing reports nothing extra', () async {
    final rig = Rig();
    await rig.session.start(Duration.zero);
    rig.engine.emit(position: Duration.zero, playing: false);
    await rig.session.close();
    await rig.session.close();
    expect(rig.reports, isEmpty);
    expect(rig.engine.log.where((entry) => entry == 'dispose').length, 1);
  });
}
