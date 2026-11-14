import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../core/labels.dart';
import '../../core/theme/kolektaku_text.dart';
import '../../core/theme/kolektaku_tokens.dart';
import '../../src/rust/dto/credits.dart';
import '../../widgets/poster.dart';
import '../../widgets/pressable.dart';

const characterRowHeight = 80.0;
const _photoSize = 56.0;

VoiceActorDto? preferredVoiceActor(CharacterDto character) {
  if (character.voiceActors.isEmpty) return null;
  for (final actor in character.voiceActors) {
    if (actor.language.toLowerCase() == 'japanese') return actor;
  }
  return character.voiceActors.first;
}

String languageLabel(String language) => switch (language.toLowerCase()) {
  'japanese' => 'Jepang',
  'english' => 'Inggris',
  'korean' => 'Korea',
  'indonesian' => 'Indonesia',
  _ => language,
};

class CharactersSection extends StatelessWidget {
  const CharactersSection({
    super.key,
    required this.characters,
    this.onCharacter,
    this.onVoiceActor,
  });

  final List<CharacterDto> characters;
  final ValueChanged<CharacterDto>? onCharacter;
  final ValueChanged<VoiceActorDto>? onVoiceActor;

  @override
  Widget build(BuildContext context) {
    if (characters.isEmpty) {
      return const SliverToBoxAdapter(
        child: _Empty(text: 'Data karakter belum tersedia.'),
      );
    }
    return SliverFixedExtentList(
      itemExtent: characterRowHeight,
      delegate: SliverChildBuilderDelegate(childCount: characters.length, (
        context,
        index,
      ) {
        final character = characters[index];
        final actor = preferredVoiceActor(character);
        return Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: Spacing.screenGutter,
            vertical: Spacing.xs,
          ),
          child: Row(
            spacing: Spacing.md,
            children: [
              Expanded(
                child: _CharacterSide(
                  character: character,
                  onTap: onCharacter == null
                      ? null
                      : () => onCharacter!(character),
                ),
              ),
              if (actor != null)
                Expanded(
                  child: _VoiceSide(
                    actor: actor,
                    onTap: onVoiceActor == null
                        ? null
                        : () => onVoiceActor!(actor),
                  ),
                ),
            ],
          ),
        );
      }),
    );
  }
}

class _Photo extends StatelessWidget {
  const _Photo({required this.url});

  final String? url;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _photoSize,
      child: Poster(url: url, aspectRatio: 1, radius: Radii.chip),
    );
  }
}

class _CharacterSide extends StatelessWidget {
  const _CharacterSide({required this.character, required this.onTap});

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
          _Photo(url: character.imageUrl),
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

class _VoiceSide extends StatelessWidget {
  const _VoiceSide({required this.actor, required this.onTap});

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
          _Photo(url: actor.imageUrl),
        ],
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(Spacing.xl),
      child: Text(text, style: ShadTheme.of(context).textTheme.muted),
    );
  }
}
