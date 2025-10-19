import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'package:flutter/services.dart';
import '../managers/drawing_tools_manager.dart';
import '../utils/share_manager.dart';
import '../utils/drawing_history_manager.dart';
import '../utils/flood_fill.dart';
import '../widgets/drawing_canvas.dart';
import '../widgets/tool_palette.dart';
import '../widgets/custom_color_picker.dart';
import '../models/drawing_point.dart';
import '../models/saved_artwork.dart';

class FreeDrawScreen extends StatefulWidget {
  final SavedArtwork? existingArtwork;
  final ui.Image? backgroundImage;

  const FreeDrawScreen({
    Key? key,
    this.existingArtwork,
    this.backgroundImage,
  }) : super(key: key);

  @override
  _FreeDrawScreenState createState() => _FreeDrawScreenState();
}

class _FreeDrawScreenState extends State<FreeDrawScreen> with SingleTickerProviderStateMixin {
  // Core drawing state
  final List<DrawingPoint> _points = [];
  final List<List<DrawingPoint>> _layers = [];
  int _currentLayerIndex = 0;
  ui.Image? _currentImage;
  ui.Image? _backgroundImage;

  // Managers
  final DrawingToolManager _toolManager = DrawingToolManager();
  final List<DrawingState> _undoStack = [];
  final List<DrawingState> _redoStack = [];

  // UI state
  bool _isDrawing = false;
  bool _showColorPicker = false;
  bool _showLayersPanel = false;
  double _zoomLevel = 1.0;
  Offset _panOffset = Offset.zero;
  final GlobalKey _canvasKey = GlobalKey();

  // Animation controllers
  late AnimationController _zoomAnimationController;
  late AnimationController _panelAnimationController;

  @override
  void initState() {
    super.initState();

    _initializeAnimations();
    _loadExistingArtwork();
    _setupGestureRecognizers();
    _initializeLayers();
  }

  void _initializeAnimations() {
    _zoomAnimationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 300),
    );

    _panelAnimationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 250),
    );
  }

  void _loadExistingArtwork() {
    if (widget.existingArtwork != null) {
      // Load existing artwork data
      // This would involve decoding the saved drawing data
    }

    if (widget.backgroundImage != null) {
      _backgroundImage = widget.backgroundImage;
    }
  }

  void _initializeLayers() {
    _layers.add([]); // Main drawing layer
    // Add background layer if needed
    if (_backgroundImage != null) {
      _layers.insert(0, []);
    }
  }

  void _setupGestureRecognizers() {
    // Setup for zoom and pan gestures
  }

  // Drawing methods
  void _onDrawingStart(DrawingPoint point) {
    setState(() {
      _isDrawing = true;
      _saveCurrentState();
      _layers[_currentLayerIndex].add(point);
    });
  }

  void _onDrawingUpdate(DrawingPoint point) {
    if (_isDrawing) {
      setState(() {
        _layers[_currentLayerIndex].add(point);
      });
    }
  }

  void _onDrawingEnd() {
    setState(() {
      _isDrawing = false;
      _captureCurrentImage();
    });
  }

  void _onCanvasTap(Offset position) {
    if (_toolManager.currentTool == DrawingTool.fill) {
      _performFloodFill(position);
    } else if (_toolManager.currentTool == DrawingTool.shapes) {
      _drawShape(position);
    } else if (_toolManager.currentTool == DrawingTool.text) {
      _showTextInputDialog(position);
    }
  }

  void _performFloodFill(Offset position) async {
    try {
      final image = await _captureCurrentImage();
      if (image != null) {
        setState(() {
          _saveCurrentState();
        });

        final filledImage = await FloodFill.performFloodFillToImage(
          image: image,
          startPoint: position,
          replacementColor: _toolManager.currentColor,
          tolerance: _toolManager.fillTolerance,
          use8Direction: _toolManager.use8DirectionFill,
        );

        setState(() {
          _backgroundImage = filledImage;
          _points.clear();
          _layers[_currentLayerIndex].clear();
        });

        await DrawingHistoryManager.addToRecent(
          'drawing_${DateTime.now().millisecondsSinceEpoch}',
          {
            'title': 'Free Drawing',
            'createdAt': DateTime.now().toIso8601String(),
            'tool': _toolManager.currentTool.toString(),
          },
        );
      }
    } catch (e) {
      print('Flood fill error: $e');
      _showErrorSnackbar('Failed to fill area: $e');
    }
  }

  void _drawShape(Offset position) {
    setState(() {
      _saveCurrentState();

      final shapePoints = _createShapePoints(position, _toolManager.selectedShape);
      _layers[_currentLayerIndex].addAll(shapePoints);

      _captureCurrentImage();
    });
  }

  List<DrawingPoint> _createShapePoints(Offset center, ShapeType shape) {
    final List<DrawingPoint> points = [];
    final double size = _toolManager.brushSize * 5;

    switch (shape) {
      case ShapeType.circle:
        points.addAll(_createCirclePoints(center, size));
        break;
      case ShapeType.rectangle:
        points.addAll(_createRectanglePoints(center, size));
        break;
      case ShapeType.line:
        points.addAll(_createLinePoints(center, size));
        break;
      case ShapeType.triangle:
        points.addAll(_createTrianglePoints(center, size));
        break;
      case ShapeType.star:
        points.addAll(_createStarPoints(center, size));
        break;
      case ShapeType.heart:
        points.addAll(_createHeartPoints(center, size));
        break;
    }

    return points;
  }

  List<DrawingPoint> _createCirclePoints(Offset center, double size) {
    final List<DrawingPoint> points = [];
    const int segments = 36;

    for (int i = 0; i <= segments; i++) {
      final angle = 2 * 3.14159 * i / segments;
      final x = center.dx + size * cos(angle);
      final y = center.dy + size * sin(angle);

      points.add(DrawingPoint(
        offset: Offset(x, y),
        color: _toolManager.currentColor,
        size: _toolManager.brushSize,
        tool: _toolManager.currentTool,
      ));
    }

    return points;
  }

  List<DrawingPoint> _createRectanglePoints(Offset center, double size) {
    final List<DrawingPoint> points = [];
    final halfSize = size / 2;

    final corners = [
      Offset(center.dx - halfSize, center.dy - halfSize),
      Offset(center.dx + halfSize, center.dy - halfSize),
      Offset(center.dx + halfSize, center.dy + halfSize),
      Offset(center.dx - halfSize, center.dy + halfSize),
      Offset(center.dx - halfSize, center.dy - halfSize),
    ];

    for (final corner in corners) {
      points.add(DrawingPoint(
        offset: corner,
        color: _toolManager.currentColor,
        size: _toolManager.brushSize,
        tool: _toolManager.currentTool,
      ));
    }

    return points;
  }

  List<DrawingPoint> _createLinePoints(Offset start, double length) {
    final end = Offset(start.dx + length, start.dy + length);

    return [
      DrawingPoint(
        offset: start,
        color: _toolManager.currentColor,
        size: _toolManager.brushSize,
        tool: _toolManager.currentTool,
      ),
      DrawingPoint(
        offset: end,
        color: _toolManager.currentColor,
        size: _toolManager.brushSize,
        tool: _toolManager.currentTool,
      ),
    ];
  }

  List<DrawingPoint> _createTrianglePoints(Offset center, double size) {
    final halfSize = size / 2;
    final height = size * 0.866; // Equilateral triangle height

    final points = [
      Offset(center.dx, center.dy - height / 2), // Top
      Offset(center.dx + halfSize, center.dy + height / 2), // Bottom right
      Offset(center.dx - halfSize, center.dy + height / 2), // Bottom left
      Offset(center.dx, center.dy - height / 2), // Back to top
    ];

    return points.map((point) => DrawingPoint(
      offset: point,
      color: _toolManager.currentColor,
      size: _toolManager.brushSize,
      tool: _toolManager.currentTool,
    )).toList();
  }

  List<DrawingPoint> _createStarPoints(Offset center, double size) {
    final List<DrawingPoint> points = [];
    const int pointsCount = 5;
    final outerRadius = size;
    final innerRadius = size / 2;

    for (int i = 0; i <= pointsCount * 2; i++) {
      final angle = 3.14159 * i / pointsCount;
      final radius = i.isEven ? outerRadius : innerRadius;

      final x = center.dx + radius * cos(angle);
      final y = center.dy + radius * sin(angle);

      points.add(DrawingPoint(
        offset: Offset(x, y),
        color: _toolManager.currentColor,
        size: _toolManager.brushSize,
        tool: _toolManager.currentTool,
      ));
    }

    return points;
  }

  List<DrawingPoint> _createHeartPoints(Offset center, double size) {
    final List<DrawingPoint> points = [];
    const int segments = 20;
    final scale = size / 20;

    for (int i = 0; i <= segments; i++) {
      final t = 2 * 3.14159 * i / segments;
      final x = 16 * pow(sin(t), 3).toDouble();
      final y = 13 * cos(t) - 5 * cos(2 * t) - 2 * cos(3 * t) - cos(4 * t);

      points.add(DrawingPoint(
        offset: Offset(center.dx + x * scale, center.dy - y * scale),
        color: _toolManager.currentColor,
        size: _toolManager.brushSize,
        tool: _toolManager.currentTool,
      ));
    }

    return points;
  }

  void _showTextInputDialog(Offset position) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add Text'),
        content: TextField(
          controller: TextEditingController(text: _toolManager.textContent),
          decoration: InputDecoration(
            hintText: 'Enter your text here',
            border: OutlineInputBorder(),
          ),
          onChanged: (value) {
            _toolManager.textContent = value;
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _addTextToCanvas(position);
            },
            child: Text('Add Text'),
          ),
        ],
      ),
    );
  }

  void _addTextToCanvas(Offset position) {
    setState(() {
      _saveCurrentState();

      // Create text as drawing points (simplified approach)
      // In a real implementation, you'd use a TextPainter
      final textPoint = DrawingPoint(
        offset: position,
        color: _toolManager.currentColor,
        size: _toolManager.textSize,
        tool: DrawingTool.text,
        text: _toolManager.textContent,
      );

      _layers[_currentLayerIndex].add(textPoint);
      _captureCurrentImage();
    });
  }

  // History management
  void _saveCurrentState() {
    if (_undoStack.length >= _toolManager.maxHistorySteps) {
      _undoStack.removeAt(0);
    }

    _undoStack.add(DrawingState(
      layers: _layers.map((layer) => List<DrawingPoint>.from(layer)).toList(),
      backgroundImage: _backgroundImage,
      timestamp: DateTime.now(),
    ));

    _redoStack.clear();
  }

  void _undo() {
    if (_undoStack.isNotEmpty) {
      final currentState = DrawingState(
        layers: _layers.map((layer) => List<DrawingPoint>.from(layer)).toList(),
        backgroundImage: _backgroundImage,
        timestamp: DateTime.now(),
      );

      _redoStack.add(currentState);

      final previousState = _undoStack.removeLast();
      setState(() {
        _layers.clear();
        _layers.addAll(previousState.layers);
        _backgroundImage = previousState.backgroundImage;
      });

      _captureCurrentImage();
    }
  }

  void _redo() {
    if (_redoStack.isNotEmpty) {
      final currentState = DrawingState(
        layers: _layers.map((layer) => List<DrawingPoint>.from(layer)).toList(),
        backgroundImage: _backgroundImage,
        timestamp: DateTime.now(),
      );

      _undoStack.add(currentState);

      final nextState = _redoStack.removeLast();
      setState(() {
        _layers.clear();
        _layers.addAll(nextState.layers);
        _backgroundImage = nextState.backgroundImage;
      });

      _captureCurrentImage();
    }
  }

  // Image capture and sharing
  Future<ui.Image?> _captureCurrentImage() async {
    try {
      // This would capture the current canvas as an image
      // Implementation depends on your specific canvas setup
      return _currentImage;
    } catch (e) {
      print('Error capturing image: $e');
      return null;
    }
  }

  void _shareDrawing() async {
    final image = await _captureCurrentImage();
    if (image != null) {
      final result = await ShareManager.shareDrawing(
        image: image,
        title: 'My Drawing',
        message: 'Check out this amazing drawing I created! 🎨',
        hashtags: ['coloring', 'drawing', 'art'],
      );

      if (!result.success) {
        _showErrorSnackbar('Failed to share drawing: ${result.error}');
      }
    }
  }

  void _saveDrawing() async {
    final image = await _captureCurrentImage();
    if (image != null) {
      final result = await ShareManager.saveToGallery(
        image: image,
        name: 'My Drawing',
        format: 'PNG',
        quality: 100,
      );

      if (result.success) {
        _showSuccessSnackbar('Drawing saved to gallery!');
      } else {
        _showErrorSnackbar('Failed to save drawing: ${result.error}');
      }
    }
  }

  void _exportDrawing() async {
    final image = await _captureCurrentImage();
    if (image != null) {
      final result = await ShareManager.exportDrawing(
        image: image,
        fileName: 'My_Drawing',
        format: 'PNG',
        quality: 100,
        includeMetadata: true,
      );

      if (result.success) {
        _showSuccessSnackbar('Drawing exported successfully!');
      } else {
        _showErrorSnackbar('Failed to export drawing: ${result.error}');
      }
    }
  }

  // UI helpers
  void _showSuccessSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _toggleColorPicker() {
    setState(() {
      _showColorPicker = !_showColorPicker;
    });
  }

  void _toggleLayersPanel() {
    setState(() {
      _showLayersPanel = !_showLayersPanel;
    });
  }

  void _resetZoomAndPan() {
    setState(() {
      _zoomLevel = 1.0;
      _panOffset = Offset.zero;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text('Free Draw'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        elevation: 4,
        actions: [
          // Undo/Redo
          IconButton(
            icon: Icon(Icons.undo),
            tooltip: 'Undo',
            onPressed: _undoStack.isNotEmpty ? _undo : null,
          ),
          IconButton(
            icon: Icon(Icons.redo),
            tooltip: 'Redo',
            onPressed: _redoStack.isNotEmpty ? _redo : null,
          ),

          // Zoom controls
          PopupMenuButton<String>(
            icon: Icon(Icons.zoom_in),
            tooltip: 'Zoom & View',
            onSelected: (value) {
              switch (value) {
                case 'reset':
                  _resetZoomAndPan();
                  break;
                case 'fit':
                // Implement fit to screen
                  break;
                case 'actual':
                  setState(() => _zoomLevel = 1.0);
                  break;
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'reset',
                child: ListTile(
                  leading: Icon(Icons.refresh),
                  title: Text('Reset View'),
                ),
              ),
              PopupMenuItem(
                value: 'fit',
                child: ListTile(
                  leading: Icon(Icons.fit_screen),
                  title: Text('Fit to Screen'),
                ),
              ),
              PopupMenuItem(
                value: 'actual',
                child: ListTile(
                  leading: Icon(Icons.aspect_ratio),
                  title: Text('Actual Size'),
                ),
              ),
            ],
          ),

          // Layers
          IconButton(
            icon: Icon(Icons.layers),
            tooltip: 'Layers',
            onPressed: _toggleLayersPanel,
          ),

          // More options
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert),
            onSelected: (value) {
              switch (value) {
                case 'share':
                  _shareDrawing();
                  break;
                case 'save':
                  _saveDrawing();
                  break;
                case 'export':
                  _exportDrawing();
                  break;
                case 'clear':
                  _clearCanvas();
                  break;
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'share',
                child: ListTile(
                  leading: Icon(Icons.share),
                  title: Text('Share Drawing'),
                ),
              ),
              PopupMenuItem(
                value: 'save',
                child: ListTile(
                  leading: Icon(Icons.save),
                  title: Text('Save to Gallery'),
                ),
              ),
              PopupMenuItem(
                value: 'export',
                child: ListTile(
                  leading: Icon(Icons.download),
                  title: Text('Export Drawing'),
                ),
              ),
              PopupMenuDivider(),
              PopupMenuItem(
                value: 'clear',
                child: ListTile(
                  leading: Icon(Icons.clear, color: Colors.red),
                  title: Text('Clear Canvas', style: TextStyle(color: Colors.red)),
                ),
              ),
            ],
          ),
        ],
      ),
      body: Stack(
        children: [
          // Main drawing area
          Positioned.fill(
            child: InteractiveViewer(
              constrained: false,
              scaleEnabled: true,
              panEnabled: true,
              minScale: 0.1,
              maxScale: 5.0,
              onInteractionUpdate: (ScaleUpdateDetails details) {
                setState(() {
                  _zoomLevel = details.scale;
                  _panOffset = details.focalPoint;
                });
              },
              child: DrawingCanvas(
                key: _canvasKey,
                points: _layers.expand((layer) => layer).toList(),
                backgroundImage: _backgroundImage,
                toolManager: _toolManager,
                onDrawingStart: _onDrawingStart,
                onDrawingUpdate: _onDrawingUpdate,
                onDrawingEnd: _onDrawingEnd,
                onCanvasTap: _onCanvasTap,
                zoomLevel: _zoomLevel,
                panOffset: _panOffset,
              ),
            ),
          ),

          // Color picker overlay
          if (_showColorPicker)
            Positioned(
              bottom: 80,
              left: 0,
              right: 0,
              child: Container(
                margin: EdgeInsets.all(16),
                child: CustomColorPicker(
                  onColorChanged: (color) {
                    _toolManager.changeColor(color);
                  },
                  onRecentColorsUpdated: (colors) {
                    // Save recent colors
                  },
                  currentColor: _toolManager.currentColor,
                  showRecentColors: true,
                  showFavoriteColors: true,
                  showColorWheel: true,
                  showOpacitySlider: true,
                  pickerHeight: 300,
                ),
              ),
            ),

          // Layers panel overlay
          if (_showLayersPanel)
            Positioned(
              right: 16,
              top: 80,
              bottom: 80,
              child: Container(
                width: 200,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 8,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: _buildLayersPanel(),
              ),
            ),
        ],
      ),

      // Bottom tool palette
      bottomNavigationBar: Container(
        color: Colors.white,
        child: SafeArea(
          child: ToolPalette(
            toolManager: _toolManager,
            onToolChanged: (tool) {
              setState(() {});
            },
            onColorChanged: (color) {
              setState(() {
                _toolManager.changeColor(color);
              });
            },
            onColorPickerToggled: _toggleColorPicker,
            onBrushSizeChanged: (size) {
              setState(() {
                _toolManager.changeBrushSize(size);
              });
            },
            onOpacityChanged: (opacity) {
              setState(() {
                _toolManager.changeOpacity(opacity);
              });
            },
          ),
        ),
      ),
    );
  }

  Widget _buildLayersPanel() {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              Text('Layers', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              Spacer(),
              IconButton(
                icon: Icon(Icons.add),
                onPressed: _addLayer,
                tooltip: 'Add Layer',
              ),
              IconButton(
                icon: Icon(Icons.close),
                onPressed: _toggleLayersPanel,
                tooltip: 'Close',
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: _layers.length,
            itemBuilder: (context, index) {
              return _buildLayerItem(index);
            },
          ),
        ),
        Container(
          padding: EdgeInsets.all(16),
          child: ElevatedButton.icon(
            icon: Icon(Icons.visibility),
            label: Text('Toggle All'),
            onPressed: _toggleAllLayers,
          ),
        ),
      ],
    );
  }

  Widget _buildLayerItem(int index) {
    final isActive = index == _currentLayerIndex;
    final layerPoints = _layers[index];

    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          border: Border.all(color: isActive ? Colors.blue : Colors.grey),
          borderRadius: BorderRadius.circular(4),
        ),
        child: layerPoints.isNotEmpty
            ? Container(color: Colors.grey[200])
            : Container(color: Colors.transparent),
      ),
      title: Text('Layer ${index + 1}'),
      subtitle: Text('${layerPoints.length} points'),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: Icon(Icons.visibility, color: Colors.grey),
            onPressed: () => _toggleLayerVisibility(index),
          ),
          if (!isActive) IconButton(
            icon: Icon(Icons.delete, color: Colors.red),
            onPressed: () => _removeLayer(index),
          ),
        ],
      ),
      onTap: () => _selectLayer(index),
      tileColor: isActive ? Colors.blue[50] : null,
    );
  }

  void _addLayer() {
    setState(() {
      _layers.add([]);
      _currentLayerIndex = _layers.length - 1;
    });
  }

  void _removeLayer(int index) {
    if (_layers.length > 1) {
      setState(() {
        _layers.removeAt(index);
        if (_currentLayerIndex >= index) {
          _currentLayerIndex = (_currentLayerIndex - 1).clamp(0, _layers.length - 1);
        }
      });
    }
  }

  void _selectLayer(int index) {
    setState(() {
      _currentLayerIndex = index;
    });
  }

  void _toggleLayerVisibility(int index) {
    // Implementation for layer visibility
  }

  void _toggleAllLayers() {
    // Implementation for toggling all layers
  }

  void _clearCanvas() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Clear Canvas'),
        content: Text('Are you sure you want to clear the entire canvas? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _saveCurrentState();
                for (final layer in _layers) {
                  layer.clear();
                }
                _backgroundImage = null;
              });
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Clear'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _zoomAnimationController.dispose();
    _panelAnimationController.dispose();
    super.dispose();
  }
}

class DrawingState {
  final List<List<DrawingPoint>> layers;
  final ui.Image? backgroundImage;
  final DateTime timestamp;

  DrawingState({
    required this.layers,
    this.backgroundImage,
    required this.timestamp,
  });
}