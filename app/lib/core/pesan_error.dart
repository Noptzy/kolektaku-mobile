import '../src/rust/error.dart';

String pesanError(BridgeError error) {
  return switch (error.kind) {
    BridgeErrorKind.network =>
      'Tidak bisa terhubung. Periksa koneksi internetmu.',
    BridgeErrorKind.unavailable =>
      'Sumber sedang tidak bisa dijangkau. Coba lagi sebentar lagi.',
    BridgeErrorKind.markupChanged =>
      'Tampilan situs sumber berubah, jadi datanya belum bisa dibaca.',
    BridgeErrorKind.challengeRequired =>
      'Situs sumber meminta verifikasi. Coba sumber lain.',
    BridgeErrorKind.notFound => 'Yang kamu cari tidak ada di sumber ini.',
    BridgeErrorKind.rateLimited => _rateLimited(error.retryAfterSecs),
    BridgeErrorKind.quotaExceeded =>
      'Batas pencarian gambar hari ini tercapai. Coba lagi besok.',
    BridgeErrorKind.unsupported => 'Fitur ini belum didukung oleh sumber ini.',
    BridgeErrorKind.storage =>
      'Penyimpanan di perangkat bermasalah, data belum tersimpan.',
    BridgeErrorKind.notReady =>
      'Aplikasi belum siap. Tunggu sebentar lalu coba lagi.',
  };
}

String _rateLimited(BigInt? retryAfterSecs) {
  if (retryAfterSecs == null) {
    return 'Terlalu banyak permintaan. Coba lagi sebentar lagi.';
  }
  return 'Terlalu banyak permintaan. Coba lagi dalam $retryAfterSecs detik.';
}

bool isOffline(BridgeError error) => error.kind == BridgeErrorKind.network;

bool canRetry(BridgeError error) => switch (error.kind) {
  BridgeErrorKind.network ||
  BridgeErrorKind.unavailable ||
  BridgeErrorKind.rateLimited ||
  BridgeErrorKind.notReady => true,
  _ => false,
};
