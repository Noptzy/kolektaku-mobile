import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../core/routes.dart';
import '../../data/providers/download_providers.dart';
import '../../widgets/pressable.dart';
import 'download_logic.dart';
import 'download_ring.dart';

const downloadFabSize = 52.0;

class DownloadFab extends ConsumerWidget {
  const DownloadFab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final jobs = ref.watch(downloadsProvider);
    final active = activeOf(jobs);
    final progress = overallProgress(jobs) ?? 1;
    final visible = active.isNotEmpty;
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 260),
      switchInCurve: Curves.easeOutBack,
      switchOutCurve: Curves.easeIn,
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: ScaleTransition(scale: animation, child: child),
      ),
      child: visible
          ? _Button(
              key: const ValueKey('download-fab-on'),
              count: active.length,
              progress: progress,
              onTap: () => context.push(Routes.downloads),
            )
          : const SizedBox.shrink(key: ValueKey('download-fab-off')),
    );
  }
}

class _Button extends StatelessWidget {
  const _Button({
    super.key,
    required this.count,
    required this.progress,
    required this.onTap,
  });

  final int count;
  final double progress;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = ShadTheme.of(context).colorScheme;
    return Pressable(
      key: const Key('download-fab'),
      onTap: onTap,
      label: 'Unduhan berjalan, ${percent(progress)}',
      child: SizedBox.square(
        dimension: downloadFabSize,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: scheme.card,
                shape: BoxShape.circle,
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x66000000),
                    blurRadius: 12,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: DownloadRing(
                progress: progress,
                color: scheme.primary,
                track: scheme.border,
                thickness: 3.5,
                child: const Center(child: BouncingArrow()),
              ),
            ),
            if (count > 1)
              Positioned(top: -2, right: -2, child: _Badge(count: count)),
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final scheme = ShadTheme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(color: scheme.primary, shape: BoxShape.circle),
      child: SizedBox.square(
        dimension: 20,
        child: Center(
          child: Text(
            '$count',
            style: TextStyle(
              color: scheme.primaryForeground,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}

class BouncingArrow extends StatefulWidget {
  const BouncingArrow({super.key});

  @override
  State<BouncingArrow> createState() => _BouncingArrowState();
}

class _BouncingArrowState extends State<BouncingArrow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _motion = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _motion.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = ShadTheme.of(context).colorScheme.primary;
    return AnimatedBuilder(
      animation: _motion,
      builder: (context, child) => Transform.translate(
        offset: Offset(0, Curves.easeInOut.transform(_motion.value) * 4 - 2),
        child: child,
      ),
      child: Icon(LucideIcons.arrowDown, size: 20, color: color),
    );
  }
}
