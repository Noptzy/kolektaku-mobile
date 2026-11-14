import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../core/theme/kolektaku_tokens.dart';

enum StateKind { empty, error, offline }

class StateView extends StatelessWidget {
  const StateView({
    super.key,
    required this.kind,
    required this.title,
    this.message,
    this.actionLabel,
    this.onAction,
  });

  const StateView.empty({
    Key? key,
    required String title,
    String? message,
    String? actionLabel,
    VoidCallback? onAction,
  }) : this(
         key: key,
         kind: StateKind.empty,
         title: title,
         message: message,
         actionLabel: actionLabel,
         onAction: onAction,
       );

  const StateView.error({
    Key? key,
    required String title,
    String? message,
    String? actionLabel,
    VoidCallback? onAction,
  }) : this(
         key: key,
         kind: StateKind.error,
         title: title,
         message: message,
         actionLabel: actionLabel,
         onAction: onAction,
       );

  const StateView.offline({
    Key? key,
    String title = 'Tidak ada koneksi',
    String? message = 'Periksa sambungan internet lalu coba lagi.',
    String? actionLabel = 'Coba lagi',
    VoidCallback? onAction,
  }) : this(
         key: key,
         kind: StateKind.offline,
         title: title,
         message: message,
         actionLabel: actionLabel,
         onAction: onAction,
       );

  final StateKind kind;
  final String title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;

  IconData get _icon => switch (kind) {
    StateKind.empty => LucideIcons.inbox,
    StateKind.error => LucideIcons.circleAlert,
    StateKind.offline => LucideIcons.wifiOff,
  };

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final detail = message;
    final label = actionLabel;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Spacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(_icon, size: 40, color: theme.colorScheme.mutedForeground),
            const SizedBox(height: Spacing.lg),
            Text(title, textAlign: TextAlign.center, style: theme.textTheme.h4),
            if (detail != null) ...[
              const SizedBox(height: Spacing.sm),
              Text(
                detail,
                textAlign: TextAlign.center,
                style: theme.textTheme.muted,
              ),
            ],
            if (label != null && onAction != null) ...[
              const SizedBox(height: Spacing.lg),
              ShadButton(onPressed: onAction, child: Text(label)),
            ],
          ],
        ),
      ),
    );
  }
}
