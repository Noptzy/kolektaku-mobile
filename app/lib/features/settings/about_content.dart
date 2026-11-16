const aboutNotes = (
  version: '0.4.0',
  lines: [
    'Notifikasi saat favoritmu punya episode atau chapter baru, dan saat ada versi baru Kolektaku.',
    'Komik dan novel mengalir tersambung: chapter berikutnya muncul di bawah dengan pembatas.',
    'Sorot kalimat di novel, lalu temukan lagi di Koleksi.',
    'Pencocokan judul diperketat: film yang belum tayang tidak lagi memutar film lain, dan dub tidak lagi jadi kartu ganda.',
    'Novel yang tidak ada di dua sumber utama kini dicari di sumber cadangan.',
    'Gambar di dalam chapter novel tampil dan bisa diperbesar.',
    'Pencarian lebih cepat dan data disimpan lebih rapi; datamu dipindahkan otomatis.',
    'Pencarian dari gambar tidak lagi membuka kamera sendiri.',
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
