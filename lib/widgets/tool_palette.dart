import 'package:flutter/material.dart';
import '../models/drawing_point.dart';

class ToolPalette extends StatefulWidget {
  final ValueChanged<Color> onColorChanged;
  final ValueChanged<double> onStrokeWidthChanged;
  final ValueChanged<DrawingType> onToolChanged;
  final VoidCallback onUndo;
  final VoidCallback onClear;
  final VoidCallback onToggleShapeFill;
  final DrawingType currentTool;
  final bool isShapeFilled;

  const ToolPalette({
    Key? key,
    required this.onColorChanged,
    required this.onStrokeWidthChanged,
    required this.onToolChanged,
    required this.onUndo,
    required this.onClear,
    required this.onToggleShapeFill,
    required this.currentTool,
    required this.isShapeFilled,
  }) : super(key: key);

  @override
  _ToolPaletteState createState() => _ToolPaletteState();
}

class _ToolPaletteState extends State<ToolPalette> {
  Color _selectedColor = Colors.black;
  double _strokeWidth = 3.0;

  final List<Color> _colors = [
    Colors.black,
    Colors.red,
    Colors.blue,
    Colors.green,
    Colors.yellow,
    Colors.orange,
    Colors.purple,
    Colors.pink,
    Colors.brown,
    Colors.grey,
  ];

  void _selectColor(Color color) {
    setState(() {
      _selectedColor = color;
    });
    widget.onColorChanged(color);
  }

  void _selectTool(DrawingType tool) {
    widget.onToolChanged(tool);
  }

  void _changeStrokeWidth(double width) {
    setState(() {
      _strokeWidth = width;
    });
    widget.onStrokeWidthChanged(width);
  }

  bool _isToolSelected(DrawingType tool) {
    return widget.currentTool == tool;
  }

  Color _getToolColor(DrawingType tool) {
    return _isToolSelected(tool) ? Colors.blue : Colors.grey;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Color Palette
          SizedBox(
            height: 40,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildColorCircle(Colors.black),
                _buildColorCircle(Colors.red),
                _buildColorCircle(Colors.blue),
                _buildColorCircle(Colors.green),
                _buildColorCircle(Colors.yellow),
                _buildColorCircle(Colors.orange),
                _buildColorCircle(Colors.purple),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Drawing Tools
          SizedBox(
            height: 50,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Pen Tool
                _buildToolButton(
                  icon: Icons.brush,
                  tool: DrawingType.pen,
                  tooltip: 'Pen',
                ),

                // Eraser
                _buildToolButton(
                  icon: Icons.auto_fix_high,
                  tool: DrawingType.eraser,
                  tooltip: 'Eraser',
                ),

                // Fill Bucket
                _buildToolButton(
                  icon: Icons.format_color_fill,
                  tool: DrawingType.fill,
                  tooltip: 'Fill Bucket',
                ),

                // Circle
                _buildToolButton(
                  icon: Icons.circle_outlined,
                  tool: DrawingType.circle,
                  tooltip: 'Circle',
                ),

                // Rectangle
                _buildToolButton(
                  icon: Icons.crop_square,
                  tool: DrawingType.rectangle,
                  tooltip: 'Rectangle',
                ),

                // Line
                _buildToolButton(
                  icon: Icons.horizontal_rule,
                  tool: DrawingType.line,
                  tooltip: 'Line',
                ),
              ],
            ),
          ),

          // Shape Fill Toggle & Other Tools
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Stroke Width
              SizedBox(
                width: 80,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Size',
                      style: TextStyle(fontSize: 10),
                    ),
                    Slider(
                      value: _strokeWidth,
                      min: 1,
                      max: 20,
                      onChanged: _changeStrokeWidth,
                    ),
                  ],
                ),
              ),

              // Shape Fill Toggle
              if (widget.currentTool == DrawingType.circle ||
                  widget.currentTool == DrawingType.rectangle)
                IconButton(
                  icon: Icon(
                    widget.isShapeFilled ? Icons.check_box : Icons.check_box_outline_blank,
                    color: widget.isShapeFilled ? Colors.blue : Colors.grey,
                  ),
                  onPressed: widget.onToggleShapeFill,
                  tooltip: 'Fill Shape',
                ),

              // Undo
              IconButton(
                icon: const Icon(Icons.undo, size: 20),
                onPressed: widget.onUndo,
                tooltip: 'Undo',
              ),

              // Clear
              IconButton(
                icon: const Icon(Icons.clear, size: 20),
                onPressed: widget.onClear,
                tooltip: 'Clear',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildColorCircle(Color color) {
    return GestureDetector(
      onTap: () => _selectColor(color),
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: _selectedColor == color
              ? Border.all(color: Colors.black, width: 2)
              : null,
        ),
      ),
    );
  }

  Widget _buildToolButton({
    required IconData icon,
    required DrawingType tool,
    required String tooltip,
  }) {
    return IconButton(
      icon: Icon(icon, size: 20),
      color: _getToolColor(tool),
      onPressed: () => _selectTool(tool),
      tooltip: tooltip,
    );
  }
}