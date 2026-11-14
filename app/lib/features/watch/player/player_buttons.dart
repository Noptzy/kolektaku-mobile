import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../src/rust/dto/stream_extras.dart';
import 'player_menus.dart';
import 'player_session.dart';

class SubtitleButton extends StatelessWidget {
  const SubtitleButton({
    super.key,
    required this.session,
    required this.onInteract,
  });

  final PlayerSession session;
  final VoidCallback onInteract;

  @override
  Widget build(BuildContext context) {
    if (!session.extras.hasSubtitles) return const SizedBox.shrink();
    return ValueListenableBuilder<SubtitleDto?>(
      valueListenable: session.extras.subtitle,
      builder: (context, current, child) => ShadIconButton.ghost(
        key: const Key('subtitles'),
        icon: Icon(
          current == null ? LucideIcons.captionsOff : LucideIcons.captions,
        ),
        onPressed: () => pickSubtitle(
          context,
          tracks: session.extras.available,
          current: current,
          onPicked: (track) {
            session.extras.selectSubtitle(track);
            onInteract();
          },
        ),
      ),
    );
  }
}

class QualityButton extends StatelessWidget {
  const QualityButton({
    super.key,
    required this.session,
    required this.onInteract,
  });

  final PlayerSession session;
  final VoidCallback onInteract;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        session.quality,
        session.extras.tracks,
        session.extras.trackId,
      ]),
      builder: (context, child) {
        final sources = session.sources;
        final tracks = session.extras.tracks.value;
        if (sources.length > 1) return _sources(context);
        if (tracks.length < 2) return const SizedBox.shrink();
        final chosen = session.extras.trackId.value;
        final label = tracks
            .where((track) => track.id == chosen)
            .map((track) => track.label)
            .followedBy(const ['Otomatis'])
            .first;
        return ShadButton.ghost(
          key: const Key('quality'),
          size: ShadButtonSize.sm,
          onPressed: () => pickTrack(
            context,
            tracks: tracks,
            current: chosen,
            onPicked: (id) {
              session.extras.selectTrack(id);
              onInteract();
            },
          ),
          child: Text(label),
        );
      },
    );
  }

  Widget _sources(BuildContext context) {
    final current = session.quality.value;
    return ShadButton.ghost(
      key: const Key('quality'),
      size: ShadButtonSize.sm,
      onPressed: () => pickQuality(
        context,
        sources: session.sources,
        current: current,
        onPicked: (index) {
          session.selectQuality(index);
          onInteract();
        },
      ),
      child: Text(session.sources[current].label),
    );
  }
}
