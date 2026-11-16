import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../core/kind_names.dart';
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
  return 'Sumber ${kindNoun(kind)} $number';
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
