import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import 'app_bottom_bar.dart';

const appDestinations = [
  BottomDestination(label: 'Beranda', icon: LucideIcons.house),
  BottomDestination(label: 'Cari', icon: LucideIcons.search),
  BottomDestination(label: 'Koleksi', icon: LucideIcons.bookmark),
  BottomDestination(label: 'Pengaturan', icon: LucideIcons.settings),
];

class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.shell});

  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context) {
    final scheme = ShadTheme.of(context).colorScheme;
    return PopScope(
      canPop: shell.currentIndex == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) shell.goBranch(0);
      },
      child: ColoredBox(
        color: scheme.background,
        child: Column(
          children: [
            Expanded(
              child: SafeArea(
                top: shell.currentIndex != 0,
                bottom: false,
                child: shell,
              ),
            ),
            AppBottomBar(
              destinations: appDestinations,
              currentIndex: shell.currentIndex,
              onSelected: (index) => shell.goBranch(
                index,
                initialLocation: index == shell.currentIndex,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
