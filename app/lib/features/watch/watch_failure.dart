import '../../core/pesan_error.dart';
import '../../src/rust/error.dart';

const _fallback = 'Terjadi masalah saat membuka episode. Coba lagi.';

String watchFailureMessage(Object? error) {
  if (error is BridgeError) return pesanError(error);
  return _fallback;
}
