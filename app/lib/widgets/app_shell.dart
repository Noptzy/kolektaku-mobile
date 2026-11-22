import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../core/theme/glass_tokens.dart';
import '../core/theme/kolektaku_tokens.dart';
import '../data/providers/scroll_providers.dart';
import '../features/downloads/download_fab.dart';
import 'dock_inset.dart';
import 'floating_dock.dart';
import 'glass_budget.dart';

const appDestinations = [
  BottomDestination(label: 'Beranda', icon: LucideIcons.house),
  BottomDestination(label: 'Cari', icon: LucideIcons.search),
  BottomDestination(label: 'Koleksi', icon: LucideIcons.bookmark),
  BottomDestination(
    label: 'Pengaturan',
    icon: LucideIcons.settings,
    spin: true,
  ),
];

class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.shell});

  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context) {
    final scheme = ShadTheme.of(context).colorScheme;
    final systemBottom = MediaQuery.paddingOf(context).bottom;
    final clearance = DockMetrics.clearance(systemBottom);
    return PopScope(
      canPop: shell.currentIndex == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) shell.goBranch(0);
      },
      child: GlassBudgetHost(
        child: ColoredBox(
          color: scheme.background,
          child: Stack(
            children: [
              Positioned.fill(
                child: SafeArea(
                  top: shell.currentIndex != 0,
                  bottom: false,
                  child: DockInset(clearance: clearance, child: shell),
                ),
              ),
              Positioned(
                right: Spacing.screenGutter,
                bottom: clearance - DockMetrics.contentGap + Spacing.md,
                child: const DownloadFab(),
              ),
              Positioned(
                left: DockMetrics.sideInset,
                right: DockMetrics.sideInset,
                bottom: DockMetrics.bottomOffset(systemBottom),
                child: FloatingDock(
                  destinations: appDestinations,
                  currentIndex: shell.currentIndex,
                  onSelected: (index) {
                    final again = index == shell.currentIndex;
                    if (again && index == 0) {
                      ProviderScope.containerOf(context)
                          .read(homeScrollToTopProvider.notifier)
                          .request();
                    }
                    shell.goBranch(index, initialLocation: again);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
