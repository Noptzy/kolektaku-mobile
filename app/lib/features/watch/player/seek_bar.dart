import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../src/rust/dto/stream_extras.dart';
import 'playback_engine.dart';
import 'seek_bubble.dart';
import 'seek_painter.dart';
import 'skip_logic.dart';

const skipMarkColor = Color(0xFF4DD0E1);

class SeekBar extends StatefulWidget {
  const SeekBar({
    super.key,
    required this.snapshot,
    required this.onSeek,
    this.onScrub,
    this.skips,
  });

  final ValueListenable<PlaybackSnapshot> snapshot;
  final ValueChanged<double> onSeek;
  final VoidCallback? onScrub;
  final ValueListenable<List<SkipDto>>? skips;

  @override
  State<SeekBar> createState() => _SeekBarState();
}

class _SeekBarState extends State<SeekBar> {
  double? _drag;

  double _fractionAt(double dx, double width) {
    final track = width - seekInset * 2;
    if (track <= 0) return 0;
    return ((dx - seekInset) / track).clamp(0.0, 1.0);
  }

  void _dragTo(double dx, double width) {
    setState(() => _drag = _fractionAt(dx, width));
    widget.onScrub?.call();
  }

  void _finishDrag() {
    final target = _drag;
    setState(() => _drag = null);
    if (target != null) widget.onSeek(target);
  }

  List<MarkSpan> _marks(PlaybackSnapshot snapshot) {
    final skips = widget.skips?.value ?? const <SkipDto>[];
    return skipFractions(skips, snapshot.duration);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = ShadTheme.of(context).colorScheme;
    return LayoutBuilder(
      builder: (context, box) {
        final width = box.maxWidth;
        return Semantics(
          label: 'Posisi video',
          slider: true,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              GestureDetector(
                key: const Key('seek-bar'),
                behavior: HitTestBehavior.opaque,
                onTapUp: (details) =>
                    widget.onSeek(_fractionAt(details.localPosition.dx, width)),
                onHorizontalDragStart: (details) =>
                    _dragTo(details.localPosition.dx, width),
                onHorizontalDragUpdate: (details) =>
                    _dragTo(details.localPosition.dx, width),
                onHorizontalDragEnd: (details) => _finishDrag(),
                onHorizontalDragCancel: () => setState(() => _drag = null),
                child: SizedBox(
                  height: 32,
                  width: double.infinity,
                  child: ListenableBuilder(
                    listenable: Listenable.merge([
                      widget.snapshot,
                      ?widget.skips,
                    ]),
                    builder: (context, child) {
                      final snapshot = widget.snapshot.value;
                      return CustomPaint(
                        painter: SeekPainter(
                          fraction: _drag ?? snapshot.fraction,
                          marks: _marks(snapshot),
                          dragging: _drag != null,
                          trackColor: scheme.secondary,
                          playedColor: scheme.primary,
                          markColor: skipMarkColor,
                        ),
                      );
                    },
                  ),
                ),
              ),
              if (_drag != null) _bubble(width),
            ],
          ),
        );
      },
    );
  }

  Widget _bubble(double width) {
    final snapshot = widget.snapshot.value;
    final fraction = _drag ?? 0;
    return SeekBubble(
      target: snapshot.duration * fraction,
      current: snapshot.position,
      thumbX: seekInset + (width - seekInset * 2) * fraction,
      trackWidth: width,
    );
  }
}
