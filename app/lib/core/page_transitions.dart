import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import 'theme/kolektaku_tokens.dart';

enum PageMotion { slide, fade }

const _slideShift = 0.08;

Widget pageTransition(
  BuildContext context,
  Animation<double> animation,
  Widget child,
  PageMotion motion,
) {
  if (MediaQuery.disableAnimationsOf(context)) return child;
  final eased = CurvedAnimation(
    parent: animation,
    curve: Curves.easeOutCubic,
    reverseCurve: Curves.easeInCubic,
  );
  final faded = FadeTransition(opacity: eased, child: child);
  if (motion == PageMotion.fade) return faded;
  return SlideTransition(
    position: Tween<Offset>(
      begin: const Offset(_slideShift, 0),
      end: Offset.zero,
    ).animate(eased),
    child: faded,
  );
}

CustomTransitionPage<void> motionPage({
  required GoRouterState state,
  required Widget child,
  PageMotion motion = PageMotion.slide,
}) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: Motion.regular,
    reverseTransitionDuration: Motion.quick,
    transitionsBuilder: (context, animation, secondary, page) =>
        pageTransition(context, animation, page, motion),
  );
}
