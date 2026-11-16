import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../core/theme/kolektaku_tokens.dart';
import '../../src/rust/dto/credits.dart';
import 'character_sides.dart';

const characterRowHeight = 80.0;

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
                child: CharacterSide(
                  character: character,
                  onTap: onCharacter == null
                      ? null
                      : () => onCharacter!(character),
                ),
              ),
              if (actor != null)
                Expanded(
                  child: VoiceSide(
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
