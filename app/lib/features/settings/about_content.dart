const aboutNotes = (
  version: '0.6.0',
  lines: [
    'Tampilan baru: dock navigasi melayang berbahan kaca, kartu Lanjutkan yang lebih informatif, dan bintang skor di baris info kartu.',
    'Top 10 kini satu rail dengan sakelar Anime dan Komik, dan hero memakai tombol ikon untuk Simpan dan Trailer.',
    'Sambutan lima halaman untuk pemasangan baru; bisa dilihat lagi dari Pengaturan > Tentang.',
    'Toast Urungkan di Koleksi bisa digeser untuk ditutup, dan riwayat bergetar ringan saat digeser untuk dihapus.',
    'Pemuat bergambar garis tipis untuk persiapan stream, pencarian dari gambar, dan daftar genre.',
    'Mengetuk Beranda saat sudah di Beranda menggulir ke atas, dan Pengaturan dikelompokkan ulang.',
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
