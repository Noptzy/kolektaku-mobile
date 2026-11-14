const aboutNotes = (
  version: '0.2.1',
  lines: [
    'Kolektaku mengecek versi baru setiap kali dibuka dan mengunduhnya sendiri.',
    'Tombol Cek pembaruan tetap ada, dan statusnya menyebut versi terpasang.',
  ],
);

const aboutLines = [
  'Katalog, skor, dan data karakter dari AniList.',
  'Judul episode dari MyAnimeList.',
  'Pencarian dari gambar oleh trace.moe.',
  'Video dan komik diambil dari situs pihak ketiga yang bisa dimatikan di '
      'Kelola sumber.',
  'Pembaruan aplikasi diambil dari halaman Releases di GitHub.',
];

List<String> notesFor(String? installed) =>
    installed == aboutNotes.version ? aboutNotes.lines : const [];
