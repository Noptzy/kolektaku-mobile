import '../../core/pesan_error.dart';
import '../../src/rust/error.dart';

String readFailureMessage(Object? error) {
  if (error is BridgeError) return pesanError(error);
  return 'Terjadi masalah saat membuka chapter. Coba lagi.';
}
