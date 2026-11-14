import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../core/theme/kolektaku_tokens.dart';
import 'update_controller.dart';
import 'update_labels.dart';
import 'update_state.dart';

class UpdatePanel extends ConsumerWidget {
  const UpdatePanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(updateControllerProvider);
    final theme = ShadTheme.of(context);
    final offer = state.offer;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: Spacing.md,
      children: [
        Text(
          updateStatus(state),
          key: const Key('update-status'),
          style: theme.textTheme.p,
        ),
        if (offer != null && offer.notes.trim().isNotEmpty)
          _Notes(text: offer.notes.trim()),
        if (state.phase == UpdatePhase.downloading) _Progress(state: state),
        _Action(state: state),
      ],
    );
  }
}

class _Notes extends StatelessWidget {
  const _Notes({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.background,
        borderRadius: Radii.cardShape,
        border: Border.all(color: theme.colorScheme.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(Spacing.md),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 220),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: Spacing.xs,
              children: [
                Text(
                  'Catatan rilis',
                  style: theme.textTheme.small.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  text,
                  key: const Key('update-notes'),
                  style: theme.textTheme.muted,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Progress extends StatelessWidget {
  const _Progress({required this.state});

  final UpdateState state;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final fraction = state.fraction;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: Spacing.xs,
      children: [
        ShadProgress(key: const Key('update-progress'), value: fraction),
        Text(
          fraction == null
              ? 'Menunggu data…'
              : '${percentLabel(fraction)} · ${megabytes(state.received)} '
                    'dari ${megabytes(state.total)}',
          key: const Key('update-progress-text'),
          style: theme.textTheme.muted,
        ),
      ],
    );
  }
}

class _Action extends ConsumerWidget {
  const _Action({required this.state});

  final UpdateState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(updateControllerProvider.notifier);
    final offer = state.offer;
    return switch (state.phase) {
      UpdatePhase.checking => const _Button(
        label: 'Memeriksa…',
        keyName: 'update-busy',
      ),
      UpdatePhase.downloading => const _Button(
        label: 'Mengunduh…',
        keyName: 'update-busy',
      ),
      UpdatePhase.installing => const _Button(
        label: 'Memasang…',
        keyName: 'update-busy',
      ),
      UpdatePhase.available => _Button(
        label: 'Unduh · ${megabytes(offer!.size.toInt())}',
        keyName: 'update-download',
        primary: true,
        onPressed: controller.download,
      ),
      UpdatePhase.ready => _Button(
        label: 'Pasang sekarang',
        keyName: 'update-install',
        primary: true,
        onPressed: controller.install,
      ),
      UpdatePhase.failed when offer != null => _Button(
        label: 'Coba lagi',
        keyName: 'update-retry',
        primary: true,
        onPressed: state.path != null
            ? controller.install
            : controller.download,
      ),
      _ => _Button(
        label: 'Cek pembaruan',
        keyName: 'update-check',
        onPressed: controller.checkNow,
      ),
    };
  }
}

class _Button extends StatelessWidget {
  const _Button({
    required this.label,
    required this.keyName,
    this.onPressed,
    this.primary = false,
  });

  final String label;
  final String keyName;
  final VoidCallback? onPressed;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    final text = Flexible(child: Text(label, maxLines: 1));
    return SizedBox(
      width: double.infinity,
      child: primary
          ? ShadButton(key: Key(keyName), onPressed: onPressed, child: text)
          : ShadButton.outline(
              key: Key(keyName),
              onPressed: onPressed,
              child: text,
            ),
    );
  }
}
