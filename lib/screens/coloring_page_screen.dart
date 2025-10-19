import 'package:flutter/material.dart';
import '../models/coloring_page.dart';
import '../widgets/drawing_canvas.dart';
import '../widgets/tool_palette.dart';
import '../services/image_saver.dart';
import '../models/drawing_point.dart';

class ColoringPageScreen extends StatefulWidget {
  final ColoringPage coloringPage;

  const ColoringPageScreen({
    Key? key,
    required this.coloringPage,
  }) : super(key: key);

  @override
  State<ColoringPageScreen> createState() => _ColoringPageScreenState();
}

class _ColoringPageScreenState extends State<ColoringPageScreen> {
  final GlobalKey<DrawingCanvasState> _drawingCanvasKey = GlobalKey();

  void _handleColorChanged(Color color) {
    _drawingCanvasKey.currentState?.selectedColor = color;
  }

  void _handleStrokeWidthChanged(double width) {
    _drawingCanvasKey.currentState?.strokeWidth = width;
  }

  void _handleToolChanged(DrawingType tool) {
    _drawingCanvasKey.currentState?.setTool(tool);
  }

  void _handleUndo() {
    _drawingCanvasKey.currentState?.undo();
  }

  void _handleClear() {
    _drawingCanvasKey.currentState?.clearCanvas();
  }

  void _handleToggleShapeFill() {
    _drawingCanvasKey.currentState?.toggleShapeFill();
  }

  Color _getBackgroundColor(String title) {
    final colors = [
      Colors.red[50]!,
      Colors.blue[50]!,
      Colors.green[50]!,
      Colors.yellow[50]!,
      Colors.purple[50]!,
      Colors.orange[50]!,
      Colors.pink[50]!,
      Colors.teal[50]!,
    ];

    int index = title.codeUnits.fold(0, (a, b) => a + b) % colors.length;
    return colors[index];
  }

  IconData _getIconFromCategory(String category) {
    switch (category) {
      case 'Animals':
        return Icons.pets;
      case 'Nature':
        return Icons.nature;
      case 'Fantasy':
        return Icons.auto_awesome;
      case 'Vehicles':
        return Icons.directions_car;
      default:
        return Icons.image;
    }
  }

  Future<void> _saveDrawing() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
            SizedBox(width: 16),
            Text('Saving your drawing...'),
          ],
        ),
        duration: Duration(seconds: 5),
      ),
    );

    final saver = ImageSaver();
    final result = await saver.saveDrawing(
      _drawingCanvasKey.currentState!.repaintKey,
      title: '${widget.coloringPage.title}_coloring',
    );

    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    if (result != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result),
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: 'OK',
            onPressed: () {},
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final backgroundColor = _getBackgroundColor(widget.coloringPage.title);
    final icon = _getIconFromCategory(widget.coloringPage.category);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.coloringPage.title),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveDrawing,
          ),
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            color: Colors.grey[100],
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Row(
                  children: [
                    Icon(
                      icon,
                      size: 16,
                      color: Colors.deepPurple,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      widget.coloringPage.category,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.deepPurple,
                      ),
                    ),
                  ],
                ),
                Text(
                  'Use tools below to color!',
                  style: TextStyle(
                    fontStyle: FontStyle.italic,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Stack(
              children: [
                Container(
                  color: backgroundColor,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          icon,
                          size: 100,
                          color: Colors.black26,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          widget.coloringPage.title,
                          style: TextStyle(
                            fontSize: 24,
                            color: Colors.black38,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Color this ${widget.coloringPage.category.toLowerCase()} page!',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.black26,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                DrawingCanvas(
                  key: _drawingCanvasKey,
                ),
              ],
            ),
          ),
          ToolPalette(
            onColorChanged: _handleColorChanged,
            onStrokeWidthChanged: _handleStrokeWidthChanged,
            onToolChanged: _handleToolChanged,
            onUndo: _handleUndo,
            onClear: _handleClear,
            onToggleShapeFill: _handleToggleShapeFill,
            currentTool: _drawingCanvasKey.currentState?.currentTool ?? DrawingType.pen,
            isShapeFilled: _drawingCanvasKey.currentState?.isShapeFilled ?? false,
          ),
        ],
      ),
    );
  }
}