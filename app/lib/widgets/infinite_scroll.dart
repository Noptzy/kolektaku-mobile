import 'package:flutter/widgets.dart';

const infiniteThreshold = 600.0;

typedef InfiniteBuilder = Widget Function(
  BuildContext context,
  ScrollController controller,
);

class InfiniteScroll extends StatefulWidget {
  const InfiniteScroll({
    super.key,
    required this.enabled,
    required this.onMore,
    required this.builder,
    this.threshold = infiniteThreshold,
  });

  final bool enabled;
  final VoidCallback onMore;
  final InfiniteBuilder builder;
  final double threshold;

  @override
  State<InfiniteScroll> createState() => _InfiniteScrollState();
}

class _InfiniteScrollState extends State<InfiniteScroll> {
  final ScrollController _controller = ScrollController();

  @override
  void initState() {
    super.initState();
    _controller.addListener(_check);
    _checkAfterFrame();
  }

  @override
  void didUpdateWidget(InfiniteScroll old) {
    super.didUpdateWidget(old);
    _checkAfterFrame();
  }

  void _checkAfterFrame() {
    WidgetsBinding.instance.addPostFrameCallback((_) => _check());
  }

  void _check() {
    if (!mounted || !widget.enabled || !_controller.hasClients) return;
    final position = _controller.position;
    if (!position.hasContentDimensions) return;
    if (position.extentAfter < widget.threshold) widget.onMore();
  }

  @override
  void dispose() {
    _controller.removeListener(_check);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _controller);
}
