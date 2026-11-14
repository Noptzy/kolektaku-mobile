import 'update_state.dart';

String megabytes(int bytes) {
  final value = bytes / (1024 * 1024);
  return '${value.toStringAsFixed(1).replaceAll('.', ',')} MB';
}

String percentLabel(double? fraction) =>
    fraction == null ? '' : '${(fraction * 100).round()}%';

String updateStatus(UpdateState state) {
  final version = state.offer?.version ?? '';
  return switch (state.phase) {
    UpdatePhase.idle =>
      'Cek apakah ada versi baru. Pengecekan otomatis berjalan paling '
          'sering 12 jam sekali.',
    UpdatePhase.checking => 'Memeriksa pembaruan…',
    UpdatePhase.upToDate => 'Kolektaku sudah versi terbaru.',
    UpdatePhase.available => 'Versi $version tersedia.',
    UpdatePhase.downloading => 'Mengunduh versi $version…',
    UpdatePhase.ready => 'Versi $version siap dipasang.',
    UpdatePhase.installing => 'Memasang versi $version…',
    UpdatePhase.failed =>
      'Pembaruan belum berhasil. Periksa koneksi, lalu coba lagi.',
  };
}

String updateSummary(UpdateState state, String? installed) {
  final version = state.offer?.version;
  return switch (state.phase) {
    UpdatePhase.available ||
    UpdatePhase.downloading ||
    UpdatePhase.ready ||
    UpdatePhase.installing => 'Versi $version tersedia',
    UpdatePhase.checking => 'Memeriksa…',
    UpdatePhase.upToDate => 'Sudah versi terbaru',
    UpdatePhase.failed => 'Belum berhasil, coba lagi',
    UpdatePhase.idle =>
      installed == null || installed.isEmpty
          ? 'Cek versi baru'
          : 'Versi $installed · cek versi baru',
  };
}
