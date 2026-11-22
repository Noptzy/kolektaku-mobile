import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/glass_tokens.dart';
import '../core/theme/kolektaku_tokens.dart';
import '../data/providers/download_providers.dart';
import '../data/providers/toast_providers.dart';
import '../features/downloads/download_fab.dart';
import '../features/downloads/download_logic.dart';
import 'swipe_toast.dart';

class SwipeToastHost extends ConsumerStatefulWidget {
  const SwipeToastHost({super.key, required this.child, this.dismissOn});

  final Widget child;
  final Listenable? dismissOn;

  @override
  ConsumerState<SwipeToastHost> createState() => _SwipeToastHostState();
}

class _SwipeToastHostState extends ConsumerState<SwipeToastHost> {
  @override
  void initState() {
    super.initState();
    widget.dismissOn?.addListener(_onNavigated);
  }

  @override
  void didUpdateWidget(SwipeToastHost oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.dismissOn == widget.dismissOn) return;
    oldWidget.dismissOn?.removeListener(_onNavigated);
    widget.dismissOn?.addListener(_onNavigated);
  }

  @override
  void dispose() {
    widget.dismissOn?.removeListener(_onNavigated);
    super.dispose();
  }

  void _onNavigated() {
    final current = ref.read(swipeToastProvider);
    if (current == null) return;
    Future.microtask(() {
      if (mounted) ref.read(swipeToastProvider.notifier).dismiss(current.id);
    });
  }

  double _bottom(bool fabVisible) {
    final systemBottom = MediaQuery.paddingOf(context).bottom;
    final aboveDock =
        DockMetrics.bottomOffset(systemBottom) +
        DockMetrics.height +
        Spacing.md;
    return fabVisible ? aboveDock + downloadFabSize + Spacing.sm : aboveDock;
  }

  @override
  Widget build(BuildContext context) {
    final toast = ref.watch(swipeToastProvider);
    final fabVisible = activeOf(ref.watch(downloadsProvider)).isNotEmpty;
    final controller = ref.read(swipeToastProvider.notifier);
    return Stack(
      children: [
        widget.child,
        if (toast != null)
          Positioned(
            left: Spacing.screenGutter,
            right: Spacing.screenGutter,
            bottom: _bottom(fabVisible),
            child: SwipeToast(
              key: ValueKey(toast.id),
              message: toast.message,
              actionLabel: toast.actionLabel,
              onAction: () {
                controller.dismiss(toast.id);
                toast.onAction();
              },
              onClosed: () => controller.dismiss(toast.id),
            ),
          ),
      ],
    );
  }
}
