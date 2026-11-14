import 'package:flutter_test/flutter_test.dart';
import 'package:kolektaku/platform/payload_poller.dart';

void main() {
  test('returns the first payload the script produces', () async {
    var calls = 0;
    final waits = <Duration>[];
    final payload = await pollForPayload(
      evaluate: () async => ++calls < 3 ? null : '{"sources":[]}',
      wait: (duration) async => waits.add(duration),
    );
    expect(payload, '{"sources":[]}');
    expect(calls, 3);
    expect(waits.length, 2);
  });

  test('null, empty and the text null all mean not ready yet', () async {
    final answers = <Object?>[null, '', '  ', 'null', 42, 'ready'];
    final payload = await pollForPayload(
      evaluate: () async => answers.removeAt(0),
      wait: (_) async {},
    );
    expect(payload, 'ready');
    expect(answers, isEmpty);
  });

  test('a page that throws while it is still mutating is retried', () async {
    var calls = 0;
    final payload = await pollForPayload(
      evaluate: () async {
        if (++calls < 3) throw StateError('page reloading');
        return 'ok';
      },
      wait: (_) async {},
    );
    expect(payload, 'ok');
  });

  test('gives up after the timeout instead of looping forever', () async {
    var calls = 0;
    final future = pollForPayload(
      evaluate: () async {
        calls++;
        return null;
      },
      timeout: const Duration(seconds: 2),
      interval: const Duration(milliseconds: 500),
      wait: (_) async {},
    );
    await expectLater(future, throwsA(isA<PayloadTimeout>()));
    expect(calls, 4);
  });

  test('the timeout error says how long it waited', () {
    expect(
      const PayloadTimeout(Duration(seconds: 45)).toString(),
      contains('45s'),
    );
  });
}
