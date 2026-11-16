import 'package:flutter/widgets.dart';

import 'hold_badge.dart';
import 'skip_feedback.dart';
import 'tap_gesture_logic.dart';

const _backShare = 0.35;
const _forwardShare = 0.65;

class DoubleTapZones extends StatefulWidget {
  const DoubleTapZones({
    super.key,
    required this.onSkip,
    required this.onTap,
    required this.onTogglePlay,
    required this.onHold,
    required this.step,
  });

  final ValueChanged<Duration> onSkip;
  final VoidCallback onTap;
  final VoidCallback onTogglePlay;
  final ValueChanged<bool> onHold;
  final Duration step;

  @override
  State<DoubleTapZones> createState() => _DoubleTapZonesState();
}

class _DoubleTapZonesState extends State<DoubleTapZones> {
  late final TapGestureLogic _logic;
  final ValueNotifier<SkipBurst?> _burst = ValueNotifier(null);
  bool _holding = false;

  @override
  void initState() {
    super.initState();
    _logic = TapGestureLogic(
      onSingleTap: () => widget.onTap(),
      onCenterDouble: () => widget.onTogglePlay(),
      onSkip: _skipped,
      onSkipEnd: () => _burst.value = null,
      onHoldStart: () => _hold(true),
      onHoldEnd: () => _hold(false),
    );
  }

  @override
  void dispose() {
    _logic.dispose();
    _burst.dispose();
    super.dispose();
  }

  void _skipped(TapZone zone, int count) {
    final direction = zone == TapZone.back ? -1 : 1;
    widget.onSkip(widget.step * direction);
    _burst.value = SkipBurst(
      zone: zone,
      seconds: widget.step.inSeconds * count,
    );
  }

  void _hold(bool value) {
    if (!mounted) return;
    setState(() => _holding = value);
    widget.onHold(value);
  }

  TapZone _zoneAt(double dx, double width) {
    if (width <= 0) return TapZone.center;
    final share = dx / width;
    if (share < _backShare) return TapZone.back;
    if (share > _forwardShare) return TapZone.forward;
    return TapZone.center;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) => Listener(
        behavior: HitTestBehavior.opaque,
        onPointerDown: (event) => _logic.down(
          _zoneAt(event.localPosition.dx, box.maxWidth),
          event.localPosition,
        ),
        onPointerMove: (event) => _logic.move(event.localPosition),
        onPointerUp: (event) => _logic.up(),
        onPointerCancel: (event) => _logic.cancel(),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Row(
              children: [
                Expanded(
                  flex: 35,
                  child: SkipFeedback(
                    key: const Key('zone-back'),
                    zone: TapZone.back,
                    burst: _burst,
                  ),
                ),
                const Spacer(flex: 30),
                Expanded(
                  flex: 35,
                  child: SkipFeedback(
                    key: const Key('zone-forward'),
                    zone: TapZone.forward,
                    burst: _burst,
                  ),
                ),
              ],
            ),
            HoldBadge(shown: _holding),
          ],
        ),
      ),
    );
  }
}
