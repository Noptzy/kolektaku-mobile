import 'package:flutter/widgets.dart';

import '../../core/theme/kolektaku_tokens.dart';
import '../../widgets/poster.dart';

const wallColumns = 4;
const wallTilesPerColumn = 6;
const _gap = 8.0;
const _tilt = -0.16;
const _zoom = 1.4;
const _loop = Duration(seconds: 80);

class WallColumns extends StatefulWidget {
  const WallColumns({super.key, required this.covers});

  final List<String> covers;

  @override
  State<WallColumns> createState() => _WallColumnsState();
}

class _WallColumnsState extends State<WallColumns>
    with SingleTickerProviderStateMixin {
  late final AnimationController _drift = AnimationController(
    vsync: this,
    duration: _loop,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _drift.stop();
    } else if (!_drift.isAnimating) {
      _drift.repeat();
    }
  }

  @override
  void dispose() {
    _drift.dispose();
    super.dispose();
  }

  String? _cover(int column, int tile) {
    final covers = widget.covers;
    if (covers.isEmpty) return null;
    return covers[(column * 3 + tile) % covers.length];
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Transform.scale(
        scale: _zoom,
        child: Transform.rotate(
          angle: _tilt,
          child: Row(
            spacing: _gap,
            children: [
              for (var c = 0; c < wallColumns; c++)
                Expanded(
                  child: _Column(
                    drift: _drift,
                    upward: c.isEven,
                    coverAt: (tile) => _cover(c, tile),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Column extends StatelessWidget {
  const _Column({
    required this.drift,
    required this.upward,
    required this.coverAt,
  });

  final Animation<double> drift;
  final bool upward;
  final String? Function(int tile) coverAt;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        final tileHeight = box.maxWidth / Sizes.posterAspect + _gap;
        final cycle = tileHeight * wallTilesPerColumn;
        return ClipRect(
          child: OverflowBox(
            alignment: Alignment.topCenter,
            maxHeight: double.infinity,
            child: AnimatedBuilder(
              animation: drift,
              builder: (context, child) {
                final t = drift.value;
                final dy = upward ? -t * cycle : (t - 1) * cycle;
                return Transform.translate(offset: Offset(0, dy), child: child);
              },
              child: Column(
                children: [
                  for (var round = 0; round < 2; round++)
                    for (var tile = 0; tile < wallTilesPerColumn; tile++)
                      Padding(
                        padding: const EdgeInsets.only(bottom: _gap),
                        child: Poster(url: coverAt(tile)),
                      ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
