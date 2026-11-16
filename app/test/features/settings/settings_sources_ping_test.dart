import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kolektaku/features/settings/source_ping_board.dart';
import 'package:kolektaku/features/settings/source_ping_labels.dart';
import 'package:kolektaku/src/rust/dto/media.dart';
import 'package:kolektaku/src/rust/dto/sources.dart';

import '../../support/fake_source_gateway.dart';
import 'settings_screen_test.dart' show open, status;

SourcePingDto ping(PingVerdictDto verdict, int millis) =>
    SourcePingDto(id: 'a', verdict: verdict, millis: millis);

void main() {
  group('wording', () {
    test('a quick answer shows milliseconds and a slow one seconds', () {
      expect(
        pingReading(ping(PingVerdictDto.online, 320)).text,
        'Aktif · 320 ms',
      );
      expect(
        pingReading(ping(PingVerdictDto.online, 1240)).text,
        'Aktif · 1,2 dtk',
      );
      expect(pingReading(ping(PingVerdictDto.online, 5)).tone, PingTone.good);
    });

    test('a changed page and a dead site have their own wording', () {
      final changed = pingReading(ping(PingVerdictDto.changed, 200));
      expect(changed.text, 'Merespons, tapi tampilannya berubah');
      expect(changed.tone, PingTone.warning);
      final down = pingReading(ping(PingVerdictDto.offline, 8000));
      expect(down.text, 'Tidak bisa dijangkau');
      expect(down.tone, PingTone.bad);
    });
  });

  group('board', () {
    test('every wanted source is checked and its answer kept', () async {
      final gateway = FakeSourceGateway()
        ..verdicts = {'b': PingVerdictDto.offline};
      final board = SourcePingBoard(gateway);
      await board.check(['a', 'b']);
      expect(gateway.pinged, ['a', 'b']);
      expect(board.results['a']!.verdict, PingVerdictDto.online);
      expect(board.results['b']!.verdict, PingVerdictDto.offline);
      expect(board.busy, isFalse);
      board.dispose();
    });

    test('a failing check counts as unreachable instead of crashing', () async {
      final gateway = FakeSourceGateway()..throwing = {'a'};
      final board = SourcePingBoard(gateway);
      await board.check(['a']);
      expect(board.results['a']!.verdict, PingVerdictDto.offline);
      board.dispose();
    });

    test('a source that is still being checked is not asked twice', () async {
      final gate = Completer<void>();
      final gateway = FakeSourceGateway()..gates = {'a': gate};
      final board = SourcePingBoard(gateway);
      final first = board.check(['a']);
      expect(board.busy, isTrue);
      await board.check(['a']);
      gate.complete();
      await first;
      expect(gateway.pinged, ['a']);
      board.dispose();
    });

    test('checking again forgets the older answer first', () async {
      final gateway = FakeSourceGateway();
      final board = SourcePingBoard(gateway);
      await board.check(['a']);
      final gate = Completer<void>();
      gateway.gates = {'a': gate};
      final again = board.check(['a']);
      expect(board.results.containsKey('a'), isFalse);
      gate.complete();
      await again;
      expect(board.results.containsKey('a'), isTrue);
      board.dispose();
    });

    test('a board that was closed ignores a late answer', () async {
      final gate = Completer<void>();
      final gateway = FakeSourceGateway()..gates = {'a': gate};
      final board = SourcePingBoard(gateway);
      final pending = board.check(['a']);
      board.dispose();
      gate.complete();
      await pending;
    });
  });

  group('page', () {
    testWidgets(
      'the button checks every source that is on and shows each answer',
      (tester) async {
        final harness = await open(tester, [
          status('a'),
          status('b'),
          status('c', enabled: false),
        ]);
        harness.sources.verdicts = {'b': PingVerdictDto.offline};
        await tester.tap(find.byKey(const Key('ping-all')));
        await tester.pumpAndSettle();
        expect(harness.sources.pinged, ['a', 'b']);
        final lines = tester
            .widgetList<Text>(find.byKey(const Key('source-ping')))
            .map((text) => text.data)
            .toList();
        expect(lines, ['Aktif · 320 ms', 'Tidak bisa dijangkau']);
      },
    );

    testWidgets('a source that is off is never checked or labelled', (
      tester,
    ) async {
      final harness = await open(tester, [
        status('c', enabled: false),
        status('d', kind: MediaKindDto.manga, enabled: true),
      ]);
      await tester.tap(find.byKey(const Key('ping-all')));
      await tester.pumpAndSettle();
      expect(harness.sources.pinged, ['d']);
    });

    testWidgets('with every source off there is nothing to check', (
      tester,
    ) async {
      await open(tester, [status('c', enabled: false)]);
      expect(find.byKey(const Key('ping-all')), findsNothing);
    });

    testWidgets('while checking the rows say so and the button waits', (
      tester,
    ) async {
      final gate = Completer<void>();
      final harness = await open(tester, [status('a')]);
      harness.sources.gates = {'a': gate};
      await tester.tap(find.byKey(const Key('ping-all')));
      await tester.pump();
      expect(find.text('Mengecek…'), findsNWidgets(2));
      gate.complete();
      await tester.pumpAndSettle();
      expect(find.text('Cek koneksi semua sumber'), findsOneWidget);
    });
  });
}
