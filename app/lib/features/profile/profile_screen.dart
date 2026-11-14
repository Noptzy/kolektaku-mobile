import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../core/routes.dart';
import '../../core/theme/kolektaku_text.dart';
import '../../core/theme/kolektaku_tokens.dart';
import '../../src/rust/dto/profile.dart';
import '../../src/rust/error.dart';
import '../../widgets/error_state_view.dart';
import '../../src/rust/dto/cards.dart';
import '../../widgets/media_grid.dart';
import '../../widgets/screen_header.dart';
import '../../widgets/skeleton.dart';
import '../../widgets/state_view.dart';
import '../detail/detail_request.dart';
import '../../platform/url_opener.dart';
import 'profile_details.dart';
import 'profile_header.dart';
import 'profile_logic.dart';
import 'profile_providers.dart';
import 'profile_request.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key, required this.request});

  final ProfileRequest request;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider(request));
    final data = profile.value;
    final scheme = ShadTheme.of(context).colorScheme;
    return ColoredBox(
      color: scheme.background,
      child: SafeArea(
        child: Column(
          children: [
            ScreenHeader(title: profileTitle(request.kind)),
            Expanded(
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: ProfileHeader(
                      name: data?.name ?? request.name,
                      nativeName: data?.nativeName,
                      imageUrl: data?.imageUrl ?? request.imageUrl,
                    ),
                  ),
                  ...profile.when(
                    loading: () => [const _Loading()],
                    error: (error, stack) => [
                      _Failure(
                        error: error,
                        onRetry: () => ref.invalidate(profileProvider(request)),
                      ),
                    ],
                    data: (loaded) => _content(context, ref, loaded),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: Spacing.xl)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _groupGrid(BuildContext context, List<AppearanceDto> items) {
    final cards = [for (final item in items) appearanceCard(item)];
    AppearanceDto itemOf(MediaCardDto card) => items[cards.indexOf(card)];
    return MediaGridSliver(
      cards: cards,
      tagOf: (card) => appearanceTag(itemOf(card)),
      onTap: (card) => context.push(
        Routes.detail,
        extra: DetailRequest.catalog(itemOf(card).media),
      ),
    );
  }

  List<Widget> _content(BuildContext context, WidgetRef ref, ProfileDto data) {
    final groups = groupByYear(data.appearances);
    return [
      SliverToBoxAdapter(
        child: ProfileDetails(
          facts: data.facts,
          links: data.links,
          onOpenLink: (url) => ref.read(urlOpenerProvider).open(url),
        ),
      ),
      SliverToBoxAdapter(child: ProfileDescription(markup: data.description)),
      if (groups.isEmpty)
        const SliverToBoxAdapter(
          child: StateView.empty(title: 'Belum ada judul untuk ditampilkan'),
        )
      else
        for (final group in groups) ...[
          _Heading(text: yearHeading(group.year)),
          _groupGrid(context, group.items),
        ],
    ];
  }
}

class _Heading extends StatelessWidget {
  const _Heading({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          Spacing.screenGutter,
          Spacing.lg,
          Spacing.screenGutter,
          Spacing.sm,
        ),
        child: Text(text, style: theme.textTheme.sectionTitle),
      ),
    );
  }
}

class _Loading extends StatelessWidget {
  const _Loading();

  @override
  Widget build(BuildContext context) {
    return SliverList.list(
      children: [
        for (var i = 0; i < 4; i++)
          const Padding(
            padding: EdgeInsets.symmetric(
              horizontal: Spacing.screenGutter,
              vertical: Spacing.xs,
            ),
            child: Skeleton(height: 84, radius: Radii.card),
          ),
      ],
    );
  }
}

class _Failure extends StatelessWidget {
  const _Failure({required this.error, required this.onRetry});

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final failure = error;
    return SliverToBoxAdapter(
      child: SizedBox(
        height: 360,
        child: failure is BridgeError
            ? ErrorStateView(error: failure, onRetry: onRetry)
            : StateView.error(
                title: 'Ada yang tidak beres',
                message: 'Profil belum bisa dimuat.',
                actionLabel: 'Coba lagi',
                onAction: onRetry,
              ),
      ),
    );
  }
}
