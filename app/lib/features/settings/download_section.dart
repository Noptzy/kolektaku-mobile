import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../core/routes.dart';
import '../../core/theme/kolektaku_tokens.dart';
import '../../data/providers/download_providers.dart';
import '../../src/rust/dto/downloads.dart';
import 'settings_widgets.dart';

const downloadSubtitleOptions = [
  (DownloadSubtitlesDto.translated, 'Terjemahan otomatis + teks asli'),
  (DownloadSubtitlesDto.original, 'Teks asli saja'),
  (DownloadSubtitlesDto.off, 'Tanpa subtitle'),
];

const downloadQualityOptions = [
  ('1080', '1080p'),
  ('720', '720p'),
  ('480', '480p'),
  ('360', '360p'),
  ('auto', 'Terbaik yang ada'),
];

String downloadSummary(DownloadSettingsDto? settings) {
  if (settings == null) return 'MKV dengan subtitle';
  final quality = downloadQualityOptions
      .firstWhere(
        (option) => option.$1 == settings.quality,
        orElse: () => downloadQualityOptions[1],
      )
      .$2;
  final subtitles = switch (settings.subtitles) {
    DownloadSubtitlesDto.translated => 'subtitle terjemahan',
    DownloadSubtitlesDto.original => 'subtitle asli',
    DownloadSubtitlesDto.off => 'tanpa subtitle',
  };
  return '$quality · $subtitles';
}

class DownloadSection extends ConsumerWidget {
  const DownloadSection({super.key});

  Future<void> _save(WidgetRef ref, DownloadSettingsDto settings) async {
    await ref.read(downloadGatewayProvider).saveSettings(settings);
    ref.invalidate(downloadSettingsProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(downloadSettingsProvider).value;
    if (settings == null) return const SizedBox(height: 120);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ChoiceRow<DownloadSubtitlesDto>(
          title: 'Subtitle di dalam file',
          hint:
              'Subtitle asing diterjemahkan ke bahasa di Pengaturan › '
              'Terjemahan otomatis saat diunduh. Subtitle buatan manusia '
              'dalam bahasamu dipakai bila tersedia.',
          options: downloadSubtitleOptions,
          value: settings.subtitles,
          onChanged: (value) => _save(
            ref,
            DownloadSettingsDto(subtitles: value, quality: settings.quality),
          ),
        ),
        ChoiceRow<String>(
          title: 'Kualitas unduhan',
          hint: 'Makin tinggi makin besar filenya (24 menit 720p ± 300 MB).',
          options: downloadQualityOptions,
          value: settings.quality,
          onChanged: (value) => _save(
            ref,
            DownloadSettingsDto(subtitles: settings.subtitles, quality: value),
          ),
        ),
        const SettingsNote(
          'Hasilnya satu file MKV (video, suara, dan subtitle yang bisa '
          'dipilih) di folder Movies/Kolektaku, bisa diputar di VLC atau MX '
          'Player. Unduhan tetap berjalan saat aplikasi di latar belakang.',
        ),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: Spacing.screenGutter,
            vertical: Spacing.sm,
          ),
          child: ShadButton.outline(
            key: const Key('open-downloads'),
            onPressed: () => context.push(Routes.downloads),
            leading: const Icon(LucideIcons.download, size: 16),
            child: const Text('Lihat unduhan'),
          ),
        ),
      ],
    );
  }
}
