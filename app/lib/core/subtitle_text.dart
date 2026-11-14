import 'package:flutter/widgets.dart';

import '../src/rust/dto/settings.dart';
import 'subtitle_style.dart';

class SubtitleText extends StatelessWidget {
  const SubtitleText({
    super.key,
    required this.text,
    required this.settings,
    this.base = 16,
    this.textKey,
  });

  final String text;
  final SettingsDto settings;
  final double base;
  final Key? textKey;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: subtitleBoxDecoration(settings) ?? const BoxDecoration(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        child: Text(
          text,
          key: textKey,
          textAlign: TextAlign.center,
          style: subtitleTextStyle(settings, base: base),
        ),
      ),
    );
  }
}
