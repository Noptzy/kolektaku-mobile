import 'package:flutter/widgets.dart';

import '../core/theme/kolektaku_tokens.dart';

const skeletonBase = Color(0xFF272731);
const skeletonGlow = Color(0xFF3A3A47);

class Skeleton extends StatefulWidget {
  const Skeleton({
    super.key,
    this.width,
    this.height,
    this.radius = Radii.poster,
    this.animate = true,
  });

  final double? width;
  final double? height;
  final double radius;
  final bool animate;

  @override
  State<Skeleton> createState() => _SkeletonState();
}

class _SkeletonState extends State<Skeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final still = !widget.animate || MediaQuery.disableAnimationsOf(context);
    if (still) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        final width =
            widget.width ?? (box.hasBoundedWidth ? box.maxWidth : null);
        return AnimatedBuilder(
          animation: _controller,
          builder: (context, child) => DecoratedBox(
            decoration: BoxDecoration(
              color: Color.lerp(skeletonBase, skeletonGlow, _controller.value),
              borderRadius: BorderRadius.circular(widget.radius),
            ),
            child: SizedBox(width: width, height: widget.height),
          ),
        );
      },
    );
  }
}
