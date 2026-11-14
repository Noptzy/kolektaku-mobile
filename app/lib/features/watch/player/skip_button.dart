import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../src/rust/dto/stream_extras.dart';
import 'player_session.dart';
import 'skip_logic.dart';

class SkipButton extends StatelessWidget {
  const SkipButton({super.key, required this.session, required this.lifted});

  final PlayerSession session;
  final bool lifted;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<SkipDto?>(
      valueListenable: session.extras.current,
      builder: (context, range, child) {
        if (range == null) return const SizedBox.shrink();
        return Align(
          alignment: Alignment.bottomRight,
          child: Padding(
            padding: EdgeInsets.fromLTRB(0, 0, 16, lifted ? 88 : 24),
            child: ShadButton.secondary(
              key: const Key('skip-button'),
              size: ShadButtonSize.sm,
              leading: const Icon(LucideIcons.skipForward, size: 16),
              onPressed: session.extras.skipCurrent,
              child: Text(skipLabel(range)),
            ),
          ),
        );
      },
    );
  }
}
