import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../core/routes.dart';
import '../../core/theme/kolektaku_tokens.dart';
import 'poster_wall.dart';
import 'welcome_copy.dart';
import 'welcome_dots.dart';
import 'welcome_gate.dart';
import 'welcome_parts.dart';
import 'welcome_providers.dart';

class WelcomeScreen extends ConsumerStatefulWidget {
  const WelcomeScreen({super.key, this.gate});

  final WelcomeGate? gate;

  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends ConsumerState<WelcomeScreen> {
  final PageController _pager = PageController();
  int _index = 0;

  bool get _last => _index == welcomePages.length - 1;

  @override
  void dispose() {
    _pager.dispose();
    super.dispose();
  }

  void _next() {
    if (_last) {
      _finish();
      return;
    }
    if (MediaQuery.disableAnimationsOf(context)) {
      _pager.jumpToPage(_index + 1);
      return;
    }
    _pager.nextPage(
      duration: Motion.regular,
      curve: const Cubic(0.23, 1, 0.32, 1),
    );
  }

  void _finish() {
    ref.read(welcomeStoreProvider).markSeen();
    (widget.gate ?? welcomeGate).complete();
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(Routes.home);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = ShadTheme.of(context).colorScheme;
    return ColoredBox(
      color: scheme.background,
      child: Stack(
        fit: StackFit.expand,
        children: [
          const PosterWall(),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                Spacing.screenGutter,
                Spacing.sm,
                Spacing.screenGutter,
                Spacing.lg,
              ),
              child: Column(
                children: [
                  WelcomeTopBar(visibleSkip: !_last, onSkip: _finish),
                  Expanded(
                    child: PageView(
                      controller: _pager,
                      onPageChanged: (index) => setState(() => _index = index),
                      children: [
                        for (final page in welcomePages)
                          WelcomePageText(page: page),
                      ],
                    ),
                  ),
                  WelcomeDots(count: welcomePages.length, index: _index),
                  const SizedBox(height: Spacing.lg),
                  SizedBox(
                    width: double.infinity,
                    child: ShadButton(
                      key: const Key('welcome-next'),
                      height: Sizes.touchTarget + 4,
                      onPressed: _next,
                      child: Text(_last ? welcomeStartLabel : welcomeNextLabel),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
