# Catatan perubahan

Format mengikuti [Keep a Changelog](https://keepachangelog.com/id-ID/1.1.0/) dan versi mengikuti [SemVer](https://semver.org/lang/id/).

## [Belum dirilis] — 0.1.0

Penulisan ulang total: antarmuka Flutter dengan inti Rust.

### Ditambahkan
- Beranda gabungan anime dan manga, dengan porsi yang mengikuti pilihan "Lebih suka" di Pengaturan.
- Pencarian universal: anime, manga, karakter, staf (pengisi suara, penulis, sutradara), dan studio. Nama studio yang diketik di pencarian anime otomatis tampil terpisah di atas hasil.
- Filter pencarian: genre, format, status tayang/terbit, sumber cerita, urutan, dan tahun, termasuk menjelajah hanya dengan filter.
- Halaman profil karakter, staf, dan studio dengan biodata dan tautan sosial.
- Info di halaman detail yang bisa diklik: studio, format, status, sumber cerita, dan genre membuka pencarian atau profil terkait.
- Pencarian dari gambar (kamera atau berbagi gambar).
- Dua sumber video anime dengan penjelasan perbedaannya; sumber utama bisa dipilih di Pengaturan, dan aplikasi otomatis beralih bila sumber gagal.
- Pemutar: kualitas, kecepatan, lewati intro dan outro (penanda di bar geser), pilihan server Sub/Dub dengan bahasa audio, subtitle dengan pratinjau (ukuran, warna, tepi, latar), layar tetap menyala saat memutar, dan PiP.
- Pembaca manga, tautan silang anime dan manga, serta Koleksiku (lanjutkan, favorit, riwayat).
- Pengaturan berbentuk daftar dengan sub-halaman dan penjelasan.
- Pembaruan sendiri: cek otomatis paling sering 12 jam sekali, cek manual, catatan rilis, unduhan dengan progres dan verifikasi SHA-256.

### Diubah
- Skeleton pemuatan lebih terlihat; judul episode dimuat paralel dengan pencocokan sumber sehingga detail terbuka lebih cepat.
- Sheet dan modal memakai sudut membulat dengan garis tepi.

### Diperbaiki
- Entri ganda dari satu sumber (rilis yang sama terdaftar dua kali) tidak lagi ditawarkan dua kali.
- Server "Dub" yang sebenarnya menunjuk ke video Sub tidak lagi ditawarkan.
