import 'package:flutter/widgets.dart';

import '../../core/theme/kolektaku_color_scheme.dart';
import 'cat_tv_splash.dart';

typedef BootStep = Future<void> Function();

const minimumSplash = Duration(milliseconds: 1500);
const _fade = Duration(milliseconds: 350);

class KolektakuBoot extends StatefulWidget {
  const KolektakuBoot({
    super.key,
    required this.init,
    required this.app,
    this.minimum = minimumSplash,
  });

  final BootStep init;
  final WidgetBuilder app;
  final Duration minimum;

  @override
  State<KolektakuBoot> createState() => _KolektakuBootState();
}

class _KolektakuBootState extends State<KolektakuBoot> {
  bool _done = false;
  Object? _error;
  int _attempt = 0;

  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    final attempt = ++_attempt;
    final reduced = WidgetsBinding
        .instance
        .platformDispatcher
        .accessibilityFeatures
        .disableAnimations;
    try {
      await Future.wait([
        widget.init(),
        Future<void>.delayed(reduced ? Duration.zero : widget.minimum),
      ]);
      if (mounted && attempt == _attempt) setState(() => _done = true);
    } on Object catch (error) {
      if (mounted && attempt == _attempt) setState(() => _error = error);
    }
  }

  void _retry() {
    setState(() => _error = null);
    _start();
  }

  @override
  Widget build(BuildContext context) {
    if (_done) return AnimatedBoot(child: widget.app(context));
    return Directionality(
      textDirection: TextDirection.ltr,
      child: MediaQuery.fromView(
        view: View.of(context),
        child: _error == null
            ? const CatTvSplash()
            : BootFailure(onRetry: _retry),
      ),
    );
  }
}

class AnimatedBoot extends StatefulWidget {
  const AnimatedBoot({super.key, required this.child});

  final Widget child;

  @override
  State<AnimatedBoot> createState() => _AnimatedBootState();
}

class _AnimatedBootState extends State<AnimatedBoot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _in = AnimationController(
    vsync: this,
    duration: _fade,
  )..forward();

  @override
  void dispose() {
    _in.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(opacity: _in, child: widget.child);
  }
}

class BootFailure extends StatelessWidget {
  const BootFailure({super.key, required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    const style = TextStyle(
      color: Color(0xFFF3F1EC),
      fontSize: 16,
      decoration: TextDecoration.none,
    );
    return ColoredBox(
      color: kolektakuDarkColorScheme.background,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: 20,
          children: [
            const Text(
              'Aplikasi belum bisa dimulai.',
              key: Key('boot-failed'),
              style: style,
            ),
            GestureDetector(
              key: const Key('boot-retry'),
              onTap: onRetry,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: kolektakuDarkColorScheme.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  child: Text(
                    'Coba lagi',
                    style: TextStyle(
                      color: Color(0xFF16130A),
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      decoration: TextDecoration.none,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
