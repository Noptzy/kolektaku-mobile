import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../core/routes.dart';

enum SettingsPage {
  preference(
    slug: 'beranda',
    title: 'Beranda',
    icon: LucideIcons.house,
    intro:
        'Atur isi Beranda: lebih banyak anime atau lebih banyak komik. '
        'Keduanya tetap tampil, hanya porsinya yang berubah.',
  ),
  sourceChoice(
    slug: 'sumber-video',
    title: 'Sumber video anime',
    icon: LucideIcons.server,
    intro:
        'Sumber utama dicoba lebih dulu. Kalau episodenya tidak ada atau '
        'gagal, aplikasi otomatis memakai sumber lain yang masih aktif.',
  ),
  subtitle(
    slug: 'subtitle',
    title: 'Subtitle',
    icon: LucideIcons.captions,
    intro:
        'Atur bahasa dan tampilan subtitle. Pratinjau di atas langsung '
        'berubah, jadi kamu bisa lihat hasilnya sebelum menonton.',
  ),
  player(
    slug: 'pemutar',
    title: 'Pemutar',
    icon: LucideIcons.circlePlay,
    intro: 'Atur kualitas awal dan perilaku otomatis saat menonton.',
  ),
  sources(
    slug: 'kelola-sumber',
    title: 'Kelola sumber',
    icon: LucideIcons.slidersHorizontal,
    intro:
        'Matikan sumber yang sedang bermasalah. Aplikasi akan memakai '
        'sumber lain yang masih aktif.',
  ),
  update(
    slug: 'pembaruan',
    title: 'Pembaruan',
    icon: LucideIcons.circleArrowDown,
    intro:
        'Kolektaku memeriksa versi baru sendiri paling sering 12 jam sekali. '
        'Kamu juga bisa memeriksanya sekarang.',
  ),
  about(
    slug: 'tentang',
    title: 'Tentang',
    icon: LucideIcons.info,
    intro: 'Informasi aplikasi dan sumber datanya.',
  );

  const SettingsPage({
    required this.slug,
    required this.title,
    required this.icon,
    required this.intro,
  });

  final String slug;
  final String title;
  final IconData icon;
  final String intro;

  String get path => '${Routes.settings}/$slug';

  static SettingsPage? fromSlug(String slug) {
    for (final page in values) {
      if (page.slug == slug) return page;
    }
    return null;
  }
}
