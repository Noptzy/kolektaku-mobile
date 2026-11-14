import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../core/theme/kolektaku_text.dart';
import '../../core/theme/kolektaku_tokens.dart';
import '../../src/rust/dto/profile_summary.dart';
import '../../widgets/poster.dart';
import '../../widgets/pressable.dart';
import '../profile/profile_logic.dart';

const personAvatarSize = 56.0;

class PersonRow extends StatelessWidget {
  const PersonRow({super.key, required this.person, required this.onTap});

  final ProfileSummaryDto person;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final subtitle = personSubtitle(person);
    return Pressable(
      onTap: onTap,
      label: person.name,
      minSize: Sizes.touchTarget,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: Spacing.screenGutter,
          vertical: Spacing.sm,
        ),
        child: Row(
          spacing: Spacing.md,
          children: [
            SizedBox(
              width: personAvatarSize,
              child: Poster(
                url: person.imageUrl,
                aspectRatio: 1,
                radius: personAvatarSize / 2,
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 2,
                children: [
                  Text(
                    person.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.cardTitle,
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.cardMeta.copyWith(
                        color: theme.colorScheme.mutedForeground,
                      ),
                    ),
                ],
              ),
            ),
            Icon(
              LucideIcons.chevronRight,
              size: 18,
              color: theme.colorScheme.mutedForeground,
            ),
          ],
        ),
      ),
    );
  }
}
