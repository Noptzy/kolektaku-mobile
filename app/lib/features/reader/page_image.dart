import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../core/theme/kolektaku_tokens.dart';
import '../../widgets/pressable.dart';
import '../watch/player/stream_spinner.dart';

typedef PageImageFactory = ImageProvider Function(String url, int? decodeWidth);

ImageProvider networkPageImage(String url, int? decodeWidth) {
  final network = NetworkImage(url);
  if (decodeWidth == null) return network;
  return ResizeImage(network, width: decodeWidth, allowUpscaling: false);
}

class PageImage extends StatefulWidget {
  const PageImage({
    super.key,
    required this.provider,
    required this.aspect,
    required this.onAspect,
  });

  final ImageProvider provider;
  final double aspect;
  final ValueChanged<double> onAspect;

  @override
  State<PageImage> createState() => _PageImageState();
}

class _PageImageState extends State<PageImage> {
  ImageStream? _stream;
  ImageInfo? _info;
  bool _failed = false;
  late final ImageStreamListener _listener = ImageStreamListener(
    _onImage,
    onError: _onError,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _resolve();
  }

  @override
  void didUpdateWidget(PageImage old) {
    super.didUpdateWidget(old);
    if (old.provider != widget.provider) _resolve();
  }

  void _resolve() {
    final next = widget.provider.resolve(
      createLocalImageConfiguration(context),
    );
    if (next.key == _stream?.key) return;
    _stream?.removeListener(_listener);
    _stream = next..addListener(_listener);
  }

  void _onImage(ImageInfo info, bool synchronous) {
    final image = info.image;
    final aspect = image.width / image.height;
    final previous = _info;
    setState(() {
      _info = info;
      _failed = false;
    });
    previous?.dispose();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.onAspect(aspect);
    });
  }

  void _onError(Object error, StackTrace? stack) {
    if (mounted) setState(() => _failed = true);
  }

  void _retry() {
    widget.provider.evict();
    _stream?.removeListener(_listener);
    _stream = null;
    setState(() => _failed = false);
    _resolve();
  }

  @override
  void dispose() {
    _stream?.removeListener(_listener);
    _info?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final info = _info;
    if (info != null) {
      return AspectRatio(
        aspectRatio: info.image.width / info.image.height,
        child: RawImage(
          image: info.image,
          scale: info.scale,
          fit: BoxFit.fill,
          filterQuality: FilterQuality.medium,
        ),
      );
    }
    return AspectRatio(
      aspectRatio: widget.aspect,
      child: _failed ? _Failed(onRetry: _retry) : const _Loading(),
    );
  }
}

class _Loading extends StatelessWidget {
  const _Loading();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: ShadTheme.of(context).colorScheme.card,
      child: const Center(child: StreamSpinner(size: 32)),
    );
  }
}

class _Failed extends StatelessWidget {
  const _Failed({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return ColoredBox(
      color: theme.colorScheme.card,
      child: Pressable(
        key: const Key('page-retry'),
        onTap: onRetry,
        label: 'Muat ulang halaman',
        minSize: Sizes.touchTarget,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            spacing: Spacing.sm,
            children: [
              Icon(
                LucideIcons.refreshCw,
                size: 24,
                color: theme.colorScheme.mutedForeground,
              ),
              Text('Ketuk untuk muat ulang', style: theme.textTheme.muted),
            ],
          ),
        ),
      ),
    );
  }
}
