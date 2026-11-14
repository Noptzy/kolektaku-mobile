import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../core/routes.dart';
import '../../core/theme/kolektaku_text.dart';
import '../../core/theme/kolektaku_tokens.dart';
import '../../src/rust/dto/media.dart';
import '../../src/rust/dto/profile.dart';
import '../../src/rust/dto/profile_summary.dart';
import '../../widgets/media_rail.dart';
import '../detail/detail_request.dart';
import '../profile/profile_request.dart';
import 'people_search_providers.dart';
import 'person_row.dart';

const matchMinQuery = 3;

class SearchMatches extends ConsumerWidget {
  const SearchMatches({super.key, required this.query});

  final String query;

  List<ProfileSummaryDto> _people(
    WidgetRef ref,
    ProfileKindDto kind,
    String text,
  ) {
    final asked = ref.watch(peopleMatchesProvider((kind: kind, text: text)));
    return asked.value ?? const [];
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = query.trim();
    if (text.length < matchMinQuery) return const SizedBox.shrink();
    final studios = _people(ref, ProfileKindDto.studio, text);
    final characters = _people(ref, ProfileKindDto.character, text);
    final staff = _people(ref, ProfileKindDto.staff, text);
    final manga = ref.watch(mangaMatchesProvider(text)).value ?? const [];
    final found =
        studios.isNotEmpty ||
        characters.isNotEmpty ||
        staff.isNotEmpty ||
        manga.isNotEmpty;
    if (!found) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _People(title: 'Studio', people: studios),
        _People(title: 'Karakter', people: characters),
        _People(title: 'Staf', people: staff),
        if (manga.isNotEmpty)
          MediaRail(
            key: const Key('manga-matches'),
            title: 'Manga',
            cards: manga,
            unitLabel: 'ch',
            onTap: (card) => context.push(
              Routes.detail,
              extra: DetailRequest(
                kind: MediaKindDto.manga,
                reference: card.reference,
              ),
            ),
          ),
        const _Heading('Anime'),
      ],
    );
  }
}

class _People extends StatelessWidget {
  const _People({required this.title, required this.people});

  final String title;
  final List<ProfileSummaryDto> people;

  @override
  Widget build(BuildContext context) {
    if (people.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Heading(title),
        for (final person in people)
          PersonRow(
            key: ValueKey('${person.kind.name}-${person.id}'),
            person: person,
            onTap: () => context.push(
              Routes.profile,
              extra: ProfileRequest.summary(person),
            ),
          ),
      ],
    );
  }
}

class _Heading extends StatelessWidget {
  const _Heading(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Spacing.screenGutter,
        Spacing.sm,
        Spacing.screenGutter,
        Spacing.xs,
      ),
      child: Text(text, style: ShadTheme.of(context).textTheme.sectionTitle),
    );
  }
}
