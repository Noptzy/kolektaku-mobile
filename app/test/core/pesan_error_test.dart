import 'package:flutter_test/flutter_test.dart';
import 'package:kolektaku/core/pesan_error.dart';
import 'package:kolektaku/src/rust/error.dart';

BridgeError error(BridgeErrorKind kind, {int? retryAfter}) => BridgeError(
  kind: kind,
  detail: 'teknis',
  retryAfterSecs: retryAfter == null ? null : BigInt.from(retryAfter),
);

void main() {
  group('pesanError', () {
    test('every kind has a message of its own', () {
      final messages = {
        for (final kind in BridgeErrorKind.values) pesanError(error(kind)),
      };
      expect(messages.length, BridgeErrorKind.values.length);
    });

    test('messages are in Indonesian and never show technical detail', () {
      for (final kind in BridgeErrorKind.values) {
        final message = pesanError(error(kind));
        expect(message, isNotEmpty);
        expect(message, isNot(contains('teknis')));
        expect(message, isNot(matches(RegExp(r'\b(error|failed|timeout)\b'))));
      }
    });

    test('a rate limit names the wait when it is known', () {
      expect(
        pesanError(error(BridgeErrorKind.rateLimited, retryAfter: 30)),
        contains('30 detik'),
      );
      expect(
        pesanError(error(BridgeErrorKind.rateLimited)),
        contains('sebentar lagi'),
      );
    });
  });

  group('error classification', () {
    test('only a network failure counts as offline', () {
      expect(isOffline(error(BridgeErrorKind.network)), isTrue);
      expect(isOffline(error(BridgeErrorKind.unavailable)), isFalse);
    });

    test('transient failures can be retried and permanent ones cannot', () {
      for (final kind in [
        BridgeErrorKind.network,
        BridgeErrorKind.unavailable,
        BridgeErrorKind.rateLimited,
        BridgeErrorKind.notReady,
      ]) {
        expect(canRetry(error(kind)), isTrue, reason: kind.name);
      }
      for (final kind in [
        BridgeErrorKind.notFound,
        BridgeErrorKind.markupChanged,
        BridgeErrorKind.quotaExceeded,
        BridgeErrorKind.unsupported,
        BridgeErrorKind.storage,
        BridgeErrorKind.challengeRequired,
      ]) {
        expect(canRetry(error(kind)), isFalse, reason: kind.name);
      }
    });
  });
}
