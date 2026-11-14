import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../core/theme/kolektaku_tokens.dart';
import '../../widgets/swipe_sheet.dart';
import 'player/clock_format.dart';
import 'watch_controller.dart';

String resumeQuestion(Duration position) =>
    'Terakhir kamu berhenti di ${formatClock(position)}.';

Future<bool?> showResumeSheet(
  BuildContext context, {
  required Duration position,
}) {
  return showSwipeSheet<bool>(
    context: context,
    builder: (sheet) => ShadSheet(
      title: const Text('Lanjutkan menonton?'),
      description: Text(resumeQuestion(position)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: Spacing.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: Spacing.sm,
          children: [
            ShadButton(
              key: const Key('resume-continue'),
              onPressed: () => Navigator.of(sheet).pop(true),
              child: Text('Lanjut dari ${formatClock(position)}'),
            ),
            ShadButton.outline(
              key: const Key('resume-restart'),
              onPressed: () => Navigator.of(sheet).pop(false),
              child: const Text('Mulai dari awal'),
            ),
          ],
        ),
      ),
    ),
  );
}

class ResumeAsker {
  bool _asking = false;

  void follow(
    BuildContext Function() context,
    bool Function() mounted,
    WatchController controller,
  ) {
    final position = controller.resumePrompt;
    if (position == null || _asking) return;
    _asking = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted()) return;
      final choice = await showResumeSheet(context(), position: position);
      _asking = false;
      await controller.chooseResume(resume: choice ?? true);
    });
  }
}
