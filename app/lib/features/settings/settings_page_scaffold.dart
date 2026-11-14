import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../core/theme/kolektaku_tokens.dart';
import 'settings_widgets.dart';

class SettingsPageScaffold extends StatelessWidget {
  const SettingsPageScaffold({
    super.key,
    required this.title,
    required this.intro,
    required this.children,
    this.pinned,
  });

  final String title;
  final String intro;
  final List<Widget> children;
  final Widget? pinned;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return ColoredBox(
      color: theme.colorScheme.background,
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                Spacing.sm,
                Spacing.sm,
                Spacing.screenGutter,
                Spacing.xs,
              ),
              child: Row(
                spacing: Spacing.xs,
                children: [
                  ShadIconButton.ghost(
                    key: const Key('settings-back'),
                    icon: const Icon(LucideIcons.arrowLeft),
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.h4.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            ?pinned,
            Expanded(
              child: ListView(
                padding: const EdgeInsets.only(bottom: Spacing.xxl),
                children: [SettingsNote(intro), ...children],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
