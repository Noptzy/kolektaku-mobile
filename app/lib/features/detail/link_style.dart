import 'package:flutter/widgets.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../src/rust/dto/links.dart';

const maxShownLinks = 6;

FaIconData? brandIconFor(String site) {
  return switch (site.toLowerCase().trim()) {
    'twitter' || 'x' => FontAwesomeIcons.xTwitter,
    'youtube' => FontAwesomeIcons.youtube,
    'instagram' => FontAwesomeIcons.instagram,
    'facebook' => FontAwesomeIcons.facebookF,
    'tiktok' => FontAwesomeIcons.tiktok,
    _ => null,
  };
}

Widget siteIcon(String site, {required double size, required Color color}) {
  final brand = brandIconFor(site);
  if (brand != null) {
    return FaIcon(brand, size: size, color: color);
  }
  final icon = site.toLowerCase().trim() == 'official site'
      ? LucideIcons.globe
      : LucideIcons.link;
  return Icon(icon, size: size, color: color);
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
