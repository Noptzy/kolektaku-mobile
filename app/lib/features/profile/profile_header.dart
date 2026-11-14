import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../core/plain_text.dart';
import '../../core/theme/kolektaku_text.dart';
import '../../core/theme/kolektaku_tokens.dart';
import '../../widgets/poster.dart';
import '../../widgets/pressable.dart';

class ProfileHeader extends StatelessWidget {
  const ProfileHeader({
    super.key,
    required this.name,
    this.nativeName,
    this.imageUrl,
  });

  final String name;
  final String? nativeName;
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.screenGutter,
        vertical: Spacing.md,
      ),
      child: Row(
        spacing: Spacing.lg,
        children: [
          SizedBox(
            width: 112,
            child: Poster(url: imageUrl, radius: Radii.card),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: Spacing.xs,
              children: [
                Text(name, style: theme.textTheme.sectionTitle),
                if (nativeName != null)
                  Text(nativeName!, style: theme.textTheme.muted),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ProfileDescription extends StatefulWidget {
  const ProfileDescription({super.key, required this.markup});

  final String markup;

  @override
  State<ProfileDescription> createState() => _ProfileDescriptionState();
}

class _ProfileDescriptionState extends State<ProfileDescription> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final text = plainText(widget.markup);
    if (text.isEmpty) return const SizedBox.shrink();
    final theme = ShadTheme.of(context);
    final label = _expanded ? 'Lebih sedikit' : 'Selengkapnya';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Spacing.screenGutter),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: Spacing.sm,
        children: [
          Text(
            text,
            maxLines: _expanded ? null : 5,
            overflow: _expanded ? TextOverflow.visible : TextOverflow.ellipsis,
            style: theme.textTheme.p.copyWith(height: 1.5),
          ),
          Pressable(
            onTap: () => setState(() => _expanded = !_expanded),
            minSize: Sizes.touchTarget,
            label: label,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                label,
                style: theme.textTheme.small.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
