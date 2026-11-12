import 'package:go_router/go_router.dart';

import '../features/dev/theme_preview_screen.dart';

final kolektakuRouter = GoRouter(
  routes: [
    GoRoute(path: '/', builder: (context, state) => const ThemePreviewScreen()),
  ],
);
