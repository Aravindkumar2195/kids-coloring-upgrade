import 'package:flutter/material.dart';
import '../widgets/drawing_canvas.dart';
import '../widgets/tool_palette.dart';
import '../services/image_saver.dart';
import '../models/drawing_point.dart';

class FreeDrawScreen extends StatefulWidget {
  const FreeDrawScreen({Key? key}) : super(key: key);

  @override
  State<FreeDrawScreen> createState() => _FreeDrawScreenState();
}

class _FreeDrawScreenState extends State<FreeDrawScreen> {
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
      title: 'free_drawing',
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Free Drawing'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveDrawing,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: DrawingCanvas(
              key: _drawingCanvasKey,
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