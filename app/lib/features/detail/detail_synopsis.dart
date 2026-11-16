import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../core/genre_names.dart';
import '../../core/theme/kolektaku_tokens.dart';
import '../../widgets/limited_data_label.dart';
import '../../widgets/pressable.dart';
import '../../widgets/translated_text.dart';
import 'detail_info.dart';

class DetailSynopsis extends StatefulWidget {
  const DetailSynopsis({super.key, required this.info, this.onGenre});

  final DetailInfo info;
  final ValueChanged<String>? onGenre;

  @override
  State<DetailSynopsis> createState() => _DetailSynopsisState();
}

class _DetailSynopsisState extends State<DetailSynopsis> {
  bool _expanded = false;

  Widget _genre(String genre) {
    final badge = ShadBadge.outline(child: Text(genreLabel(genre)));
    final tap = widget.onGenre;
    if (tap == null) return badge;
    return Pressable(
      key: Key('genre-$genre'),
      onTap: () => tap(genre),
      label: genreLabel(genre),
      child: badge,
    );
  }

  @override
  Widget build(BuildContext context) {
    final info = widget.info;
    final theme = ShadTheme.of(context);
    final text = info.synopsis.trim();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Spacing.screenGutter),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: Spacing.md,
        children: [
          if (info.genres.isNotEmpty)
            Wrap(
              spacing: Spacing.sm,
              runSpacing: Spacing.sm,
              children: [for (final genre in info.genres) _genre(genre)],
            ),
          if (text.isNotEmpty) ...[
            TranslatedText(
              text: text,
              maxLines: _expanded ? null : 4,
              overflow: _expanded
                  ? TextOverflow.visible
                  : TextOverflow.ellipsis,
              style: theme.textTheme.p.copyWith(height: 1.5),
            ),
            Pressable(
              onTap: () => setState(() => _expanded = !_expanded),
              minSize: Sizes.touchTarget,
              label: _expanded ? 'Lebih sedikit' : 'Selengkapnya',
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  _expanded ? 'Lebih sedikit' : 'Selengkapnya',
                  style: theme.textTheme.small.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ] else
            Text('Sinopsis belum tersedia.', style: theme.textTheme.muted),
          if (info.limited) const LimitedDataLabel(),
        ],
      ),
    );
  }
}
