const aboutNotes = (
  version: '0.2.2',
  lines: [
    'Hero Beranda berupa kartu poster yang tajam, tanpa lapisan blur.',
    'Riwayat di Koleksi memakai kartu poster yang sama dengan Favorit.',
    'Pengaturan pemutar membuka pilihan di sheet yang sama, dengan tombol kembali.',
    'Halaman Tentang memuat catatan versi dan sumber data.',
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
