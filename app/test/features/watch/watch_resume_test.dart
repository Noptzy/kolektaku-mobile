import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kolektaku/features/watch/episode_loader.dart';
import 'package:kolektaku/features/watch/resume_gate.dart';
import 'package:kolektaku/features/watch/watch_resume_sheet.dart';
import 'package:kolektaku/src/rust/dto/stream.dart';
import 'package:kolektaku/platform/stream_resolver.dart';
import 'package:kolektaku/src/rust/dto/sources.dart';

import 'watch_harness.dart';

const _saved = Duration(seconds: 90);

LoadedEpisode episode() => LoadedEpisode(
  playback: PlaybackDto(
    source: 's',
    item: 'i',
    unit: const UnitDto(id: '1', number: 1, label: 'Episode 1'),
    servers: const [],
    audioOptions: const [],
  ),
  stream: const ResolvedStream(
    set: StreamSetDto(sources: [], headers: [], subtitles: [], skips: []),
    headers: {},
  ),
  serverId: 'a',
);

void main() {
  group('ResumeGate', () {
    test('holds an episode with where it was left', () {
      final gate = ResumeGate()..hold(episode(), _saved, 3);
      expect(gate.waitingFor, _saved);
    });

    test('releasing hands it over once and then forgets it', () {
      final gate = ResumeGate()..hold(episode(), _saved, 3);
      expect(gate.release()?.generation, 3);
      expect(gate.release(), isNull);
      expect(gate.waitingFor, isNull);
    });

    test('clear drops what is held', () {
      final gate = ResumeGate()
        ..hold(episode(), _saved, 1)
        ..clear();
      expect(gate.waitingFor, isNull);
    });

    test('settling with resume begins at the saved position', () async {
      final gate = ResumeGate()..hold(episode(), _saved, 4);
      final begun = <(Duration, int)>[];
      await gate.settle(
        resume: true,
        begin: (_, position, generation) async =>
            begun.add((position, generation)),
        isCurrent: (generation) => generation == 4,
        onError: (_) {},
      );
      expect(begun, [(_saved, 4)]);
    });

    test('settling without resume begins from the start', () async {
      final gate = ResumeGate()..hold(episode(), _saved, 4);
      Duration? at;
      await gate.settle(
        resume: false,
        begin: (_, position, _) async => at = position,
        isCurrent: (_) => true,
        onError: (_) {},
      );
      expect(at, Duration.zero);
    });

    test(
      'a newer load makes the held answer stale and nothing begins',
      () async {
        final gate = ResumeGate()..hold(episode(), _saved, 4);
        var begun = false;
        await gate.settle(
          resume: true,
          begin: (_, _, _) async => begun = true,
          isCurrent: (generation) => generation == 5,
          onError: (_) {},
        );
        expect(begun, isFalse);
      },
    );

    test('settling with nothing held does nothing', () async {
      var begun = false;
      await ResumeGate().settle(
        resume: true,
        begin: (_, _, _) async => begun = true,
        isCurrent: (_) => true,
        onError: (_) {},
      );
      expect(begun, isFalse);
    });

    test('a failure while beginning is reported while it is current', () async {
      final gate = ResumeGate()..hold(episode(), _saved, 2);
      Object? reported;
      await gate.settle(
        resume: true,
        begin: (_, _, _) async => throw StateError('boom'),
        isCurrent: (_) => true,
        onError: (failure) => reported = failure,
      );
      expect(reported, isA<StateError>());
    });
  });

  group('the sheet words', () {
    test('it names the minute where the person stopped', () {
      expect(resumeQuestion(_saved), 'Terakhir kamu berhenti di 01:30.');
    });
  });

  group('the resume question on screen', () {
    testWidgets('waits for an answer before playing anything', (tester) async {
      final harness = WatchHarness(resume: _saved);
      await harness.open(tester);
      expect(find.text('Lanjutkan menonton?'), findsOneWidget);
      expect(find.text('Lanjut dari 01:30'), findsOneWidget);
      expect(find.text('Mulai dari awal'), findsOneWidget);
      expect(harness.engine.startedAt, isEmpty);
    });

    testWidgets('continuing plays from the saved minute', (tester) async {
      final harness = WatchHarness(resume: _saved);
      await harness.open(tester);
      await tester.tap(find.byKey(const Key('resume-continue')));
      await tester.pumpAndSettle();
      expect(harness.engine.startedAt.single, _saved);
      expect(find.text('Lanjutkan menonton?'), findsNothing);
    });

    testWidgets('starting over plays from the beginning', (tester) async {
      final harness = WatchHarness(resume: _saved);
      await harness.open(tester);
      await tester.tap(find.byKey(const Key('resume-restart')));
      await tester.pumpAndSettle();
      expect(harness.engine.startedAt.single, Duration.zero);
    });

    testWidgets('swiping the question away carries on from the saved minute', (
      tester,
    ) async {
      final harness = WatchHarness(resume: _saved);
      await harness.open(tester);
      await tester.drag(find.text('Lanjutkan menonton?'), const Offset(0, 300));
      await tester.pumpAndSettle();
      expect(harness.engine.startedAt.single, _saved);
    });

    testWidgets('a start time given by the caller skips the question', (
      tester,
    ) async {
      final harness = WatchHarness(
        resume: _saved,
        startAt: const Duration(seconds: 276),
      );
      await harness.open(tester);
      expect(find.text('Lanjutkan menonton?'), findsNothing);
      expect(harness.engine.startedAt.single, const Duration(seconds: 276));
    });

    testWidgets('nothing saved means no question', (tester) async {
      final harness = WatchHarness();
      await harness.open(tester);
      expect(find.text('Lanjutkan menonton?'), findsNothing);
      expect(harness.engine.startedAt.single, Duration.zero);
    });
  });
}
