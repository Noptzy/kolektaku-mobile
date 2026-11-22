import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../core/hairline/hairline_stage.dart';
import '../../../core/theme/kolektaku_tokens.dart';
import '../../../figures/gulungan.dart';
import '../../../widgets/poster.dart';

const slowAfter = Duration(seconds: 10);

class StandbyPanel extends StatelessWidget {
  const StandbyPanel({
    super.key,
    required this.title,
    required this.onBack,
    required this.message,
    this.imageUrl,
    this.detail,
    this.onRetry,
  });

  final String title;
  final VoidCallback onBack;
  final String message;
  final String? imageUrl;
  final String? detail;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const ColoredBox(color: Color(0xFF000000)),
        _Backdrop(url: imageUrl),
        const ColoredBox(color: Color(0x99000000)),
        _Content(
          message: message,
          detail: detail,
          onRetry: onRetry,
          busy: onRetry == null,
        ),
        _Bar(title: title, onBack: onBack),
      ],
    );
  }
}

class _Backdrop extends StatelessWidget {
  const _Backdrop({required this.url});

  final String? url;

  @override
  Widget build(BuildContext context) {
    final address = url;
    if (address == null || address.isEmpty) return const SizedBox.shrink();
    return LayoutBuilder(
      builder: (context, constraints) => Image.network(
        address,
        key: const Key('standby-backdrop'),
        fit: BoxFit.cover,
        cacheWidth: decodeWidth(
          constraints.maxWidth,
          MediaQuery.devicePixelRatioOf(context),
        ),
        gaplessPlayback: true,
        errorBuilder: (context, error, stack) => const SizedBox.shrink(),
        frameBuilder: (context, child, frame, synchronous) => AnimatedOpacity(
          opacity: frame == null && !synchronous ? 0 : 1,
          duration: Motion.regular,
          child: child,
        ),
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({required this.title, required this.onBack});

  final String title;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          children: [
            ShadIconButton.ghost(
              key: const Key('back'),
              icon: const Icon(LucideIcons.arrowLeft),
              onPressed: onBack,
            ),
            Expanded(
              child: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
      ),
    );
  }
}

const _figureHeight = 72.0;

class _Content extends StatelessWidget {
  const _Content({
    required this.message,
    required this.busy,
    this.detail,
    this.onRetry,
  });

  final String message;
  final bool busy;
  final String? detail;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Spacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: Spacing.sm,
          children: [
            if (busy)
              HairlineStage(create: Gulungan.new, height: _figureHeight),
            Text(message, style: theme.textTheme.large),
            if (busy) const _SlowHint(),
            if (detail != null)
              Text(
                detail!,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: theme.textTheme.muted,
              ),
            if (onRetry != null)
              ShadButton(
                key: const Key('retry'),
                onPressed: onRetry,
                child: const Text('Coba lagi'),
              ),
          ],
        ),
      ),
    );
  }
}

class _SlowHint extends StatefulWidget {
  const _SlowHint();

  @override
  State<_SlowHint> createState() => _SlowHintState();
}

class _SlowHintState extends State<_SlowHint> {
  Timer? _timer;
  bool _slow = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer(slowAfter, () {
      if (mounted) setState(() => _slow = true);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: _slow ? 1 : 0,
      duration: Motion.regular,
      child: Text(
        'Agak lama, masih mencoba…',
        key: const Key('slow-hint'),
        style: ShadTheme.of(context).textTheme.muted,
      ),
    );
  }
}
