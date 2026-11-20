import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../features/dev/gallery/gallery_screen.dart';
import '../features/dev/gate/gate_screen.dart';
import '../features/collection/collection_screen.dart';
import '../features/detail/detail_request.dart';
import '../features/detail/detail_screen.dart';
import '../features/downloads/downloads_screen.dart';
import '../features/genre/genre_list_screen.dart';
import '../features/genre/genre_titles_screen.dart';
import '../features/home/home_screen.dart';
import '../features/profile/profile_request.dart';
import '../features/novel_reader/novel_request.dart';
import '../features/novel_reader/novel_screen.dart';
import '../features/reader/continuous_setting.dart';
import '../features/reader/read_request.dart';
import '../features/reader/reader_screen.dart';
import '../features/profile/profile_screen.dart';
import '../features/scene_search/scene_search_screen.dart';
import '../features/settings/settings_page_screen.dart';
import '../features/settings/settings_pages.dart';
import '../features/settings/settings_screen.dart';
import '../features/search/search_tab_screen.dart';
import '../features/update/update_host.dart';
import '../features/watch/watch_request.dart';
import '../features/watch/watch_route.dart';
import '../widgets/app_shell.dart';
import '../widgets/fade_branches.dart';
import 'page_transitions.dart';
import 'routes.dart';
import '../src/rust/dto/media.dart';

const startRoute = String.fromEnvironment(
  'START_ROUTE',
  defaultValue: Routes.home,
);

StatefulShellBranch _branch(String path, Widget Function() screen) {
  return StatefulShellBranch(
    routes: [GoRoute(path: path, builder: (context, state) => screen())],
  );
}

GoRoute _route(
  String path,
  Widget Function(GoRouterState state) screen, {
  PageMotion motion = PageMotion.slide,
}) {
  return GoRoute(
    path: path,
    pageBuilder: (context, state) =>
        motionPage(state: state, motion: motion, child: screen(state)),
  );
}

GoRouter createRouter({String initialLocation = startRoute}) {
  return GoRouter(
    initialLocation: initialLocation,
    routes: [
      GoRoute(path: '/', redirect: (context, state) => Routes.home),
      StatefulShellRoute(
        builder: (context, state, shell) =>
            UpdateHost(child: AppShell(shell: shell)),
        navigatorContainerBuilder: (context, shell, children) =>
            FadeBranches(index: shell.currentIndex, children: children),
        branches: [
          _branch(Routes.home, () => const HomeScreen()),
          _branch(Routes.search, () => const SearchTabScreen()),
          _branch(Routes.collection, () => const CollectionScreen()),
          _branch(Routes.settings, () => const SettingsScreen()),
        ],
      ),
      _route(Routes.gate, (state) => const GateScreen()),
      _route(Routes.gallery, (state) => const GalleryScreen()),
      _route(Routes.downloads, (state) => const DownloadsScreen()),
      _route(
        Routes.settingsPage,
        (state) => SettingsPageScreen(
          page:
              SettingsPage.fromSlug(state.pathParameters['page'] ?? '') ??
              SettingsPage.preference,
        ),
      ),
      _route(
        Routes.genres,
        (state) => GenreListScreen(kind: state.extra! as MediaKindDto),
      ),
      _route(Routes.genre, (state) {
        final args = state.extra! as GenreRouteArgs;
        return GenreTitlesScreen(kind: args.kind, genre: args.genre);
      }),
      _route(
        Routes.detail,
        (state) => DetailScreen(request: state.extra! as DetailRequest),
      ),
      _route(
        Routes.profile,
        (state) => ProfileScreen(request: state.extra! as ProfileRequest),
      ),
      _route(Routes.sceneSearch, (state) {
        final shared = state.extra as Uint8List?;
        return SceneSearchScreen(initialImage: shared);
      }),
      _route(
        Routes.read,
        (state) => WithContinuous(
          builder: (auto) => ReaderScreen(
            request: state.extra! as ReadRequest,
            autoContinue: auto,
          ),
        ),
      ),
      _route(
        Routes.novel,
        (state) => WithContinuous(
          builder: (auto) => NovelScreen(
            request: state.extra! as NovelRequest,
            autoContinue: auto,
          ),
        ),
      ),
      _route(
        Routes.watch,
        (state) => WatchRoute(request: state.extra! as WatchRequest),
        motion: PageMotion.fade,
      ),
    ],
  );
}

final kolektakuRouter = createRouter();
