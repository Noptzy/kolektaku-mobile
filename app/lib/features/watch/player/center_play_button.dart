import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import 'playback_engine.dart';

class CenterPlayButton extends StatelessWidget {
  const CenterPlayButton({
    super.key,
    required this.snapshot,
    required this.onPressed,
  });

  final ValueListenable<PlaybackSnapshot> snapshot;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ValueListenableBuilder<PlaybackSnapshot>(
        valueListenable: snapshot,
        builder: (context, current, child) => GestureDetector(
          key: const Key('play-pause'),
          behavior: HitTestBehavior.opaque,
          onTap: onPressed,
          child: DecoratedBox(
            decoration: const BoxDecoration(
              color: Color(0x66000000),
              shape: BoxShape.circle,
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Icon(
                current.playing ? LucideIcons.pause : LucideIcons.play,
                size: 34,
                color: const Color(0xFFFFFFFF),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
