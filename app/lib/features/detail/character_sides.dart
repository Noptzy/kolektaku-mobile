import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../core/labels.dart';
import '../../core/theme/kolektaku_text.dart';
import '../../core/theme/kolektaku_tokens.dart';
import '../../src/rust/dto/credits.dart';
import '../../widgets/poster.dart';
import '../../widgets/pressable.dart';
import 'characters_section.dart' show languageLabel;

const _photoSize = 56.0;

class CharacterPhoto extends StatelessWidget {
  const CharacterPhoto({super.key, required this.url});

  final String? url;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _photoSize,
      child: Poster(url: url, aspectRatio: 1, radius: Radii.chip),
    );
  }
}

class CharacterSide extends StatelessWidget {
  const CharacterSide({
    super.key,
    required this.character,
    required this.onTap,
  });

  final CharacterDto character;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return Pressable(
      key: Key('character-${character.id}'),
      onTap: onTap,
      label: character.name,
      minSize: Sizes.touchTarget,
      child: Row(
        spacing: Spacing.md,
        children: [
          CharacterPhoto(url: character.imageUrl),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  character.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.cardTitle,
                ),
                Text(
                  roleLabel(character.role),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.cardMeta.copyWith(
                    color: theme.colorScheme.mutedForeground,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class VoiceSide extends StatelessWidget {
  const VoiceSide({super.key, required this.actor, required this.onTap});

  final VoiceActorDto actor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return Pressable(
      key: Key('voice-${actor.id}'),
      onTap: onTap,
      label: 'Pengisi suara ${actor.name}',
      minSize: Sizes.touchTarget,
      child: Row(
        spacing: Spacing.md,
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  actor.name,
                  maxLines: 2,
                  textAlign: TextAlign.end,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.cardTitle,
                ),
                Text(
                  languageLabel(actor.language),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.cardMeta.copyWith(
                    color: theme.colorScheme.mutedForeground,
                  ),
                ),
              ],
            ),
          ),
          CharacterPhoto(url: actor.imageUrl),
        ],
      ),
    );
  }
}
