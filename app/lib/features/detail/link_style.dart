import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../src/rust/dto/links.dart';

const maxShownLinks = 6;

IconData linkIcon(String site) {
  return switch (site.toLowerCase().trim()) {
    'twitter' || 'x' => LucideIcons.messageCircle,
    'instagram' => LucideIcons.camera,
    'facebook' => LucideIcons.share2,
    'youtube' => LucideIcons.squarePlay,
    'tiktok' => LucideIcons.music,
    'official site' => LucideIcons.globe,
    _ => LucideIcons.link,
  };
}

String linkLabel(String site) {
  return switch (site.toLowerCase().trim()) {
    'official site' => 'Situs resmi',
    'x' => 'Twitter',
    _ => site,
  };
}

bool openableLink(String url) {
  final uri = Uri.tryParse(url);
  return uri != null && uri.scheme == 'https' && uri.host.isNotEmpty;
}

List<ExternalLinkDto> shownLinks(List<ExternalLinkDto> links) {
  final seen = <String>{};
  return [
    for (final link in links)
      if (openableLink(link.url) && seen.add(link.url)) link,
  ].take(maxShownLinks).toList();
}
