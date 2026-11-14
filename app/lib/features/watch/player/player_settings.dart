import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../core/theme/kolektaku_text.dart';
import '../../../core/theme/kolektaku_tokens.dart';
import '../../../widgets/pressable.dart';
import '../../../widgets/swipe_sheet.dart';
import 'player_menus.dart';
import 'player_session.dart';
import 'subtitle_logic.dart';

typedef SettingChoice = ({
  String id,
  IconData icon,
  String label,
  String value,
  VoidCallback open,
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

List<SettingChoice> settingChoices(
  BuildContext context, {
  required PlayerSession session,
  required VoidCallback onInteract,
  VoidCallback? onAudio,
  String? audioLabel,
}) {
  final speed = session.engine.snapshot.value.speed;
  return [
    if (hasResolutions(session))
      (
        id: 'quality',
        icon: LucideIcons.monitorPlay,
        label: 'Resolusi',
        value: resolutionValue(session),
        open: () => _openResolution(context, session, onInteract),
      ),
    if (session.extras.hasSubtitles)
      (
        id: 'subtitle',
        icon: LucideIcons.captions,
        label: 'Subtitle',
        value: _subtitleValue(session),
        open: () => pickSubtitle(
          context,
          tracks: session.extras.available,
          current: session.extras.subtitle.value,
          onPicked: (track) {
            session.extras.selectSubtitle(track);
            onInteract();
          },
        ),
      ),
    if (onAudio != null)
      (
        id: 'audio',
        icon: LucideIcons.audioLines,
        label: 'Suara (sub atau dub)',
        value: audioLabel ?? 'Server',
        open: onAudio,
      ),
    (
      id: 'speed',
      icon: LucideIcons.gauge,
      label: 'Kecepatan',
      value: speedLabel(speed),
      open: () => pickSpeed(
        context,
        current: speed,
        onPicked: (next) {
          session.setSpeed(next);
          onInteract();
        },
      ),
    ),
  ];
}

String _subtitleValue(PlayerSession session) {
  final current = session.extras.subtitle.value;
  return current == null ? 'Mati' : subtitleTitle(current);
}

Future<void> _openResolution(
  BuildContext context,
  PlayerSession session,
  VoidCallback onInteract,
) {
  if (session.sources.length > 1) {
    return pickQuality(
      context,
      sources: session.sources,
      current: session.quality.value,
      onPicked: (index) {
        session.selectQuality(index);
        onInteract();
      },
    );
  }
  return pickTrack(
    context,
    tracks: session.extras.tracks.value,
    current: session.extras.trackId.value,
    onPicked: (id) {
      session.extras.selectTrack(id);
      onInteract();
    },
  );
}

class PlayerSettingsButton extends StatelessWidget {
  const PlayerSettingsButton({
    super.key,
    required this.session,
    required this.onInteract,
    this.onAudio,
    this.audioLabel,
  });

  final PlayerSession session;
  final VoidCallback onInteract;
  final VoidCallback? onAudio;
  final String? audioLabel;

  @override
  Widget build(BuildContext context) {
    return ShadIconButton.ghost(
      key: const Key('player-settings'),
      icon: const Icon(LucideIcons.settings),
      onPressed: () {
        onInteract();
        final choices = settingChoices(
          context,
          session: session,
          onInteract: onInteract,
          onAudio: onAudio,
          audioLabel: audioLabel,
        );
        showSwipeSheet<void>(
          context: context,
          builder: (sheet) => ShadSheet(
            title: const Text('Pengaturan pemutar'),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: Spacing.sm),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final choice in choices)
                    SettingRow(
                      choice: choice,
                      onTap: () {
                        Navigator.of(sheet).pop();
                        choice.open();
                      },
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

class SettingRow extends StatelessWidget {
  const SettingRow({super.key, required this.choice, required this.onTap});

  final SettingChoice choice;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final muted = theme.colorScheme.mutedForeground;
    return Pressable(
      key: Key('settings-row-${choice.id}'),
      onTap: onTap,
      label: '${choice.label}, ${choice.value}',
      minSize: Sizes.touchTarget,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: Spacing.sm),
        child: Row(
          spacing: Spacing.md,
          children: [
            Icon(choice.icon, size: 20, color: muted),
            Expanded(child: Text(choice.label, style: theme.textTheme.p)),
            Flexible(
              child: Text(
                choice.value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.cardMeta.copyWith(color: muted),
              ),
            ),
            Icon(LucideIcons.chevronRight, size: 18, color: muted),
          ],
        ),
      ),
    );
  }
}
