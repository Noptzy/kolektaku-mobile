const aboutNotes = (
  version: '0.4.1',
  lines: [
    'Sumber anime ke-3 sebagai cadangan, dan tombol cek koneksi semua sumber di Kelola sumber.',
    'Coba notifikasi kini meminta izin dan menjelaskan bila gagal; ada tombol Periksa sekarang.',
    'Pemutar lebih mirip YouTube: ketuk dua kali untuk lompat, tahan untuk 2x, geser bilah menampilkan waktu tujuan.',
    'Zoom dua jari di komik berpusat di antara jari.',
    'Film bersubjudul panjang kini ketemu di sumber yang tidak menjawab judul penuh.',
    'Pencarian dari gambar punya tombol Coba dengan contoh.',
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
