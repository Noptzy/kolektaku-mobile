import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import 'poster_wall_columns.dart';
import 'welcome_providers.dart';

class PosterWall extends ConsumerWidget {
  const PosterWall({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final covers = ref.watch(welcomeCoversProvider).value ?? const <String>[];
    final background = ShadTheme.of(context).colorScheme.background;
    return ExcludeSemantics(
      child: IgnorePointer(
        child: Stack(
          fit: StackFit.expand,
          children: [
            WallColumns(covers: covers),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    background.withValues(alpha: 0.6),
                    background.withValues(alpha: 0.78),
                    background.withValues(alpha: 0.97),
                  ],
                  stops: const [0, 0.45, 0.78],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
