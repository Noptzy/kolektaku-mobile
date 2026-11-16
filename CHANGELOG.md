# Catatan perubahan

Format mengikuti [Keep a Changelog](https://keepachangelog.com/id-ID/1.1.0/) dan versi mengikuti [SemVer](https://semver.org/lang/id/).

## [0.4.0] — 2026-11-16

### Ditambahkan
- Notifikasi episode dan chapter baru untuk judul favorit (bunyi "tuturu"), serta notifikasi saat ada versi baru Kolektaku. Diatur di Pengaturan > Notifikasi; izin diminta saat pertama kali memfavoritkan.
- Gulir tersambung di pembaca komik dan novel: chapter berikutnya muncul di bawah dengan pembatas, bisa dimatikan di Pengaturan > Pembaca.
- Gambar di dalam chapter novel (termasuk yang dimuat belakangan) tampil dan bisa diketuk untuk diperbesar.
- Sorotan novel: tahan kata atau kalimat di pembaca novel lalu pilih Sorot; tersimpan di Koleksi → Novel dan membuka paragrafnya lagi bila diketuk.
- Sumber novel cadangan berbahasa Inggris untuk judul yang tidak ada di dua sumber utama (misalnya Hyouka).
- Pilihan suara (dub) di lembar server, dikelompokkan di bawah sumbernya.
- Tombol "Mungkin ini?" bila sumber belum yakin judul yang cocok, dan "Belum tayang" untuk judul yang belum rilis.
- Peringatan "Video ini mungkin bukan filmnya" bila durasi video jauh di bawah durasi film.

### Diubah
- Pencocokan judul ke sumber diperketat: nomor katalog (AniList dan MAL) dipakai lebih dulu; format, tahun, dan status yang beda menolak kecocokan; kembaran dub tidak lagi menimpa entri aslinya. Memperbaiki film belum tayang yang memutar film lain dan kartu ganda "Data terbatas".
- Daftar chapter novel yang dikelompokkan situs kini terbaca, dan judul novel yang hanya beda spasi atau ejaan kini cocok.
- Hasil cari Komik dan Novel tampil ke bawah (bukan menyamping), keadaan kosong tidak terpotong, subtitle naik di atas kontrol pemutar.
- Data (favorit, riwayat, tautan, cache) disimpan dalam satu basis data SQLite; data lama dipindahkan otomatis dan berkasnya disimpan dengan akhiran `.migrated`.
- Pencarian tidak lagi menunggu situs yang lambat lebih dari 4 detik; halaman situs yang pernah dibuka disimpan 15 menit.
- Ukuran paket turun dari 59,4 MB ke sekitar 25 MB (pustaka terkompresi, profil rilis Rust, paket tak terpakai dilepas).
- Pencarian dari gambar tidak lagi membuka kamera otomatis; harus ditekan dulu.

## [0.3.1] — 2026-11-16

### Diperbaiki
- Pembaruan dari versi 0.2.x gagal terpasang dengan pesan "paket tampaknya tidak valid". Penyebabnya nomor build internal 0.3.0 lebih rendah daripada build 0.2.x per-ABI yang terpasang, sehingga Android menolaknya sebagai penurunan versi. Nomor build kini dimulai dari 5001 dan dijaga oleh tes agar selalu di atas semua build lama.
- Rilis 0.3.0 dicabut karena tidak bisa dipasang di atas versi lama; 0.3.1 memuat semua isinya.

## [0.3.0] — 2026-11-16

### Ditambahkan
- Terjemahan otomatis: subtitle bahasa asing, sinopsis, dan teks novel diterjemahkan ke bahasa pilihan (Indonesia dari awal), dengan teks asli tampil dulu dan pilihan "Tampilkan teks asli". Bisa dimatikan atau diganti bahasanya di Pengaturan > Terjemahan otomatis; hasilnya disimpan agar tidak diminta dua kali.
- Novel sebagai kategori ketiga: cakupan di Cari, pengalih Anime · Komik · Novel di Koleksi, rel "Novel populer" di Beranda, dan tombol "Baca novelnya" di detail anime dan komik yang berasal dari light novel.
- Pembaca teks untuk novel: paragraf dan ilustrasi, bar yang bisa disembunyikan, daftar chapter, lembar Tampilan baca (lima ukuran huruf, tiga jarak baris), progres tersimpan per paragraf, dan chapter berikutnya disiapkan lebih dulu.
- Dua sumber novel (Indonesia dan Inggris) dengan pencocokan ketat yang menolak judul fanfiksi, light novel didahulukan daripada web novel.
- Sumber komik ketiga berbahasa Inggris untuk judul yang tidak ada di Komiku dan KomikIndo (misalnya Medalist, Monster, dan Tower of God); dicocokkan lewat nomor katalog yang tercantum di halamannya.
- Warna aksen aplikasi bisa dipilih di Pengaturan > Tampilan, dengan pratinjau langsung.
- Logo asli situs dan jejaring sosial pada tautan di halaman detail.

### Diubah
- Rilis berupa satu berkas `kolektaku-mobile-<versi>.apk` untuk ponsel ARM 64-bit dan 32-bit; varian per ABI dan varian emulator tidak lagi dibagikan.
- Pencarian komik juga mencoba judul tanpa tanda kurung, titik dua, dan tanda seru, sehingga judul seperti "[Oshi no Ko]" kini ketemu di kedua sumber komik.
- Halaman "tidak ada hasil" Komiku dibaca sebagai daftar kosong, bukan sebagai situs yang berubah.
- Novel tidak lagi muncul di daftar Komik. Favorit dan riwayat Komik yang ternyata novel dipindahkan otomatis ke Novel saat aplikasi dibuka dengan internet; berkas lama dicadangkan lebih dulu.

## [0.2.2] — 2026-11-15

### Diubah
- Hero Beranda didesain ulang ala billboard: kartu poster bersudut bulat dengan sampul tajam, gradasi gelap di bawah, teks dan tombol di atas gambar, dan penghitung di pojok kartu. Lapisan blur dihapus karena menimbulkan garis di sebagian ponsel.
- Riwayat di Koleksi memakai kartu poster yang sama dengan Favorit dan ikut menggulir halaman, tidak lagi dalam kotak sendiri.
- Pengaturan pemutar: Resolusi, Subtitle, Suara, dan Kecepatan membuka daftar pilihannya di sheet yang sama dengan tombol kembali; teks lebih kecil dan selalu satu baris. Tombol kembali sistem kembali ke menu dulu sebelum menutup sheet.
- Halaman Tentang memuat catatan versi terpasang dan sumber data.

### Dihapus
- Kotak riwayat yang menggulir sendiri, serta keterangan persen tonton dan "x jam lalu" di baris riwayat.

## [0.2.1] — 2026-11-14

### Ditambahkan
- Pembaruan otomatis: aplikasi mengecek rilis baru setiap dibuka (tanpa batas 12 jam), mengunduhnya sendiri, dan menampilkan sheet untuk memasangnya; "Cek pembaruan" di Pengaturan tetap bisa dipakai kapan saja dan status "sudah terbaru" menyebut versi terpasang.
- Status "sudah versi terbaru" di Pengaturan menyebut versi yang terpasang.

### Diubah
- Pengecekan pembaruan saat dibuka tidak lagi dibatasi 12 jam.

## [0.2.0] — 2026-11-14

### Ditambahkan
- Hero Beranda berkategori dan berputar otomatis: rating tertinggi minggu ini, terbaru, baru saja tamat, baru saja comeback, dan sedang ramai; tiap slide punya sinopsis singkat dan sampul yang tajam.
- Tombol pengaturan di pemutar: resolusi, subtitle, suara (sub atau dub), dan kecepatan dalam satu tempat.
- Pertanyaan "Lanjut dari menit sekian atau mulai dari awal" saat episode punya progres.
- Zoom cubit di pembaca komik.
- Semua sheet bawah bisa ditutup dengan menggeser ke bawah.
- Koleksi: pengalih Anime/Komik penuh lebar, riwayat dalam kotak sendiri yang bisa digulir, dan riwayat langsung membuka episode atau chapter itu. Data Koleksi disegarkan setiap tab dibuka.
- Filter Anime/Komik di baris Lanjutkan pada Beranda.
- Cache: gambar disimpan di perangkat, jawaban katalog disimpan beberapa menit (juga dipakai saat offline), dan detail, daftar episode, serta tautan video diingat di memori sehingga kembali ke layar yang sama tidak memuat ulang.

### Diubah
- Istilah "manga" di layar menjadi "komik"; satuan komik ditulis "chapter".
- Skeleton kartu menggantikan spinner saat hasil pencarian dimuat.
- Pencarian sumber ikut memakai judul sinonim, jadi lebih banyak komik dan anime yang ditemukan.
- Pesan "Chapter tidak ditemukan" atau "Episode tidak ditemukan" menggantikan pesan error umum.

### Diperbaiki
- Ikon pengaturan di Koleksi berpindah ke tab Pengaturan, tidak lagi menumpuk halaman di dalam Koleksi.
- Skeleton halaman detail, pratinjau subtitle, dan deretan titik warna subtitle tampil benar.

## [0.1.0] — 2026-11-14

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
