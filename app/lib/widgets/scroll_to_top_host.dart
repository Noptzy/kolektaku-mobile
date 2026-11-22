import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/providers/scroll_providers.dart';

const _upDuration = Duration(milliseconds: 320);

class ScrollToTopHost extends ConsumerStatefulWidget {
  const ScrollToTopHost({
    super.key,
    required this.signal,
    required this.builder,
  });

  final NotifierProvider<ScrollToTopSignal, int> signal;
  final Widget Function(BuildContext context, ScrollController controller)
  builder;

  @override
  ConsumerState<ScrollToTopHost> createState() => _ScrollToTopHostState();
}

class _ScrollToTopHostState extends ConsumerState<ScrollToTopHost> {
  final ScrollController _controller = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _up() {
    if (!_controller.hasClients || _controller.offset <= 0) return;
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.jumpTo(0);
      return;
    }
    _controller.animateTo(0, duration: _upDuration, curve: Curves.easeOutCubic);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<int>(widget.signal, (previous, next) => _up());
    return widget.builder(context, _controller);
  }
}
