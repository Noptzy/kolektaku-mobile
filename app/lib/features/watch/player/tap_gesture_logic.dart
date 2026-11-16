import 'dart:async';
import 'dart:ui';

enum TapZone { back, center, forward }

const doubleTapWindow = Duration(milliseconds: 300);
const seekChainWindow = Duration(milliseconds: 800);
const holdAfter = Duration(milliseconds: 500);
const tapSlop = 18.0;

class TapGestureLogic {
  TapGestureLogic({
    required this.onSingleTap,
    required this.onCenterDouble,
    required this.onSkip,
    required this.onSkipEnd,
    required this.onHoldStart,
    required this.onHoldEnd,
  });

  final VoidCallback onSingleTap;
  final VoidCallback onCenterDouble;
  final void Function(TapZone zone, int count) onSkip;
  final VoidCallback onSkipEnd;
  final VoidCallback onHoldStart;
  final VoidCallback onHoldEnd;

  Timer? _single;
  Timer? _chain;
  Timer? _hold;
  TapZone? _pending;
  TapZone? _chained;
  TapZone _zone = TapZone.center;
  Offset _origin = Offset.zero;
  bool _down = false;
  bool _moved = false;
  bool _holding = false;
  int _count = 0;

  void down(TapZone zone, Offset position) {
    if (_down) {
      _abandon();
      return;
    }
    _down = true;
    _moved = false;
    _zone = zone;
    _origin = position;
    _hold?.cancel();
    _hold = Timer(holdAfter, _beginHold);
  }

  void move(Offset position) {
    if (!_down || _moved) return;
    if ((position - _origin).distance <= tapSlop) return;
    _moved = true;
    _hold?.cancel();
  }

  void up() {
    if (!_down) return;
    _down = false;
    _hold?.cancel();
    if (_holding) {
      _holding = false;
      onHoldEnd();
      return;
    }
    if (!_moved) _tapped(_zone);
  }

  void cancel() => _abandon();

  void dispose() {
    _single?.cancel();
    _chain?.cancel();
    _hold?.cancel();
  }

  void _abandon() {
    _hold?.cancel();
    final wasHolding = _holding;
    _down = false;
    _holding = false;
    if (wasHolding) onHoldEnd();
  }

  void _beginHold() {
    if (_moved || !_down || _chained != null) return;
    _single?.cancel();
    _pending = null;
    _holding = true;
    onHoldStart();
  }

  void _tapped(TapZone zone) {
    final chained = _chained;
    if (chained != null && zone != TapZone.center) {
      _skip(zone, continuing: zone == chained);
      return;
    }
    if (_pending == zone) {
      _single?.cancel();
      _pending = null;
      if (zone == TapZone.center) {
        onCenterDouble();
      } else {
        _skip(zone, continuing: false);
      }
      return;
    }
    _pending = zone;
    _single?.cancel();
    _single = Timer(doubleTapWindow, () {
      _pending = null;
      onSingleTap();
    });
  }

  void _skip(TapZone zone, {required bool continuing}) {
    _single?.cancel();
    _pending = null;
    _chained = zone;
    _count = continuing ? _count + 1 : 1;
    onSkip(zone, _count);
    _chain?.cancel();
    _chain = Timer(seekChainWindow, () {
      _chained = null;
      _count = 0;
      onSkipEnd();
    });
  }
}
