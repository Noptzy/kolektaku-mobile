import 'dart:async';

import 'package:flutter/widgets.dart';

import 'swipe_toast_body.dart';
import 'swipe_toast_logic.dart';

const swipeToastDuration = Duration(milliseconds: 4200);
const _settle = Duration(milliseconds: 220);
const _exitReach = 24.0;
const _exitDrop = 200.0;
const _enterDrop = 0.4;

class SwipeToast extends StatefulWidget {
  const SwipeToast({
    super.key,
    required this.message,
    required this.actionLabel,
    required this.onAction,
    required this.onClosed,
    this.duration = swipeToastDuration,
  });

  final String message;
  final String actionLabel;
  final VoidCallback onAction;
  final VoidCallback onClosed;
  final Duration duration;

  @override
  State<SwipeToast> createState() => _SwipeToastState();
}

class _SwipeToastState extends State<SwipeToast> {
  Timer? _timer;
  Offset _start = Offset.zero;
  Offset _offset = Offset.zero;
  SwipeAxis? _axis;
  bool _dragging = false;
  bool _closing = false;
  bool _entered = false;
  bool _reported = false;

  @override
  void initState() {
    super.initState();
    _arm();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _entered = true);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _arm() {
    _timer?.cancel();
    _timer = Timer(widget.duration, _close);
  }

  void _close() {
    if (_closing) return;
    _timer?.cancel();
    final width = context.size?.width ?? 0;
    setState(() {
      _closing = true;
      _dragging = false;
      _offset = switch (_axis) {
        SwipeAxis.horizontal => Offset(
          (_offset.dx < 0 ? -1 : 1) * (width + _exitReach),
          0,
        ),
        _ => const Offset(0, _exitDrop),
      };
    });
    if (MediaQuery.disableAnimationsOf(context)) _report();
  }

  void _report() {
    if (_reported) return;
    _reported = true;
    widget.onClosed();
  }

  void _down(DragDownDetails details) {
    _timer?.cancel();
    _start = details.globalPosition;
    _axis = null;
  }

  void _update(DragUpdateDetails details) {
    final delta = details.globalPosition - _start;
    final axis = _axis ??= swipeAxisOf(delta);
    if (axis == null) return;
    setState(() {
      _dragging = true;
      _offset = swipeOffset(axis, delta);
    });
  }

  void _end(DragEndDetails details) {
    final axis = _axis;
    if (axis == null) {
      _arm();
      return;
    }
    final velocity = details.velocity.pixelsPerSecond;
    final along = axis == SwipeAxis.horizontal
        ? velocity.dx.abs()
        : velocity.dy;
    final close = swipeShouldClose(
      distance: swipeDistance(axis, _offset),
      speed: along.clamp(0, double.infinity) / 1000,
    );
    if (close) {
      _close();
      return;
    }
    setState(() {
      _dragging = false;
      _offset = Offset.zero;
    });
    _arm();
  }

  @override
  Widget build(BuildContext context) {
    final animate = !MediaQuery.disableAnimationsOf(context);
    final shown = _entered && !_closing;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onPanDown: _down,
      onPanUpdate: _update,
      onPanEnd: _end,
      onPanCancel: _arm,
      child: AnimatedSlide(
        offset: _entered ? Offset.zero : const Offset(0, _enterDrop),
        duration: animate ? _settle : Duration.zero,
        curve: Curves.easeOutCubic,
        child: AnimatedContainer(
          duration: _dragging || !animate ? Duration.zero : _settle,
          curve: Curves.easeOutCubic,
          transform: Matrix4.translationValues(_offset.dx, _offset.dy, 0),
          onEnd: () {
            if (_closing) _report();
          },
          child: AnimatedOpacity(
            opacity: shown ? swipeFade(_offset) : 0,
            duration: _dragging || !animate ? Duration.zero : _settle,
            child: SwipeToastBody(
              message: widget.message,
              actionLabel: widget.actionLabel,
              onAction: widget.onAction,
            ),
          ),
        ),
      ),
    );
  }
}
