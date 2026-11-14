import 'dart:math' as math;

import 'package:flutter/widgets.dart';

const maxReaderZoom = 3.0;
const _snapBelow = 1.08;
const _decodeSteps = [1.0, 1.5, 2.0, maxReaderZoom];

class ReaderZoom extends ChangeNotifier {
  double zoom = 1;
  double pan = 0;
  bool pinching = false;

  bool get zoomed => zoom > 1;

  double widthOf(double screen) => screen * zoom;

  double get decodeScale => _decodeSteps.firstWhere(
    (step) => zoom <= step,
    orElse: () => maxReaderZoom,
  );

  double _clampPan(double value, double screen) =>
      value.clamp(-(screen * zoom - screen), 0.0).toDouble();

  void setZoom(double value, double screen) {
    zoom = value.clamp(1.0, maxReaderZoom).toDouble();
    pan = _clampPan(pan, screen);
    notifyListeners();
  }

  void panBy(double dx, double screen) {
    if (!zoomed) return;
    final next = _clampPan(pan + dx, screen);
    if (next == pan) return;
    pan = next;
    notifyListeners();
  }

  void startPinch() {
    pinching = true;
    notifyListeners();
  }

  void endPinch(double screen) {
    pinching = false;
    if (zoom < _snapBelow) zoom = 1;
    pan = _clampPan(pan, screen);
    notifyListeners();
  }

  void reset() {
    zoom = 1;
    pan = 0;
    pinching = false;
    notifyListeners();
  }
}

class ZoomSurface extends StatefulWidget {
  const ZoomSurface({super.key, required this.model, required this.builder});

  final ReaderZoom model;
  final Widget Function(BuildContext context, double width) builder;

  @override
  State<ZoomSurface> createState() => _ZoomSurfaceState();
}

class _ZoomSurfaceState extends State<ZoomSurface> {
  final Map<int, Offset> _touches = {};
  double _startDistance = 0;
  double _startZoom = 1;

  double get _screen => MediaQuery.sizeOf(context).width;

  double _distance() {
    final points = _touches.values.toList();
    return (points[0] - points[1]).distance;
  }

  void _down(PointerDownEvent event) {
    _touches[event.pointer] = event.position;
    if (_touches.length != 2) return;
    _startDistance = math.max(_distance(), 1);
    _startZoom = widget.model.zoom;
    widget.model.startPinch();
  }

  void _move(PointerMoveEvent event) {
    final before = _touches[event.pointer];
    if (before == null) return;
    _touches[event.pointer] = event.position;
    if (_touches.length == 2) {
      widget.model.setZoom(_startZoom * _distance() / _startDistance, _screen);
    } else if (_touches.length == 1) {
      widget.model.panBy(event.position.dx - before.dx, _screen);
    }
  }

  void _up(PointerEvent event) {
    final wasPinching = _touches.length >= 2;
    _touches.remove(event.pointer);
    if (wasPinching && _touches.length < 2) widget.model.endPinch(_screen);
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: _down,
      onPointerMove: _move,
      onPointerUp: _up,
      onPointerCancel: _up,
      child: ListenableBuilder(
        listenable: widget.model,
        builder: (context, child) {
          final width = widget.model.widthOf(_screen);
          return ClipRect(
            child: OverflowBox(
              alignment: Alignment.topLeft,
              minWidth: width,
              maxWidth: width,
              child: Transform.translate(
                offset: Offset(widget.model.pan, 0),
                child: widget.builder(context, width),
              ),
            ),
          );
        },
      ),
    );
  }
}
