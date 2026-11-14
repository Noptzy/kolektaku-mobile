import '../../src/rust/dto/credits.dart';
import '../../src/rust/dto/profile.dart';
import '../../src/rust/dto/profile_summary.dart';

class ProfileRequest {
  const ProfileRequest({
    required this.kind,
    required this.id,
    required this.name,
    this.imageUrl,
  });

  factory ProfileRequest.character(CharacterDto character) {
    return ProfileRequest(
      kind: ProfileKindDto.character,
      id: character.id,
      name: character.name,
      imageUrl: character.imageUrl,
    );
  }

  factory ProfileRequest.voiceActor(VoiceActorDto actor) {
    return ProfileRequest(
      kind: ProfileKindDto.staff,
      id: actor.id,
      name: actor.name,
      imageUrl: actor.imageUrl,
    );
  }

  factory ProfileRequest.summary(ProfileSummaryDto summary) {
    return ProfileRequest(
      kind: summary.kind,
      id: summary.id,
      name: summary.name,
      imageUrl: summary.imageUrl,
    );
  }

  final ProfileKindDto kind;
  final BigInt id;
  final String name;
  final String? imageUrl;

  @override
  bool operator ==(Object other) =>
      other is ProfileRequest && other.kind == kind && other.id == id;

  @override
  int get hashCode => Object.hash(kind, id);
}
