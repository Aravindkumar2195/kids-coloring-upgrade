import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import '../models/drawing_point.dart';
import '../utils/flood_fill.dart';

class DrawingCanvas extends StatefulWidget {
  const DrawingCanvas({Key? key}) : super(key: key);

  @override
  DrawingCanvasState createState() => DrawingCanvasState();
}

class DrawingCanvasState extends State<DrawingCanvas> {
  final GlobalKey _repaintKey = GlobalKey();

  List<DrawingPoint> drawingPoints = [];
  Color selectedColor = Colors.black;
  double strokeWidth = 3.0;
  DrawingType currentTool = DrawingType.pen;
  Offset? shapeStart;
  Offset? shapeEnd;
  bool isShapeFilled = false;

  void _onPanStart(DragStartDetails details) {
    if (currentTool == DrawingType.fill) {
      _performFloodFill(details.localPosition);
      return;
    }

    if (_isShapeTool()) {
      shapeStart = details.localPosition;
      shapeEnd = details.localPosition;
      return;
    }

    setState(() {
      drawingPoints.add(DrawingPoint(
        points: [details.localPosition],
        color: currentTool == DrawingType.eraser ? Colors.white : selectedColor,
        strokeWidth: currentTool == DrawingType.eraser ? strokeWidth * 2 : strokeWidth,
        type: currentTool,
      ));
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (currentTool == DrawingType.fill) return;

    if (_isShapeTool()) {
      setState(() {
        shapeEnd = details.localPosition;
      });
      return;
    }

    setState(() {
      drawingPoints.last.points.add(details.localPosition);
    });
  }

  void _onPanEnd(DragEndDetails details) {
    if (currentTool == DrawingType.fill) return;

    if (_isShapeTool() && shapeStart != null && shapeEnd != null) {
      _addShapeToDrawing();
      return;
    }

    setState(() {
      drawingPoints.add(DrawingPoint(
        points: [],
        color: currentTool == DrawingType.eraser ? Colors.white : selectedColor,
        strokeWidth: currentTool == DrawingType.eraser ? strokeWidth * 2 : strokeWidth,
        type: currentTool,
      ));
    });
  }

  bool _isShapeTool() {
    return currentTool == DrawingType.circle ||
        currentTool == DrawingType.rectangle ||
        currentTool == DrawingType.line;
  }

  void _addShapeToDrawing() {
    if (shapeStart == null || shapeEnd == null) return;

    final rect = Rect.fromPoints(shapeStart!, shapeEnd!);

    setState(() {
      drawingPoints.add(DrawingPoint(
        points: [shapeStart!, shapeEnd!],
        color: selectedColor,
        strokeWidth: strokeWidth,
        type: currentTool,
        shapeRect: rect,
        isFill: isShapeFilled,
      ));

      shapeStart = null;
      shapeEnd = null;
    });
  }

  Future<void> _performFloodFill(Offset position) async {
    try {
      final RenderRepaintBoundary boundary =
      _repaintKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final ui.Image image = await boundary.toImage();

      final List<Offset> filledPixels = await FloodFill.performFloodFill(
        image: image,
        startPoint: position,
        targetColor: Colors.white,
        replacementColor: selectedColor,
        tolerance: 20,
      );

      if (filledPixels.isNotEmpty) {
        setState(() {
          drawingPoints.add(DrawingPoint(
            points: filledPixels,
            color: selectedColor,
            strokeWidth: 1.0,
            type: DrawingType.fill,
          ));
        });
      } else {
        // Fallback: draw a dot
        setState(() {
          drawingPoints.add(DrawingPoint(
            points: [position],
            color: selectedColor,
            strokeWidth: 20.0,
            type: DrawingType.pen,
          ));
        });
      }
    } catch (e) {
      // Fallback: draw a dot
      setState(() {
        drawingPoints.add(DrawingPoint(
          points: [position],
          color: selectedColor,
          strokeWidth: 20.0,
          type: DrawingType.pen,
        ));
      });
    }
  }

  void clearCanvas() {
    setState(() {
      drawingPoints.clear();
      shapeStart = null;
      shapeEnd = null;
    });
  }

  void undo() {
    setState(() {
      if (drawingPoints.isNotEmpty) {
        drawingPoints.removeLast();
      }
    });
  }

  void setTool(DrawingType tool) {
    setState(() {
      currentTool = tool;
      shapeStart = null;
      shapeEnd = null;
    });
  }

  void toggleShapeFill() {
    setState(() {
      isShapeFilled = !isShapeFilled;
    });
  }

  GlobalKey get repaintKey => _repaintKey;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      key: _repaintKey,
      child: Stack(
        children: [
          Container(color: Colors.white),
          GestureDetector(
            onPanStart: _onPanStart,
            onPanUpdate: _onPanUpdate,
            onPanEnd: _onPanEnd,
            child: CustomPaint(
              painter: _DrawingPainter(
                drawingPoints,
                shapeStart: shapeStart,
                shapeEnd: shapeEnd,
                currentTool: currentTool,
                currentColor: selectedColor,
                strokeWidth: strokeWidth,
                isShapeFilled: isShapeFilled,
              ),
              size: Size.infinite,
            ),
          ),
        ],
      ),
    );
  }
}

class _DrawingPainter extends CustomPainter {
  final List<DrawingPoint> drawingPoints;
  final Offset? shapeStart;
  final Offset? shapeEnd;
  final DrawingType currentTool;
  final Color currentColor;
  final double strokeWidth;
  final bool isShapeFilled;

  _DrawingPainter(
      this.drawingPoints, {
        this.shapeStart,
        this.shapeEnd,
        required this.currentTool,
        required this.currentColor,
        required this.strokeWidth,
        required this.isShapeFilled,
      });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw completed drawings
    for (var point in drawingPoints) {
      _drawPoint(canvas, point);
    }

    // Draw current preview shape
    if (shapeStart != null && shapeEnd != null) {
      _drawPreviewShape(canvas);
    }
  }

  void _drawPoint(Canvas canvas, DrawingPoint point) {
    final paint = Paint()
      ..color = point.color
      ..strokeWidth = point.strokeWidth
      ..strokeCap = StrokeCap.round;

    switch (point.type) {
      case DrawingType.pen:
      case DrawingType.eraser:
      case DrawingType.fill:
        paint.style = point.type == DrawingType.fill ?
        PaintingStyle.fill : PaintingStyle.stroke;

        if (point.type == DrawingType.fill) {
          for (final pixel in point.points) {
            canvas.drawCircle(pixel, point.strokeWidth / 2, paint);
          }
        } else {
          for (int i = 0; i < point.points.length - 1; i++) {
            if (point.points[i] != null && point.points[i + 1] != null) {
              canvas.drawLine(point.points[i], point.points[i + 1], paint);
            }
          }
        }
        break;

      case DrawingType.circle:
        paint.style = point.isFill ? PaintingStyle.fill : PaintingStyle.stroke;
        if (point.shapeRect != null) {
          final center = point.shapeRect!.center;
          final radius = point.shapeRect!.width.abs() / 2;
          canvas.drawCircle(center, radius, paint);
        }
        break;

      case DrawingType.rectangle:
        paint.style = point.isFill ? PaintingStyle.fill : PaintingStyle.stroke;
        if (point.shapeRect != null) {
          canvas.drawRect(point.shapeRect!, paint);
        }
        break;

      case DrawingType.line:
        paint.style = PaintingStyle.stroke;
        if (point.points.length >= 2) {
          canvas.drawLine(point.points[0], point.points[1], paint);
        }
        break;
    }
  }

  void _drawPreviewShape(Canvas canvas) {
    final paint = Paint()
      ..color = currentColor.withOpacity(0.6)
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final rect = Rect.fromPoints(shapeStart!, shapeEnd!);

    switch (currentTool) {
      case DrawingType.circle:
        paint.style = isShapeFilled ? PaintingStyle.fill : PaintingStyle.stroke;
        final center = rect.center;
        final radius = rect.width.abs() / 2;
        canvas.drawCircle(center, radius, paint);
        break;

      case DrawingType.rectangle:
        paint.style = isShapeFilled ? PaintingStyle.fill : PaintingStyle.stroke;
        canvas.drawRect(rect, paint);
        break;

      case DrawingType.line:
        paint.style = PaintingStyle.stroke;
        canvas.drawLine(shapeStart!, shapeEnd!, paint);
        break;

      default:
        break;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}