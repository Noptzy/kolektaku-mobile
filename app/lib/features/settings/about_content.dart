const aboutNotes = (
  version: '0.3.1',
  lines: [
    'Memperbaiki pembaruan dari versi 0.2.x yang gagal terpasang dengan pesan paket tidak valid.',
    'Terjemahan otomatis untuk subtitle, sinopsis, dan teks novel, dengan bahasa tujuan yang bisa dipilih di Pengaturan.',
    'Novel menjadi kategori sendiri: ada di Cari, Koleksi, dan Beranda, dengan pembaca teks yang ukuran huruf dan jarak barisnya bisa diatur.',
    'Sumber komik ketiga berbahasa Inggris untuk judul yang tidak ada di sumber Indonesia.',
    'Warna aksen aplikasi bisa dipilih di Pengaturan.',
    'Pencarian komik juga mencoba judul tanpa tanda kurung dan titik dua, sehingga judul seperti Oshi no Ko kini ketemu.',
    'Logo di halaman detail memakai logo asli situs dan jejaring sosial.',
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
