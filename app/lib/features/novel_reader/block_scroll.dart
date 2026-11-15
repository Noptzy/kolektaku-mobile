import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

const _tries = 8;

RenderSliverMultiBoxAdaptor? _sliverIn(BuildContext? context) {
  RenderSliverMultiBoxAdaptor? found;
  void visit(RenderObject object) {
    if (found != null) return;
    if (object is RenderSliverMultiBoxAdaptor) {
      found = object;
      return;
    }
    object.visitChildren(visit);
  }

  context?.findRenderObject()?.visitChildren(visit);
  return found;
}

double _endOf(RenderSliverMultiBoxAdaptor sliver, RenderBox child) {
  return (sliver.childScrollOffset(child) ?? 0) + child.size.height;
}

int? firstVisibleBlock(BuildContext? context) {
  final sliver = _sliverIn(context);
  var child = sliver?.firstChild;
  while (sliver != null && child != null) {
    if (_endOf(sliver, child) > sliver.constraints.scrollOffset) {
      return sliver.indexOf(child);
    }
    child = sliver.childAfter(child);
  }
  return null;
}

double? _offsetOfBuilt(RenderSliverMultiBoxAdaptor sliver, int target) {
  var child = sliver.firstChild;
  while (child != null) {
    if (sliver.indexOf(child) == target) {
      return sliver.childScrollOffset(child);
    }
    child = sliver.childAfter(child);
  }
  return null;
}

double _estimate(RenderSliverMultiBoxAdaptor sliver, int target) {
  final first = sliver.firstChild;
  final last = sliver.lastChild;
  if (first == null || last == null) return 0;
  final built = sliver.indexOf(last) - sliver.indexOf(first) + 1;
  final span = _endOf(sliver, last) - (sliver.childScrollOffset(first) ?? 0);
  return span / built * target;
}

Future<void> jumpToBlock(
  ScrollController controller,
  BuildContext? Function() listContext,
  int target,
) async {
  for (var attempt = 0; attempt < _tries; attempt++) {
    if (!controller.hasClients) return;
    final sliver = _sliverIn(listContext());
    if (sliver == null) return;
    final exact = _offsetOfBuilt(sliver, target);
    final wanted = exact ?? _estimate(sliver, target);
    final position = controller.position;
    final start = sliver.constraints.precedingScrollExtent;
    controller.jumpTo((start + wanted).clamp(0.0, position.maxScrollExtent));
    if (exact != null) return;
    await WidgetsBinding.instance.endOfFrame;
  }
}
