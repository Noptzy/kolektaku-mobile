import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../src/rust/dto/settings.dart';

const _outlineSteps = 12;

double subtitleScale(SubtitleSizeDto size) => switch (size) {
  SubtitleSizeDto.small => 0.85,
  SubtitleSizeDto.medium => 1.0,
  SubtitleSizeDto.large => 1.3,
  SubtitleSizeDto.huge => 1.65,
};

Color subtitleInk(SubtitleColorDto color) => switch (color) {
  SubtitleColorDto.white => const Color(0xFFFFFFFF),
  SubtitleColorDto.yellow => const Color(0xFFFFE04A),
  SubtitleColorDto.green => const Color(0xFF7CF29A),
  SubtitleColorDto.cyan => const Color(0xFF6FE3FF),
  SubtitleColorDto.pink => const Color(0xFFFF9EC8),
};

Color subtitleBoxInk(SubtitleBoxColorDto color) => switch (color) {
  SubtitleBoxColorDto.black => const Color(0xFF000000),
  SubtitleBoxColorDto.gray => const Color(0xFF4A4A52),
  SubtitleBoxColorDto.navy => const Color(0xFF0B1F4D),
};

double subtitleBoxAlpha(SubtitleBoxOpacityDto opacity) => switch (opacity) {
  SubtitleBoxOpacityDto.off => 0,
  SubtitleBoxOpacityDto.light => 0.4,
  SubtitleBoxOpacityDto.medium => 0.7,
  SubtitleBoxOpacityDto.full => 1,
};

List<Shadow> _outline(double fontSize) {
  final radius = math.max(1.2, fontSize * 0.075);
  return [
    for (var step = 0; step < _outlineSteps; step++)
      Shadow(
        color: const Color(0xFF000000),
        blurRadius: 0.6,
        offset: Offset(
          radius * math.cos(step * 2 * math.pi / _outlineSteps),
          radius * math.sin(step * 2 * math.pi / _outlineSteps),
        ),
      ),
  ];
}

List<Shadow>? _edge(SubtitleEdgeDto edge, double fontSize) => switch (edge) {
  SubtitleEdgeDto.none => null,
  SubtitleEdgeDto.shadow => const [
    Shadow(blurRadius: 3, color: Color(0xFF000000)),
    Shadow(blurRadius: 6, color: Color(0xFF000000)),
  ],
  SubtitleEdgeDto.outline => _outline(fontSize),
};

TextStyle subtitleTextStyle(SettingsDto settings, {double base = 16}) {
  final size = base * subtitleScale(settings.subtitleSize);
  return TextStyle(
    color: subtitleInk(settings.subtitleColor),
    fontSize: size,
    height: 1.3,
    fontWeight: FontWeight.w600,
    shadows: _edge(settings.subtitleEdge, size),
  );
}

BoxDecoration? subtitleBoxDecoration(SettingsDto settings) {
  final alpha = subtitleBoxAlpha(settings.subtitleBoxOpacity);
  if (alpha == 0) return null;
  return BoxDecoration(
    color: subtitleBoxInk(settings.subtitleBoxColor).withValues(alpha: alpha),
    borderRadius: BorderRadius.circular(6),
  );
}
