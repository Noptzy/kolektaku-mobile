import 'dart:async';

class PayloadTimeout implements Exception {
  const PayloadTimeout(this.waited);

  final Duration waited;

  @override
  String toString() => 'no stream payload after ${waited.inSeconds}s';
}

typedef Wait = Future<void> Function(Duration duration);

Future<void> realWait(Duration duration) => Future<void>.delayed(duration);

String? _payloadOf(Object? result) {
  if (result is! String) return null;
  final text = result.trim();
  if (text.isEmpty || text == 'null') return null;
  return text;
}

Future<String> pollForPayload({
  required Future<Object?> Function() evaluate,
  Duration timeout = const Duration(seconds: 45),
  Duration interval = const Duration(milliseconds: 350),
  Wait wait = realWait,
}) async {
  var waited = Duration.zero;
  while (waited < timeout) {
    Object? result;
    try {
      result = await evaluate();
    } on Object {
      result = null;
    }
    final payload = _payloadOf(result);
    if (payload != null) return payload;
    await wait(interval);
    waited += interval;
  }
  throw PayloadTimeout(timeout);
}
