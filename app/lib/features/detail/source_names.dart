import '../../src/rust/dto/media.dart';
import '../../src/rust/dto/sources.dart';
import '../settings/settings_logic.dart';

typedef SourceNames = ({
  Map<String, String> labels,
  Map<String, String> summaries,
});

SourceNames sourceNamesOf(List<SourceStatusDto> statuses, MediaKindDto kind) {
  final entries = numberedSources(statuses, kind);
  return (
    labels: {
      for (final entry in entries)
        entry.status.id: sourceLabel(kind, entry.number),
    },
    summaries: {
      for (final entry in entries)
        if (entry.status.summary.trim().isNotEmpty)
          entry.status.id: entry.status.summary.trim(),
    },
  );
}

String unitNoun(MediaKindDto kind) =>
    kind == MediaKindDto.anime ? 'episode' : 'chapter';

String? completenessNote({
  required MediaKindDto kind,
  required int loaded,
  required int? expected,
  required bool canSwitch,
}) {
  if (expected == null || expected <= 0 || loaded >= expected) return null;
  final base =
      'Baru ada $loaded dari $expected ${unitNoun(kind)} di sumber ini.';
  return canSwitch ? '$base Coba ganti sumber.' : base;
}

String? sourceLine(String? label, String? summary) {
  if (label == null) return null;
  return summary == null ? label : '$label · $summary';
}
