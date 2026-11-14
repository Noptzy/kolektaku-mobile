import 'package:flutter_test/flutter_test.dart';
import 'package:kolektaku/features/detail/characters_section.dart';
import 'package:kolektaku/src/rust/dto/credits.dart';

CharacterDto character(List<VoiceActorDto> actors) =>
    CharacterDto(id: BigInt.one, name: 'X', role: 'MAIN', voiceActors: actors);

VoiceActorDto actor(int id, String language) =>
    VoiceActorDto(id: BigInt.from(id), name: 'A$id', language: language);

void main() {
  group('preferredVoiceActor', () {
    test('the Japanese voice wins whatever the order', () {
      final picked = preferredVoiceActor(
        character([actor(1, 'English'), actor(2, 'Japanese')]),
      );
      expect(picked?.id, BigInt.two);
    });

    test('the language is not case sensitive', () {
      final picked = preferredVoiceActor(
        character([actor(1, 'English'), actor(2, 'JAPANESE')]),
      );
      expect(picked?.id, BigInt.two);
    });

    test('without Japanese the first voice is used', () {
      final picked = preferredVoiceActor(
        character([actor(3, 'Korean'), actor(4, 'English')]),
      );
      expect(picked?.id, BigInt.from(3));
    });

    test('no voices means no actor', () {
      expect(preferredVoiceActor(character(const [])), isNull);
    });
  });

  group('languageLabel', () {
    test('known languages are in Indonesian and others stay', () {
      expect(languageLabel('Japanese'), 'Jepang');
      expect(languageLabel('english'), 'Inggris');
      expect(languageLabel('Korean'), 'Korea');
      expect(languageLabel('Indonesian'), 'Indonesia');
      expect(languageLabel('Hungarian'), 'Hungarian');
    });
  });
}
