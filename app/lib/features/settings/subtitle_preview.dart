import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../core/subtitle_text.dart';
import '../../core/theme/kolektaku_tokens.dart';
import '../../src/rust/dto/settings.dart';

const subtitleSample = 'Ini contoh teks subtitle.';
const subtitleOffText = 'Subtitle dimatikan';

class SubtitlePreview extends StatelessWidget {
  const SubtitlePreview({super.key, required this.settings});

  final SettingsDto settings;

  @override
  Widget build(BuildContext context) {
    final off = settings.subtitleLanguage == SubtitleLanguageDto.off;
    final muted = ShadTheme.of(context).colorScheme.mutedForeground;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.screenGutter,
        vertical: Spacing.sm,
      ),
      child: ClipRRect(
        borderRadius: Radii.cardShape,
        child: SizedBox(
          height: 120,
          child: Stack(
            fit: StackFit.expand,
            children: [
              const Row(
                children: [
                  Expanded(child: ColoredBox(color: Color(0xFFE9E3D2))),
                  Expanded(child: ColoredBox(color: Color(0xFF2B2B35))),
                ],
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: Spacing.md),
                  child: off
                      ? Text(
                          subtitleOffText,
                          style: TextStyle(color: muted, fontSize: 14),
                        )
                      : SubtitleText(
                          text: subtitleSample,
                          settings: settings,
                          textKey: const Key('subtitle-preview'),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
