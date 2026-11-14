import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../src/rust/dto/media.dart';
import '../../src/rust/dto/sources.dart';

typedef SourceEntry = ({SourceStatusDto status, int number});

final appVersionProvider = FutureProvider<String>((ref) async {
  final info = await PackageInfo.fromPlatform();
  return info.version;
});

List<SourceEntry> numberedSources(
  List<SourceStatusDto> all,
  MediaKindDto kind,
) {
  final own = all.where((item) => item.kind == kind).toList();
  return [
    for (var index = 0; index < own.length; index++)
      (status: own[index], number: index + 1),
  ];
}

String sourceLabel(MediaKindDto kind, int number) {
  final name = kind == MediaKindDto.anime ? 'anime' : 'komik';
  return 'Sumber $name $number';
}

String sourceHint(SourceStatusDto status) {
  if (!status.enabled) return 'Dimatikan';
  if (status.skipped) return 'Sedang dilewati karena bermasalah';
  return 'Aktif';
}

bool allOff(List<SourceEntry> entries) =>
    entries.isNotEmpty && entries.every((entry) => !entry.status.enabled);

String versionLabel(String? version) => version == null || version.isEmpty
    ? 'Versi tidak diketahui'
    : 'Versi $version';

const aboutLines = [
  'Katalog, skor, dan data karakter dari AniList.',
  'Judul episode dari MyAnimeList.',
  'Pencarian dari gambar oleh trace.moe.',
];
