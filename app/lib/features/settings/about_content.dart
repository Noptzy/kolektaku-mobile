const aboutNotes = (
  version: '0.5.0',
  lines: [
    'Unduh episode anime: satu, beberapa, atau semua sekaligus, jadi satu file MKV dengan subtitle terjemahan di Movies/Kolektaku.',
    'Tombol bulat dengan cincin progres muncul di atas navbar selama mengunduh; ketuk untuk membuka halaman Unduhan.',
    'Pengaturan Unduhan: pilih kualitas dan subtitle yang ikut disimpan.',
    'Riwayat kini berupa daftar dengan kotak cari, dan bisa digeser untuk menghapus satu riwayat.',
    'Sumber anime ke-3 kini juga dicari untuk judul yang sudah pernah dibuka.',
    'Subtitle yang kamu pilih sendiri tidak lagi diterjemahkan diam-diam.',
  ],
);

const aboutLines = [
  'Katalog, skor, dan data karakter dari AniList.',
  'Judul episode dari MyAnimeList.',
  'Pencarian dari gambar oleh trace.moe.',
  'Video, komik, dan novel diambil dari situs pihak ketiga yang bisa '
      'dimatikan di Kelola sumber.',
  'Terjemahan otomatis memakai layanan terjemahan daring.',
  'Pembaruan aplikasi diambil dari halaman Releases di GitHub.',
];

List<String> notesFor(String? installed) =>
    installed == aboutNotes.version ? aboutNotes.lines : const [];
