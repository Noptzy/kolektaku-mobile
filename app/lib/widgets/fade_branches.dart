import 'package:flutter/widgets.dart';

import '../core/theme/kolektaku_tokens.dart';

class FadeBranches extends StatefulWidget {
  const FadeBranches({super.key, required this.index, required this.children});

  final int index;
  final List<Widget> children;

  @override
  State<FadeBranches> createState() => _FadeBranchesState();
}

class _FadeBranchesState extends State<FadeBranches>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fade = AnimationController(
    vsync: this,
    duration: Motion.regular,
    value: 1,
  );
  late int _previous = widget.index;

  @override
  void didUpdateWidget(FadeBranches old) {
    super.didUpdateWidget(old);
    if (old.index == widget.index) return;
    _previous = old.index;
    if (MediaQuery.disableAnimationsOf(context)) {
      _fade.value = 1;
    } else {
      _fade.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _fade.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _fade,
      builder: (context, child) {
        final settling = _fade.value < 1;
        return Stack(
          fit: StackFit.expand,
          children: [
            for (var i = 0; i < widget.children.length; i++)
              _branch(i, settling),
          ],
        );
      },
    );
  }

  Widget _branch(int i, bool settling) {
    final current = i == widget.index;
    final leaving = settling && i == _previous && !current;
    return Offstage(
      offstage: !current && !leaving,
      child: TickerMode(
        enabled: current,
        child: IgnorePointer(
          ignoring: !current,
          child: Opacity(
            opacity: current
                ? Curves.easeOut.transform(_fade.value)
                : 1 - _fade.value,
            child: widget.children[i],
          ),
        ),
      ),
    );
  }
}
