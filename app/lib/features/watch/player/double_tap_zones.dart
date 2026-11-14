import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

class DoubleTapZones extends StatefulWidget {
  const DoubleTapZones({
    super.key,
    required this.onSkip,
    required this.onTap,
    required this.step,
  });

  final ValueChanged<Duration> onSkip;
  final VoidCallback onTap;
  final Duration step;

  @override
  State<DoubleTapZones> createState() => _DoubleTapZonesState();
}

class _DoubleTapZonesState extends State<DoubleTapZones> {
  int _direction = 0;

  void _skip(int direction) {
    widget.onSkip(widget.step * direction);
    setState(() => _direction = direction);
    Future<void>.delayed(const Duration(milliseconds: 600), () {
      if (mounted) setState(() => _direction = 0);
    });
  }

  Widget _zone(int direction, String label) {
    final shown = _direction == direction;
    return Expanded(
      child: GestureDetector(
        key: Key(direction < 0 ? 'zone-back' : 'zone-forward'),
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        onDoubleTap: () => _skip(direction),
        child: Center(
          child: AnimatedOpacity(
            opacity: shown ? 1 : 0,
            duration: const Duration(milliseconds: 150),
            child: Text(label, style: ShadTheme.of(context).textTheme.h3),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final seconds = widget.step.inSeconds;
    return Row(
      children: [_zone(-1, '-$seconds dtk'), _zone(1, '+$seconds dtk')],
    );
  }
}
