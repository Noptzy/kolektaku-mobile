import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import 'player_menus.dart';
import 'player_session.dart';
import 'subtitle_logic.dart';
import 'translation_logic.dart';

typedef SettingPage = Widget Function(VoidCallback close);

typedef SettingChoice = ({
  String id,
  IconData icon,
  String label,
  String title,
  String value,
  SettingPage page,
});

String resolutionValue(PlayerSession session) {
  final sources = session.sources;
  if (sources.length > 1) return sources[session.quality.value].label;
  final chosen = session.extras.trackId.value;
  return session.extras.tracks.value
      .where((track) => track.id == chosen)
      .map((track) => track.label)
      .followedBy(const ['Otomatis'])
      .first;
}

bool hasResolutions(PlayerSession session) =>
    session.sources.length > 1 || session.extras.tracks.value.length > 1;

List<SettingChoice> settingChoices({
  required PlayerSession session,
  required VoidCallback onInteract,
  SettingPage? audioPage,
  String? audioLabel,
}) {
  final speed = session.engine.snapshot.value.speed;
  return [
    if (hasResolutions(session))
      (
        id: 'quality',
        icon: LucideIcons.monitorPlay,
        label: 'Resolusi',
        title: 'Resolusi',
        value: resolutionValue(session),
        page: (close) => _resolutionPage(session, onInteract, close),
      ),
    if (session.extras.hasSubtitles)
      (
        id: 'subtitle',
        icon: LucideIcons.captions,
        label: 'Subtitle',
        title: 'Subtitle',
        value: _subtitleValue(session),
        page: (close) => _subtitlePage(session, onInteract, close),
      ),
    if (audioPage != null)
      (
        id: 'audio',
        icon: LucideIcons.audioLines,
        label: 'Suara',
        title: 'Suara (sub atau dub)',
        value: audioLabel ?? 'Server',
        page: audioPage,
      ),
    (
      id: 'speed',
      icon: LucideIcons.gauge,
      label: 'Kecepatan',
      title: 'Kecepatan',
      value: speedLabel(speed),
      page: (close) => speedOptions(
        current: speed,
        onPicked: (next) {
          session.setSpeed(next);
          onInteract();
          close();
        },
      ),
    ),
  ];
}

String? _translationLabel(PlayerSession session) {
  final cues = session.extras.subtitleCues;
  final target = session.settings.translation;
  return switch (cues.status.value) {
    TranslationStatus.translated => translatedTitle(target),
    TranslationStatus.working => translatingTitle(target),
    _ => null,
  };
}

String _subtitleValue(PlayerSession session) {
  final current = session.extras.subtitle.value;
  if (current == null) return 'Mati';
  return _translationLabel(session) ?? subtitleTitle(current);
}

Widget? _translationButton(
  PlayerSession session,
  VoidCallback onInteract,
  VoidCallback close,
) {
  final cues = session.extras.subtitleCues;
  void after(VoidCallback action) {
    action();
    onInteract();
    close();
  }

  if (cues.canToggleOriginal) {
    return originalTextToggle(
      showingOriginal: cues.showingOriginal.value,
      onPressed: () => after(cues.toggleOriginal),
    );
  }
  if (!cues.canTranslate) return null;
  return translateNowButton(
    target: session.settings.translation,
    onPressed: () => after(() => cues.translateNow()),
  );
}

Widget _subtitlePage(
  PlayerSession session,
  VoidCallback onInteract,
  VoidCallback close,
) {
  return subtitleOptions(
    tracks: session.extras.available,
    current: session.extras.subtitle.value,
    currentLabel: _translationLabel(session),
    originalToggle: _translationButton(session, onInteract, close),
    onPicked: (track) {
      session.extras.pickSubtitle(track);
      onInteract();
      close();
    },
  );
}

Widget _resolutionPage(
  PlayerSession session,
  VoidCallback onInteract,
  VoidCallback close,
) {
  if (session.sources.length > 1) {
    return qualityOptions(
      sources: session.sources,
      current: session.quality.value,
      onPicked: (index) {
        session.selectQuality(index);
        onInteract();
        close();
      },
    );
  }
  return trackOptions(
    tracks: session.extras.tracks.value,
    current: session.extras.trackId.value,
    onPicked: (id) {
      session.extras.selectTrack(id);
      onInteract();
      close();
    },
  );
}
