import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// A freehand drawing surface: pen-only strokes, with clear/undo, and the
/// ability to rasterize the current drawing to PNG bytes for upload.
class DrawingCanvas extends StatefulWidget {
  const DrawingCanvas({super.key, required this.controller});

  final DrawingCanvasController controller;

  @override
  State<DrawingCanvas> createState() => _DrawingCanvasState();
}

class _DrawingCanvasState extends State<DrawingCanvas> {
  final GlobalKey _boundaryKey = GlobalKey();
  final List<List<Offset>> _strokes = [];
  List<Offset>? _currentStroke;

  @override
  void initState() {
    super.initState();
    widget.controller._attach(this);
  }

  @override
  void dispose() {
    widget.controller._detach(this);
    super.dispose();
  }

  void _clear() {
    setState(() {
      _strokes.clear();
      _currentStroke = null;
    });
  }

  void _undo() {
    if (_strokes.isEmpty) return;
    setState(() => _strokes.removeLast());
  }

  bool get _isEmpty => _strokes.isEmpty;

  Future<Uint8List?> _captureImage() async {
    if (_isEmpty) return null;
    final boundary =
        _boundaryKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) return null;

    final image = await boundary.toImage(pixelRatio: 2.0);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData?.buffer.asUint8List();
  }

  void _onPanStart(DragStartDetails details) {
    setState(() {
      _currentStroke = [details.localPosition];
      _strokes.add(_currentStroke!);
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    setState(() => _currentStroke?.add(details.localPosition));
  }

  void _onPanEnd(DragEndDetails details) {
    _currentStroke = null;
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      key: _boundaryKey,
      child: Container(
        color: Colors.white,
        child: GestureDetector(
          onPanStart: _onPanStart,
          onPanUpdate: _onPanUpdate,
          onPanEnd: _onPanEnd,
          child: CustomPaint(
            painter: _StrokesPainter(_strokes),
            size: Size.infinite,
          ),
        ),
      ),
    );
  }
}

class _StrokesPainter extends CustomPainter {
  _StrokesPainter(this.strokes);

  final List<List<Offset>> strokes;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6;

    for (final stroke in strokes) {
      if (stroke.length < 2) {
        if (stroke.isNotEmpty) {
          canvas.drawPoints(ui.PointMode.points, stroke, paint..strokeWidth = 6);
        }
        continue;
      }
      final path = Path()..moveTo(stroke.first.dx, stroke.first.dy);
      for (final point in stroke.skip(1)) {
        path.lineTo(point.dx, point.dy);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _StrokesPainter oldDelegate) => true;
}

/// Lets a parent widget (e.g. the Next/Clear/Undo buttons) drive a
/// [DrawingCanvas] without lifting the stroke state up itself.
class DrawingCanvasController {
  _DrawingCanvasState? _state;

  void _attach(_DrawingCanvasState state) => _state = state;

  void _detach(_DrawingCanvasState state) {
    if (_state == state) _state = null;
  }

  bool get isEmpty => _state?._isEmpty ?? true;

  void clear() => _state?._clear();

  void undo() => _state?._undo();

  Future<Uint8List?> captureImage() => _state?._captureImage() ?? Future.value(null);
}
