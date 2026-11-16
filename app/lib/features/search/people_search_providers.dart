import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/providers/gateway_providers.dart';
import '../../src/rust/dto/cards.dart';
import '../../src/rust/dto/media.dart';
import '../../src/rust/dto/profile.dart';
import '../../src/rust/dto/profile_summary.dart';

typedef PeopleQuery = ({ProfileKindDto kind, String text});

const matchLimit = 3;
const mangaMatchLimit = 12;
const novelMatchLimit = 12;

List<ProfileSummaryDto> namesMatching(
  List<ProfileSummaryDto> found,
  String text,
) {
  final words = text
      .toLowerCase()
      .split(RegExp(r'\s+'))
      .where((word) => word.isNotEmpty)
      .toList();
  if (words.isEmpty) return const [];
  return [
    for (final person in found)
      if (words.every((word) => person.name.toLowerCase().contains(word)))
        person,
  ];
}

final peopleMatchesProvider = FutureProvider.autoDispose
    .family<List<ProfileSummaryDto>, PeopleQuery>((ref, query) async {
      try {
        final found = await ref
            .watch(catalogGatewayProvider)
            .searchPeople(query.kind, query.text);
        return namesMatching(found, query.text).take(matchLimit).toList();
      } on Object {
        return const [];
      }
    });

final mangaMatchesProvider = FutureProvider.autoDispose
    .family<List<MediaCardDto>, String>((ref, text) async {
      try {
        final page = await ref
            .watch(catalogGatewayProvider)
            .search(MediaKindDto.manga, text, 1);
        return page.cards.take(mangaMatchLimit).toList();
      } on Object {
        return const [];
      }
    });

final novelMatchesProvider = FutureProvider.autoDispose
    .family<List<MediaCardDto>, String>((ref, text) async {
      try {
        final page = await ref
            .watch(catalogGatewayProvider)
            .search(MediaKindDto.novel, text, 1);
        return page.cards.take(novelMatchLimit).toList();
      } on Object {
        return const [];
      }
    });
