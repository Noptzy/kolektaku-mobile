import 'package:flutter/widgets.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../core/theme/kolektaku_tokens.dart';
import '../../platform/trailer_embed.dart';
import '../../src/rust/dto/credits.dart';
import '../watch/player/stream_spinner.dart';

typedef TrailerPlayerBuilder = Widget Function(
  BuildContext context,
  TrailerDto trailer,
);

final trailerPlayerProvider = Provider<TrailerPlayerBuilder>(
  (ref) =>
      (context, trailer) => InAppTrailerPlayer(
        key: const Key('trailer-player'),
        trailer: trailer,
      ),
);

class InAppTrailerPlayer extends StatefulWidget {
  const InAppTrailerPlayer({super.key, required this.trailer});

  final TrailerDto trailer;

  @override
  State<InAppTrailerPlayer> createState() => _InAppTrailerPlayerState();
}

class _InAppTrailerPlayerState extends State<InAppTrailerPlayer> {
  bool _ready = false;
  bool _failed = false;
  bool _onWatchPage = false;
  Object? _code;
  InAppWebViewController? _controller;

  String get _site => widget.trailer.site;

  bool get _youtube => _site.toLowerCase() == 'youtube';

  void _fail([Object? code]) {
    if (!mounted) return;
    final watch = youtubeWatchUrl(widget.trailer.videoId);
    if (_youtube && !_onWatchPage && watch != null && _controller != null) {
      setState(() {
        _onWatchPage = true;
        _ready = false;
        _code = code;
      });
      _controller!.loadUrl(urlRequest: URLRequest(url: WebUri(watch)));
      return;
    }
    setState(() {
      _failed = true;
      _code = code ?? _code;
    });
  }

  Future<NavigationActionPolicy> _navigate(NavigationAction action) async {
    final target = action.request.url?.uriValue;
    final allowed = target != null && trailerNavigationAllowed(_site, target);
    return allowed
        ? NavigationActionPolicy.ALLOW
        : NavigationActionPolicy.CANCEL;
  }

  InAppWebViewInitialData? _page() {
    final html = youtubePlayerHtml(widget.trailer.videoId);
    if (html == null) return null;
    return InAppWebViewInitialData(
      data: html,
      baseUrl: WebUri(trailerAppOrigin),
      historyUrl: WebUri(trailerAppOrigin),
    );
  }

  @override
  Widget build(BuildContext context) {
    final embed = trailerEmbedUrl(_site, widget.trailer.videoId);
    if (embed == null || _failed) return _Unavailable(code: _code);
    return Stack(
      fit: StackFit.expand,
      children: [
        const ColoredBox(color: Color(0xFF000000)),
        _Backdrop(url: widget.trailer.thumbnailUrl, visible: !_ready),
        InAppWebView(
          key: const Key('trailer-webview'),
          initialUrlRequest: _youtube
              ? null
              : URLRequest(url: WebUri(embed), headers: trailerHeaders(_site)),
          initialData: _youtube ? _page() : null,
          initialSettings: InAppWebViewSettings(
            javaScriptEnabled: true,
            mediaPlaybackRequiresUserGesture: false,
            allowsInlineMediaPlayback: true,
            supportMultipleWindows: false,
            javaScriptCanOpenWindowsAutomatically: false,
            transparentBackground: true,
            mixedContentMode: MixedContentMode.MIXED_CONTENT_NEVER_ALLOW,
          ),
          onWebViewCreated: (controller) {
            _controller = controller;
            controller.addJavaScriptHandler(
              handlerName: trailerErrorHandler,
              callback: (arguments) {
                _fail(arguments.isEmpty ? null : arguments.first);
                return null;
              },
            );
          },
          shouldOverrideUrlLoading: (_, action) => _navigate(action),
          onCreateWindow: (_, action) async => false,
          onPermissionRequest: (_, request) async => PermissionResponse(
            resources: request.resources,
            action: PermissionResponseAction.DENY,
          ),
          onLoadStop: (_, url) {
            if (mounted) setState(() => _ready = true);
          },
          onReceivedError: (_, request, error) {
            if (request.isForMainFrame == true) _fail(error.description);
          },
          onReceivedHttpError: (_, request, response) {
            if (request.isForMainFrame == true &&
                (response.statusCode ?? 0) >= 400) {
              _fail(response.statusCode);
            }
          },
        ),
        if (!_ready) const Center(child: StreamSpinner()),
      ],
    );
  }
}

class _Backdrop extends StatelessWidget {
  const _Backdrop({required this.url, required this.visible});

  final String? url;
  final bool visible;

  @override
  Widget build(BuildContext context) {
    final address = url;
    if (!visible || address == null || address.isEmpty) {
      return const SizedBox.shrink();
    }
    return Opacity(
      opacity: 0.5,
      child: Image.network(
        address,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stack) => const SizedBox.shrink(),
      ),
    );
  }
}

class _Unavailable extends StatelessWidget {
  const _Unavailable({this.code});

  final Object? code;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return ColoredBox(
      color: const Color(0xFF000000),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(Spacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            spacing: Spacing.sm,
            children: [
              Text(
                'Trailer ini tidak bisa diputar di dalam aplikasi.',
                key: const Key('trailer-unavailable'),
                textAlign: TextAlign.center,
                style: theme.textTheme.muted,
              ),
              if (code != null)
                Text(
                  'Kode galat: $code',
                  key: const Key('trailer-error-code'),
                  style: theme.textTheme.small.copyWith(
                    color: theme.colorScheme.mutedForeground,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
