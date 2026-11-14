import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../core/theme/kolektaku_tokens.dart';
import '../../widgets/swipe_sheet.dart';
import 'update_controller.dart';
import 'update_panel.dart';
import 'update_state.dart';

class UpdateHost extends ConsumerStatefulWidget {
  const UpdateHost({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<UpdateHost> createState() => _UpdateHostState();
}

class _UpdateHostState extends ConsumerState<UpdateHost> {
  String? _shownFor;
  bool _open = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(updateControllerProvider.notifier).checkOnLaunch();
      }
    });
  }

  void _present(UpdateState state) {
    final offer = state.offer;
    if (offer == null || state.isRequired || _open) return;
    final fresh =
        state.phase == UpdatePhase.available && _shownFor != offer.version;
    if (!fresh && state.phase != UpdatePhase.ready) return;
    _shownFor = offer.version;
    _open = true;
    showSwipeSheet<void>(
      context: context,
      builder: (sheetContext) => ShadSheet(
        title: Text('Pembaruan ${offer.version}'),
        description: const Text('Versi baru Kolektaku siap dipasang.'),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: Spacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: Spacing.md,
            children: [
              const UpdatePanel(),
              ShadButton.ghost(
                key: const Key('update-later'),
                onPressed: () => Navigator.of(sheetContext).maybePop(),
                child: const Text('Nanti saja'),
              ),
            ],
          ),
        ),
      ),
    ).whenComplete(() => _open = false);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<UpdateState>(updateControllerProvider, (previous, next) {
      if (previous?.phase != next.phase) _present(next);
    });
    final state = ref.watch(updateControllerProvider);
    final blocked = state.isRequired && state.phase != UpdatePhase.upToDate;
    return Stack(
      fit: StackFit.expand,
      children: [widget.child, if (blocked) const RequiredUpdateGate()],
    );
  }
}

class RequiredUpdateGate extends StatelessWidget {
  const RequiredUpdateGate({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return PopScope(
      canPop: false,
      child: ColoredBox(
        key: const Key('required-update'),
        color: theme.colorScheme.background,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(Spacing.xl),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: Spacing.lg,
              children: [
                Icon(
                  LucideIcons.circleArrowDown,
                  size: 48,
                  color: theme.colorScheme.primary,
                ),
                Text(
                  'Perlu diperbarui',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.h3,
                ),
                Text(
                  'Versi ini sudah tidak didukung. Perbarui Kolektaku '
                  'untuk melanjutkan.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.muted,
                ),
                const UpdatePanel(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
