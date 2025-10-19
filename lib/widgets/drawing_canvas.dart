import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'package:flutter/gestures.dart';
import '../managers/drawing_tools_manager.dart';
import '../models/drawing_point.dart';
import '../utils/flood_fill.dart';

class DrawingCanvas extends StatefulWidget {
  final List<DrawingPoint> points;
  final ui.Image? backgroundImage;
  final DrawingToolManager toolManager;
  final ValueChanged<DrawingPoint> onDrawingStart;
  final ValueChanged<DrawingPoint> onDrawingUpdate;
  final VoidCallback onDrawingEnd;
  final ValueChanged<Offset> onCanvasTap;
  final double zoomLevel;
  final Offset panOffset;
  final bool showGrid;
  final Color gridColor;
  final double gridSize;

  const DrawingCanvas({
    Key? key,
    required this.points,
    this.backgroundImage,
    required this.toolManager,
    required this.onDrawingStart,
    required this.onDrawingUpdate,
    required this.onDrawingEnd,
    required this.onCanvasTap,
    this.zoomLevel = 1.0,
    this.panOffset = Offset.zero,
    this.showGrid = false,
    this.gridColor = const Color(0x20000000),
    this.gridSize = 20.0,
  }) : super(key: key);

  @override
  _DrawingCanvasState createState() => _DrawingCanvasState();
}

class _DrawingCanvasState extends State<DrawingCanvas> {
  // Canvas state
  final List<DrawingPoint> _currentStroke = [];
  late ui.Image _currentImage;
  bool _isDrawing = false;
  Offset? _lastPoint;
  DateTime? _lastRenderTime;
  double _fps = 60.0;

  // Performance optimization
  final Map<BrushType, Paint> _brushPaints = {};
  final Map<Color, Paint> _colorPaints = {};
  bool _needsRedraw = true;
  ui.Picture? _cachedPicture;

  // Gesture recognition
  late ScaleGestureRecognizer _scaleRecognizer;
  late TapGestureRecognizer _tapRecognizer;
  late LongPressGestureRecognizer _longPressRecognizer;

  @override
  void initState() {
    super.initState();
    _initializeGestureRecognizers();
    _initializePaints();
    _initializeCanvas();
  }

  void _initializeGestureRecognizers() {
    _scaleRecognizer = ScaleGestureRecognizer();
    _tapRecognizer = TapGestureRecognizer();
    _longPressRecognizer = LongPressGestureRecognizer();

    _tapRecognizer.onTap = _handleTap;
    _longPressRecognizer.onLongPress = _handleLongPress;
  }

  void _initializePaints() {
    // Initialize paint cache for better performance
    _updatePaints();
  }

  void _initializeCanvas() {
    // Initialize canvas with default size
    _createBlankImage(800, 600).then((image) {
      setState(() {
        _currentImage = image;
      });
    });
  }

  Future<ui.Image> _createBlankImage(int width, int height) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    // Draw white background
    canvas.drawRect(
      Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
      Paint()..color = Colors.white,
    );

    final picture = recorder.endRecording();
    return await picture.toImage(width, height);
  }

  void _updatePaints() {
    // Update paints when tool or color changes
    _brushPaints.clear();
    _colorPaints.clear();
  }

  Paint _getPaintForPoint(DrawingPoint point) {
    final colorKey = point.color.value;

    if (!_colorPaints.containsKey(colorKey)) {
      _colorPaints[colorKey] = Paint()
        ..color = point.color
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..isAntiAlias = true
        ..style = PaintingStyle.stroke;
    }

    final paint = _colorPaints[colorKey]!;
    paint.strokeWidth = point.size * widget.zoomLevel;

    // Apply brush type effects
    switch (point.tool) {
      case DrawingTool.eraser:
        paint.blendMode = BlendMode.clear;
        paint.color = Colors.transparent;
        break;
      case DrawingTool.brush:
        paint.blendMode = BlendMode.srcOver;
        _applyBrushEffects(paint, point);
        break;
      case DrawingTool.fill:
        paint.blendMode = BlendMode.srcOver;
        break;
      case DrawingTool.shapes:
        paint.blendMode = BlendMode.srcOver;
        break;
      case DrawingTool.text:
        paint.blendMode = BlendMode.srcOver;
        break;
      default:
        paint.blendMode = BlendMode.srcOver;
    }

    return paint;
  }

  void _applyBrushEffects(Paint paint, DrawingPoint point) {
    switch (widget.toolManager.selectedBrush) {
      case BrushType.normal:
        paint.maskFilter = null;
        paint.shader = null;
        break;
      case BrushType.calligraphy:
        paint.strokeCap = StrokeCap.square;
        paint.strokeJoin = StrokeJoin.bevel;
        break;
      case BrushType.airbrush:
        paint.maskFilter = MaskFilter.blur(BlurStyle.normal, point.size * 0.3);
        break;
      case BrushType.charcoal:
        paint.maskFilter = MaskFilter.blur(BlurStyle.solid, point.size * 0.1);
        paint.color = paint.color.withOpacity(0.8);
        break;
      case BrushType.watercolor:
        paint.maskFilter = MaskFilter.blur(BlurStyle.normal, point.size * 0.2);
        paint.color = paint.color.withOpacity(0.7);
        break;
    }
  }

  void _handleTap() {
    if (widget.toolManager.currentTool == DrawingTool.fill ||
        widget.toolManager.currentTool == DrawingTool.shapes ||
        widget.toolManager.currentTool == DrawingTool.text) {
      // Convert tap position to canvas coordinates
      final renderBox = context.findRenderObject() as RenderBox;
      final localPosition = renderBox.globalToLocal(_tapRecognizer.position);
      widget.onCanvasTap(localPosition);
    }
  }

  void _handleLongPress() {
    // Show context menu or tool options
    _showContextMenu(_longPressRecognizer.position);
  }

  void _showContextMenu(Offset position) {
    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy,
        MediaQuery.of(context).size.width - position.dx,
        MediaQuery.of(context).size.height - position.dy,
      ),
      items: [
        PopupMenuItem(
          child: ListTile(
            leading: Icon(Icons.undo),
            title: Text('Undo'),
          ),
          value: 'undo',
        ),
        PopupMenuItem(
          child: ListTile(
            leading: Icon(Icons.clear),
            title: Text('Clear Canvas'),
          ),
          value: 'clear',
        ),
        PopupMenuItem(
          child: ListTile(
            leading: Icon(Icons.save),
            title: Text('Save Snapshot'),
          ),
          value: 'save',
        ),
      ],
    ).then((value) {
      if (value != null) {
        _handleContextMenuAction(value);
      }
    });
  }

  void _handleContextMenuAction(String action) {
    switch (action) {
      case 'undo':
      // Handle undo
        break;
      case 'clear':
      // Handle clear
        break;
      case 'save':
      // Handle save
        break;
    }
  }

  void _onPanStart(DragStartDetails details) {
    if (widget.toolManager.currentTool == DrawingTool.brush ||
        widget.toolManager.currentTool == DrawingTool.eraser) {
      setState(() {
        _isDrawing = true;
        _lastPoint = details.localPosition;

        final point = DrawingPoint(
          offset: details.localPosition,
          color: widget.toolManager.currentColor,
          size: widget.toolManager.brushSize,
          tool: widget.toolManager.currentTool,
          pressure: 1.0,
          timestamp: DateTime.now(),
        );

        _currentStroke.add(point);
        widget.onDrawingStart(point);
      });
    }
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (_isDrawing && _lastPoint != null) {
      final now = DateTime.now();

      // Throttle updates for performance
      if (_lastRenderTime == null ||
          now.difference(_lastRenderTime!).inMilliseconds > (1000 / _fps).round()) {

        setState(() {
          final newPoint = DrawingPoint(
            offset: details.localPosition,
            color: widget.toolManager.currentColor,
            size: widget.toolManager.brushSize,
            tool: widget.toolManager.currentTool,
            pressure: _calculatePressure(details),
            timestamp: now,
          );

          _currentStroke.add(newPoint);
          widget.onDrawingUpdate(newPoint);

          _lastPoint = details.localPosition;
          _lastRenderTime = now;
          _needsRedraw = true;
        });
      }
    }
  }

  void _onPanEnd(DragEndDetails details) {
    if (_isDrawing) {
      setState(() {
        _isDrawing = false;
        _currentStroke.clear();
        _lastPoint = null;
        widget.onDrawingEnd();
        _needsRedraw = true;
      });
    }
  }

  double _calculatePressure(DragUpdateDetails details) {
    if (!widget.toolManager.pressureSensitive) {
      return 1.0;
    }

    // Simulate pressure based on speed or other factors
    // In a real implementation, you might get actual pressure from stylus
    final speed = details.primaryDelta?.distance ?? 1.0;
    return (1.0 / speed).clamp(0.3, 1.0);
  }

  void _drawBackground(Canvas canvas, Size size) {
    // Draw white background
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = Colors.white,
    );

    // Draw grid if enabled
    if (widget.showGrid) {
      _drawGrid(canvas, size);
    }

    // Draw background image if available
    if (widget.backgroundImage != null) {
      _drawBackgroundImage(canvas, size);
    }
  }

  void _drawGrid(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = widget.gridColor
      ..strokeWidth = 1.0;

    final gridSize = widget.gridSize * widget.zoomLevel;

    // Draw vertical lines
    for (double x = 0; x < size.width; x += gridSize) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    // Draw horizontal lines
    for (double y = 0; y < size.height; y += gridSize) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  void _drawBackgroundImage(Canvas canvas, Size size) {
    if (widget.backgroundImage != null) {
      canvas.drawImage(
        widget.backgroundImage!,
        Offset.zero,
        Paint()..filterQuality = FilterQuality.high,
      );
    }
  }

  void _drawPoints(Canvas canvas, List<DrawingPoint> points) {
    if (points.isEmpty) return;

    // Group points by tool and color for better performance
    final groupedPoints = <String, List<DrawingPoint>>{};

    for (final point in points) {
      final key = '${point.tool}_${point.color.value}';
      if (!groupedPoints.containsKey(key)) {
        groupedPoints[key] = [];
      }
      groupedPoints[key]!.add(point);
    }

    // Draw each group with optimized paint settings
    groupedPoints.forEach((key, groupPoints) {
      if (groupPoints.isNotEmpty) {
        _drawPointGroup(canvas, groupPoints);
      }
    });
  }

  void _drawPointGroup(Canvas canvas, List<DrawingPoint> points) {
    if (points.length == 1) {
      // Single point
      final point = points.first;
      final paint = _getPaintForPoint(point);
      canvas.drawPoints(ui.PointMode.points, [point.offset], paint);
    } else {
      // Multiple points - draw as connected lines
      _drawSmoothLines(canvas, points);
    }
  }

  void _drawSmoothLines(Canvas canvas, List<DrawingPoint> points) {
    if (points.length < 2) return;

    final path = Path();
    path.moveTo(points.first.offset.dx, points.first.offset.dy);

    for (int i = 1; i < points.length - 1; i++) {
      final p0 = points[i - 1].offset;
      final p1 = points[i].offset;
      final p2 = points[i + 1].offset;

      // Calculate control points for smooth curve
      final control1 = Offset(
        p1.dx + (p2.dx - p0.dx) * widget.toolManager.smoothness * 0.16,
        p1.dy + (p2.dy - p0.dy) * widget.toolManager.smoothness * 0.16,
      );

      final control2 = Offset(
        p2.dx - (p2.dx - p0.dx) * widget.toolManager.smoothness * 0.16,
        p2.dy - (p2.dy - p0.dy) * widget.toolManager.smoothness * 0.16,
      );

      path.cubicTo(control1.dx, control1.dy, control2.dx, control2.dy, p2.dx, p2.dy);
    }

    final paint = _getPaintForPoint(points.first);
    canvas.drawPath(path, paint);
  }

  void _drawCurrentStroke(Canvas canvas) {
    if (_currentStroke.isNotEmpty) {
      _drawPoints(canvas, _currentStroke);
    }
  }

  void _drawShapes(Canvas canvas, List<DrawingPoint> points) {
    final shapePoints = points.where((point) => point.tool == DrawingTool.shapes).toList();

    for (final point in shapePoints) {
      _drawShape(canvas, point);
    }
  }

  void _drawShape(Canvas canvas, DrawingPoint point) {
    final paint = _getPaintForPoint(point);

    // This is a simplified implementation
    // In a real app, you'd have more sophisticated shape drawing
    canvas.drawCircle(
      point.offset,
      point.size,
      paint,
    );
  }

  void _drawText(Canvas canvas, List<DrawingPoint> points) {
    final textPoints = points.where((point) => point.tool == DrawingTool.text && point.text != null).toList();

    for (final point in textPoints) {
      _drawTextAtPoint(canvas, point);
    }
  }

  void _drawTextAtPoint(Canvas canvas, DrawingPoint point) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: point.text,
        style: TextStyle(
          color: point.color,
          fontSize: point.size,
          fontFamily: 'Arial',
        ),
      ),
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();
    textPainter.paint(canvas, point.offset);
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (details) => _onPanStart(DragStartDetails(
        localPosition: details.localPosition,
        globalPosition: details.position,
      )),
      onPointerMove: (details) => _onPanUpdate(DragUpdateDetails(
        localPosition: details.localPosition,
        globalPosition: details.position,
        primaryDelta: details.delta,
      )),
      onPointerUp: (details) => _onPanEnd(DragEndDetails()),
      onPointerCancel: (details) => _onPanEnd(DragEndDetails()),
      child: CustomPaint(
        size: Size.infinite,
        painter: _DrawingCanvasPainter(
          points: widget.points,
          backgroundImage: widget.backgroundImage,
          currentStroke: _currentStroke,
          toolManager: widget.toolManager,
          showGrid: widget.showGrid,
          gridColor: widget.gridColor,
          gridSize: widget.gridSize,
          zoomLevel: widget.zoomLevel,
          panOffset: widget.panOffset,
          needsRedraw: _needsRedraw,
          onRedrawComplete: () {
            _needsRedraw = false;
          },
          drawBackground: _drawBackground,
          drawPoints: _drawPoints,
          drawCurrentStroke: _drawCurrentStroke,
          drawShapes: _drawShapes,
          drawText: _drawText,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _scaleRecognizer.dispose();
    _tapRecognizer.dispose();
    _longPressRecognizer.dispose();
    super.dispose();
  }
}

class _DrawingCanvasPainter extends CustomPainter {
  final List<DrawingPoint> points;
  final ui.Image? backgroundImage;
  final List<DrawingPoint> currentStroke;
  final DrawingToolManager toolManager;
  final bool showGrid;
  final Color gridColor;
  final double gridSize;
  final double zoomLevel;
  final Offset panOffset;
  final bool needsRedraw;
  final VoidCallback onRedrawComplete;
  final Function(Canvas, Size) drawBackground;
  final Function(Canvas, List<DrawingPoint>) drawPoints;
  final Function(Canvas) drawCurrentStroke;
  final Function(Canvas, List<DrawingPoint>) drawShapes;
  final Function(Canvas, List<DrawingPoint>) drawText;

  _DrawingCanvasPainter({
    required this.points,
    required this.backgroundImage,
    required this.currentStroke,
    required this.toolManager,
    required this.showGrid,
    required this.gridColor,
    required this.gridSize,
    required this.zoomLevel,
    required this.panOffset,
    required this.needsRedraw,
    required this.onRedrawComplete,
    required this.drawBackground,
    required this.drawPoints,
    required this.drawCurrentStroke,
    required this.drawShapes,
    required this.drawText,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Apply zoom and pan transformations
    canvas.save();
    canvas.translate(panOffset.dx, panOffset.dy);
    canvas.scale(zoomLevel);

    // Draw background
    drawBackground(canvas, size);

    // Draw existing points
    drawPoints(canvas, points);

    // Draw shapes
    drawShapes(canvas, points);

    // Draw text
    drawText(canvas, points);

    // Draw current stroke (in progress)
    drawCurrentStroke(canvas);

    canvas.restore();

    // Notify that redraw is complete
    onRedrawComplete();
  }

  @override
  bool shouldRepaint(_DrawingCanvasPainter oldDelegate) {
    return needsRedraw ||
        points != oldDelegate.points ||
        currentStroke != oldDelegate.currentStroke ||
        toolManager != oldDelegate.toolManager ||
        zoomLevel != oldDelegate.zoomLevel ||
        panOffset != oldDelegate.panOffset ||
        showGrid != oldDelegate.showGrid;
  }
}