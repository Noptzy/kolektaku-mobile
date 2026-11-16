import '../../src/rust/dto/media.dart';
import '../../src/rust/dto/sources.dart';

SourceLinkDto? doubtfulLink({
  required MediaKindDto kind,
  required List<SourceLinkDto> links,
  required String? current,
}) {
  if (kind != MediaKindDto.anime) return null;
  final active =
      links.where((link) => link.source == current).firstOrNull ??
      links.firstOrNull;
  if (active == null || active.manual || !active.needsHint) return null;
  return active;
}

String maybeMatchLine(SourceLinkDto link) {
  final title = link.matchedTitle?.trim();
  return title == null || title.isEmpty
      ? 'Sumber belum yakin ini judul yang kamu cari.'
      : 'Sumber menamai judul ini “$title”. Yakin itu yang kamu cari?';
}
