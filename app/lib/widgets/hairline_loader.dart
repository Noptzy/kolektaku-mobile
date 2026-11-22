import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../core/hairline/brush.dart';
import '../core/hairline/hairline_stage.dart';
import '../core/theme/kolektaku_tokens.dart';
import '../figures/gulungan.dart';
import '../figures/lupa.dart';
import '../figures/tumpuk.dart';

enum HairlineKind { lupa, gulungan, tumpuk }

const hairlineLoaderHeight = 96.0;

HairlineFigure createFigure(HairlineKind kind) => switch (kind) {
  HairlineKind.lupa => Lupa(),
  HairlineKind.gulungan => Gulungan(),
  HairlineKind.tumpuk => Tumpuk(),
};

class HairlineLoader extends StatelessWidget {
  const HairlineLoader({
    super.key,
    required this.kind,
    this.message,
    this.height = hairlineLoaderHeight,
  });

  final HairlineKind kind;
  final String? message;
  final double height;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return Semantics(
      liveRegion: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        spacing: Spacing.sm,
        children: [
          HairlineStage(create: () => createFigure(kind), height: height),
          if (message != null)
            Text(
              message!,
              textAlign: TextAlign.center,
              style: theme.textTheme.large,
            ),
        ],
      ),
    );
  }
}
