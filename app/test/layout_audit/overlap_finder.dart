import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kolektaku/widgets/pressable.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

const _tolerance = 2.0;

bool _isTarget(Widget widget) =>
    widget is Pressable || widget is ShadButton || widget is ShadIconButton;

bool _isAncestor(Element ancestor, Element descendant) {
  var found = false;
  descendant.visitAncestorElements((element) {
    if (identical(element, ancestor)) {
      found = true;
      return false;
    }
    return true;
  });
  return found;
}

bool _clips(RenderObject object) =>
    object is RenderAbstractViewport || object is RenderClipRect;

Rect _clippedByParents(RenderBox box, Rect rect) {
  var clipped = rect;
  RenderObject? parent = box.parent;
  while (parent != null) {
    if (parent is RenderBox && parent.hasSize && _clips(parent)) {
      final bounds = parent.localToGlobal(Offset.zero) & parent.size;
      clipped = clipped.intersect(bounds);
    }
    parent = parent.parent;
  }
  return clipped;
}

Rect? _visibleRect(Element element, Size screen) {
  final object = element.renderObject;
  if (object is! RenderBox || !object.hasSize || !object.attached) return null;
  final rect = object.localToGlobal(Offset.zero) & object.size;
  final onScreen = _clippedByParents(
    object,
    rect,
  ).intersect(Offset.zero & screen);
  if (onScreen.isEmpty || onScreen.width < 1 || onScreen.height < 1) {
    return null;
  }
  return onScreen;
}

String _describe(Element element) {
  final key = element.widget.key;
  return key == null ? element.widget.runtimeType.toString() : '$key';
}

List<String> overlappingTargets(WidgetTester tester) {
  final screen = tester.view.physicalSize / tester.view.devicePixelRatio;
  final targets = find
      .byWidgetPredicate(_isTarget)
      .evaluate()
      .map((element) => (element, _visibleRect(element, screen)))
      .where((entry) => entry.$2 != null)
      .toList();
  final problems = <String>[];
  for (var i = 0; i < targets.length; i++) {
    for (var j = i + 1; j < targets.length; j++) {
      final (first, firstRect) = targets[i];
      final (second, secondRect) = targets[j];
      if (_isAncestor(first, second) || _isAncestor(second, first)) continue;
      final shared = firstRect!.intersect(secondRect!);
      if (shared.width > _tolerance && shared.height > _tolerance) {
        problems.add(
          '${_describe(first)} menimpa ${_describe(second)} '
          '(${shared.width.round()}x${shared.height.round()})',
        );
      }
    }
  }
  return problems;
}
