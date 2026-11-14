import 'package:flutter/widgets.dart';

import '../../../core/subtitle_text.dart';
import '../../../src/rust/dto/cues.dart';
import '../../../src/rust/dto/settings.dart';
import 'playback_engine.dart';
import 'player_session.dart';
import 'subtitle_logic.dart';

class SubtitleOverlay extends StatelessWidget {
  const SubtitleOverlay({
    super.key,
    required this.session,
    required this.settings,
    required this.lifted,
  });

  final PlayerSession session;
  final SettingsDto settings;
  final bool lifted;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: ValueListenableBuilder<List<CueDto>>(
        valueListenable: session.extras.cues,
        builder: (context, cues, child) {
          if (cues.isEmpty) return const SizedBox.shrink();
          return ValueListenableBuilder<PlaybackSnapshot>(
            valueListenable: session.engine.snapshot,
            builder: (context, snapshot, child) {
              final cue = cueAt(cues, snapshot.position);
              if (cue == null) return const SizedBox.shrink();
              return _Line(text: cue.text, settings: settings, lifted: lifted);
            },
          );
        },
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({
    required this.text,
    required this.settings,
    required this.lifted,
  });

  final String text;
  final SettingsDto settings;
  final bool lifted;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: EdgeInsets.fromLTRB(24, 0, 24, lifted ? 96 : 36),
        child: SubtitleText(
          text: text,
          settings: settings,
          textKey: const Key('subtitle-line'),
        ),
      ),
    );
  }
}
