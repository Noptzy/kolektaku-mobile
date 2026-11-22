const welcomeBrandName = 'Kolektaku';

class WelcomePage {
  const WelcomePage({required this.title, required this.body});

  final String title;
  final String body;
}

const welcomePages = [
  WelcomePage(
    title: 'Anime, komik, dan novel dalam satu aplikasi.',
    body:
        'Cari, tonton, dan baca tanpa pindah-pindah aplikasi. Koleksi dan '
        'riwayatmu ikut satu tempat.',
  ),
  WelcomePage(
    title: 'Cari judul, atau cari dari gambar adegan.',
    body:
        'Ketik judulnya, atau pilih tangkapan layar. Hasilnya dicocokkan '
        'dengan data AniList dan trace.moe.',
  ),
  WelcomePage(
    title: 'Lanjut persis di tempat kamu berhenti.',
    body:
        'Episode dan chapter terakhir tersimpan, jadi kamu bisa lanjut dari '
        'menit atau halaman yang sama.',
  ),
  WelcomePage(
    title: 'Tanpa akun, tanpa server.',
    body:
        'Semua berjalan di HP-mu. Kolektaku mengambil data dan video langsung '
        'dari sumbernya, tanpa perantara. Riwayatmu tidak pernah keluar dari '
        'HP.',
  ),
  WelcomePage(
    title: 'Atur sesukamu, kapan saja.',
    body:
        'Pilih sumber, warna aksen, dan bahasa terjemahan di Pengaturan. '
        'Sambutan ini bisa kamu lihat lagi dari Pengaturan > Tentang.',
  ),
];

const welcomeSkipLabel = 'Lewati';
const welcomeNextLabel = 'Lanjut';
const welcomeStartLabel = 'Mulai';
