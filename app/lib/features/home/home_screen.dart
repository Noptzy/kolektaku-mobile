import 'package:flutter/cupertino.dart' show CupertinoSliverRefreshControl;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/routes.dart';
import '../../data/providers/gateway_providers.dart';
import '../../data/providers/home_providers.dart';
import '../../data/providers/settings_providers.dart';
import '../../src/rust/dto/cards.dart';
import '../../src/rust/dto/library.dart';
import '../../src/rust/dto/media.dart';
import '../../src/rust/dto/sources.dart';
import '../../src/rust/error.dart';
import '../../widgets/error_state_view.dart';
import '../../widgets/refresh_on_visible.dart';
import '../../widgets/state_view.dart';
import '../detail/detail_request.dart';
import 'hero_auto_play.dart';
import 'home_actions.dart';
import 'home_mix.dart';
import 'home_skeleton.dart';
import 'mixed_home.dart';

const _kinds = MediaKindDto.values;

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  Future<void> _refresh(WidgetRef ref) async {
    await ref
        .read(catalogGatewayProvider)
        .clearCache()
        .catchError((Object _) {});
    for (final kind in _kinds) {
      ref.invalidate(homeProvider(kind));
      ref.invalidate(continueProvider(kind));
      ref.invalidate(genresProvider(kind));
    }
    try {
      await Future.wait([
        for (final kind in _kinds) ref.read(homeProvider(kind).future),
      ]);
    } on Object {
      return;
    }
  }

  void _refreshLibrary(WidgetRef ref) {
    for (final kind in _kinds) {
      ref.invalidate(continueProvider(kind));
    }
  }

  HomeActions _actions(BuildContext context, WidgetRef ref) {
    Future<void> open(MediaKindDto kind, MediaRefDto reference) async {
      await context.push(
        Routes.detail,
        extra: DetailRequest(kind: kind, reference: reference),
      );
      _refreshLibrary(ref);
    }

    return HomeActions(
      onOpen: (kind, card) => open(kind, card.reference),
      onResume: (ProgressDto progress) =>
          open(progress.kind, progress.reference),
      onGenre: (kind, GenreDto genre) =>
          context.push(Routes.genre, extra: (kind: kind, genre: genre)),
      onAllGenres: (kind) => context.push(Routes.genres, extra: kind),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefersAnime = ref.watch(currentSettingsProvider).prefersAnime;
    final anime = ref.watch(homeProvider(MediaKindDto.anime));
    final manga = ref.watch(homeProvider(MediaKindDto.manga));
    return RefreshOnVisible(
      onVisible: () => _refreshLibrary(ref),
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        slivers: [
          CupertinoSliverRefreshControl(onRefresh: () => _refresh(ref)),
          SliverToBoxAdapter(
            child: _body(context, ref, anime, manga, prefersAnime),
          ),
        ],
      ),
    );
  }

  Widget _body(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<HomeDto> anime,
    AsyncValue<HomeDto> manga,
    bool prefersAnime,
  ) {
    final waiting = anime.isLoading && manga.isLoading;
    if (waiting) return const HomeSkeleton();
    if (anime.hasError && manga.hasError) {
      return _failure(context, anime.error!, ref);
    }
    return MixedHome(
      anime: anime.value,
      manga: manga.value,
      prefersAnime: prefersAnime,
      resume: mergeResume(
        ref.watch(continueProvider(MediaKindDto.anime)).value ?? const [],
        ref.watch(continueProvider(MediaKindDto.manga)).value ?? const [],
      ),
      genres: {
        for (final kind in _kinds)
          kind: ref.watch(genresProvider(kind)).value ?? const [],
      },
      covers: {
        for (final kind in _kinds)
          kind: ref.watch(genreCoversProvider(kind)).value ?? const {},
      },
      actions: _actions(context, ref),
      heroAutoPlay: ref.watch(heroAutoPlayProvider),
    );
  }

  Widget _failure(BuildContext context, Object error, WidgetRef ref) {
    final inset = MediaQuery.paddingOf(context).top;
    void retry() {
      for (final kind in _kinds) {
        ref.invalidate(homeProvider(kind));
      }
    }

    if (error is BridgeError) {
      return SizedBox(
        height: 420 + inset,
        child: Padding(
          padding: EdgeInsets.only(top: inset),
          child: ErrorStateView(error: error, onRetry: retry),
        ),
      );
    }
    return SizedBox(
      height: 420 + inset,
      child: Padding(
        padding: EdgeInsets.only(top: inset),
        child: StateView.error(
          title: 'Ada yang tidak beres',
          message: 'Beranda belum bisa dimuat.',
          actionLabel: 'Coba lagi',
          onAction: retry,
        ),
      ),
    );
  }
}
