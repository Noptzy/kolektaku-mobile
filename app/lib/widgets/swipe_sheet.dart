import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

const sheetDismissDistance = 96.0;
const sheetDismissVelocity = 700.0;
const _settleDuration = Duration(milliseconds: 180);
const _grabberSize = Size(40, 4);

bool shouldDismiss({required double distance, required double velocity}) =>
    distance >= sheetDismissDistance || velocity >= sheetDismissVelocity;

Future<T?> showSwipeSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
}) {
  return showShadSheet<T>(
    context: context,
    side: ShadSheetSide.bottom,
    builder: (sheetContext) => SwipeDismiss(child: builder(sheetContext)),
  );
}

class SwipeDismiss extends StatefulWidget {
  const SwipeDismiss({super.key, required this.child});

  final Widget child;

  @override
  State<SwipeDismiss> createState() => _SwipeDismissState();
}

class _SwipeDismissState extends State<SwipeDismiss>
    with SingleTickerProviderStateMixin {
  late final AnimationController _settle = AnimationController(
    vsync: this,
    duration: _settleDuration,
  );
  double _offset = 0;

  @override
  void initState() {
    super.initState();
    _settle.addStatusListener((status) {
      if (status == AnimationStatus.completed) setState(() => _offset = 0);
    });
  }

  @override
  void dispose() {
    _settle.dispose();
    super.dispose();
  }

  void _drag(DragUpdateDetails details) {
    _settle.stop();
    setState(() => _offset = (_offset + details.delta.dy).clamp(0, 4000));
  }

  void _release(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    if (shouldDismiss(distance: _offset, velocity: velocity)) {
      Navigator.of(context).maybePop();
      return;
    }
    _settle.forward(from: 0);
  }

  double get _shift => _settle.isAnimating
      ? _offset * (1 - Curves.easeOut.transform(_settle.value))
      : _offset;

  @override
  Widget build(BuildContext context) {
    final muted = ShadTheme.of(context).colorScheme.mutedForeground;
    return GestureDetector(
      key: const Key('swipe-dismiss'),
      onVerticalDragUpdate: _drag,
      onVerticalDragEnd: _release,
      child: AnimatedBuilder(
        animation: _settle,
        builder: (context, child) =>
            Transform.translate(offset: Offset(0, _shift), child: child),
        child: Stack(
          alignment: Alignment.topCenter,
          children: [
            widget.child,
            Positioned(
              top: 8,
              child: IgnorePointer(
                child: DecoratedBox(
                  key: const Key('sheet-grabber'),
                  decoration: BoxDecoration(
                    color: muted.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(_grabberSize.height),
                  ),
                  child: SizedBox.fromSize(size: _grabberSize),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
