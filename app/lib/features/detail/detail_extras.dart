import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../core/theme/kolektaku_tokens.dart';
import '../../platform/url_opener.dart';
import '../../src/rust/dto/media.dart';
import '../../src/rust/dto/sources.dart';
import 'detail_actions.dart';
import 'detail_info.dart';
import 'link_style.dart';
import 'related_section.dart';

class DetailExtras extends StatelessWidget {
  const DetailExtras({
    super.key,
    required this.view,
    required this.info,
    required this.kind,
    required this.actions,
  });

  final DetailViewDto view;
  final DetailInfo info;
  final MediaKindDto kind;
  final DetailActions actions;

  @override
  Widget build(BuildContext context) {
    final trailer = info.trailer;
    final canTrailer =
        trailer != null && trailerUrl(trailer.site, trailer.videoId) != null;
    final anime = kind == MediaKindDto.anime;
    final other = anime ? MediaKindDto.manga : MediaKindDto.anime;
    final relation = view.catalog == null
        ? null
        : adaptationOf(view.catalog!.detail.relations, other);
    final links = shownLinks(info.links);
    if (!canTrailer && relation == null && links.isEmpty) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Spacing.screenGutter,
        Spacing.md,
        Spacing.screenGutter,
        0,
      ),
      child: Wrap(
        spacing: Spacing.sm,
        runSpacing: Spacing.sm,
        children: [
          if (canTrailer)
            ShadButton.outline(
              onPressed: () => actions.openTrailer(trailer),
              leading: const Icon(LucideIcons.circlePlay, size: 16),
              child: const Text('Trailer'),
            ),
          for (final link in links)
            ShadButton.outline(
              key: Key('link-${link.url}'),
              onPressed: () => actions.openLink(link.url),
              leading: Icon(linkIcon(link.site), size: 16),
              child: Flexible(
                child: Text(
                  linkLabel(link.site),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          if (relation != null)
            ShadButton.outline(
              onPressed: () => actions.openSummary(relation),
              leading: Icon(
                anime ? LucideIcons.bookOpen : LucideIcons.tv,
                size: 16,
              ),
              child: Text(anime ? 'Baca komiknya' : 'Tonton animenya'),
            ),
        ],
      ),
    );
  }
}
