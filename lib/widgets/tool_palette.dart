import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import '../managers/drawing_tools_manager.dart';
import 'custom_color_picker.dart';

class ToolPalette extends StatefulWidget {
  final DrawingToolManager toolManager;
  final ValueChanged<DrawingTool> onToolChanged;
  final ValueChanged<Color> onColorChanged;
  final VoidCallback onColorPickerToggled;
  final ValueChanged<double> onBrushSizeChanged;
  final ValueChanged<double> onOpacityChanged;
  final ValueChanged<BrushType>? onBrushTypeChanged;
  final ValueChanged<ShapeType>? onShapeTypeChanged;
  final ValueChanged<int>? onFillToleranceChanged;
  final ValueChanged<bool>? onFillDirectionChanged;
  final bool showAdvancedOptions;

  const ToolPalette({
    Key? key,
    required this.toolManager,
    required this.onToolChanged,
    required this.onColorChanged,
    required this.onColorPickerToggled,
    required this.onBrushSizeChanged,
    required this.onOpacityChanged,
    this.onBrushTypeChanged,
    this.onShapeTypeChanged,
    this.onFillToleranceChanged,
    this.onFillDirectionChanged,
    this.showAdvancedOptions = false,
  }) : super(key: key);

  @override
  _ToolPaletteState createState() => _ToolPaletteState();
}

class _ToolPaletteState extends State<ToolPalette> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  bool _showAdvancedSettings = false;
  final double _paletteHeight = 120.0;
  final double _expandedHeight = 220.0;

  // Brush presets
  final List<Map<String, dynamic>> _brushPresets = [
    {'type': BrushType.normal, 'name': 'Normal', 'icon': Icons.brush, 'minSize': 1.0, 'maxSize': 50.0},
    {'type': BrushType.calligraphy, 'name': 'Calligraphy', 'icon': Icons.edit, 'minSize': 2.0, 'maxSize': 30.0},
    {'type': BrushType.airbrush, 'name': 'Airbrush', 'icon': Icons.air, 'minSize': 5.0, 'maxSize': 100.0},
    {'type': BrushType.charcoal, 'name': 'Charcoal', 'icon': Icons.grain, 'minSize': 3.0, 'maxSize': 40.0},
    {'type': BrushType.watercolor, 'name': 'Watercolor', 'icon': Icons.water_drop, 'minSize': 8.0, 'maxSize': 60.0},
  ];

  // Shape presets
  final List<Map<String, dynamic>> _shapePresets = [
    {'type': ShapeType.circle, 'name': 'Circle', 'icon': Icons.circle_outlined},
    {'type': ShapeType.rectangle, 'name': 'Rectangle', 'icon': Icons.crop_square},
    {'type': ShapeType.line, 'name': 'Line', 'icon': Icons.horizontal_rule},
    {'type': ShapeType.triangle, 'name': 'Triangle', 'icon': Icons.change_history},
    {'type': ShapeType.star, 'name': 'Star', 'icon': Icons.star_border},
    {'type': ShapeType.heart, 'name': 'Heart', 'icon': Icons.favorite_border},
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 300),
    );
  }

  void _toggleAdvancedSettings() {
    setState(() {
      _showAdvancedSettings = !_showAdvancedSettings;
    });

    if (_showAdvancedSettings) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
  }

  Widget _buildMainTools() {
    return Container(
      height: _paletteHeight,
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Primary tools row
          Expanded(
            child: Row(
              children: [
                // Drawing tools
                _buildToolSection(
                  title: 'Tools',
                  children: [
                    _buildToolButton(
                      Icons.brush,
                      'Brush',
                      DrawingTool.brush,
                      Colors.blue,
                    ),
                    _buildToolButton(
                      Icons.format_color_fill,
                      'Fill',
                      DrawingTool.fill,
                      Colors.green,
                    ),
                    _buildToolButton(
                      Icons.eraser,
                      'Eraser',
                      DrawingTool.eraser,
                      Colors.red,
                    ),
                    _buildToolButton(
                      Icons.shape_line,
                      'Shapes',
                      DrawingTool.shapes,
                      Colors.orange,
                    ),
                    _buildToolButton(
                      Icons.text_fields,
                      'Text',
                      DrawingTool.text,
                      Colors.purple,
                    ),
                  ],
                ),

                // Color picker and current color
                _buildColorSection(),

                // Brush size and opacity
                _buildSizeAndOpacitySection(),

                // Advanced settings toggle
                if (widget.showAdvancedOptions)
                  IconButton(
                    icon: Icon(
                      _showAdvancedSettings ? Icons.expand_less : Icons.expand_more,
                      color: Colors.grey[600],
                    ),
                    onPressed: _toggleAdvancedSettings,
                    tooltip: 'Advanced Settings',
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolSection({required String title, required List<Widget> children}) {
    return Expanded(
      flex: 3,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 4),
          Expanded(
            child: Row(
              children: children,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolButton(IconData icon, String tooltip, DrawingTool tool, Color activeColor) {
    final isActive = widget.toolManager.currentTool == tool;

    return Expanded(
      child: Tooltip(
        message: tooltip,
        child: InkWell(
          onTap: () {
            widget.toolManager.changeTool(tool);
            widget.onToolChanged(tool);
          },
          borderRadius: BorderRadius.circular(8),
          child: Container(
            margin: EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
              color: isActive ? activeColor.withOpacity(0.1) : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isActive ? activeColor : Colors.transparent,
                width: 2,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: isActive ? activeColor : Colors.grey[600],
                ),
                SizedBox(height: 2),
                if (isActive)
                  Container(
                    width: 4,
                    height: 4,
                    decoration: BoxDecoration(
                      color: activeColor,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildColorSection() {
    return Expanded(
      flex: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Color',
            style: TextStyle(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 4),
          Expanded(
            child: Row(
              children: [
                // Current color display
                GestureDetector(
                  onTap: widget.onColorPickerToggled,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: widget.toolManager.currentColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.grey, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: widget.toolManager.currentColor.opacity < 0.5
                        ? Icon(Icons.invert_colors, size: 16, color: Colors.black)
                        : null,
                  ),
                ),
                SizedBox(width: 8),

                // Quick color presets
                Expanded(
                  child: _buildQuickColors(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickColors() {
    final quickColors = [
      Colors.black,
      Colors.red,
      Colors.orange,
      Colors.yellow,
      Colors.green,
      Colors.blue,
      Colors.indigo,
      Colors.purple,
      Colors.pink,
      Colors.brown,
      Colors.grey,
      Colors.white,
    ];

    return ListView.builder(
      scrollDirection: Axis.horizontal,
      itemCount: quickColors.length,
      itemBuilder: (context, index) {
        final color = quickColors[index];
        return GestureDetector(
          onTap: () {
            widget.toolManager.changeColor(color);
            widget.onColorChanged(color);
          },
          child: Container(
            width: 24,
            height: 24,
            margin: EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.grey,
                width: color == widget.toolManager.currentColor ? 2 : 1,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSizeAndOpacitySection() {
    return Expanded(
      flex: 3,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Brush',
            style: TextStyle(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 4),
          Expanded(
            child: Row(
              children: [
                // Brush size
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Size: ${widget.toolManager.brushSize.toInt()}px',
                        style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                      ),
                      Expanded(
                        child: Slider(
                          value: widget.toolManager.brushSize,
                          onChanged: widget.onBrushSizeChanged,
                          min: 1,
                          max: 50,
                          divisions: 49,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 8),

                // Opacity
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Opacity: ${(widget.toolManager.opacity * 100).toInt()}%',
                        style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                      ),
                      Expanded(
                        child: Slider(
                          value: widget.toolManager.opacity,
                          onChanged: widget.onOpacityChanged,
                          min: 0,
                          max: 1,
                          divisions: 20,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdvancedSettings() {
    return SizeTransition(
      sizeFactor: _animationController,
      child: Container(
        height: _expandedHeight - _paletteHeight,
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
        ),
        child: Column(
          children: [
            // Tool-specific settings
            if (widget.toolManager.currentTool == DrawingTool.brush)
              _buildBrushSettings(),

            if (widget.toolManager.currentTool == DrawingTool.fill)
              _buildFillSettings(),

            if (widget.toolManager.currentTool == DrawingTool.shapes)
              _buildShapeSettings(),

            if (widget.toolManager.currentTool == DrawingTool.text)
              _buildTextSettings(),

            // General advanced settings
            _buildGeneralSettings(),
          ],
        ),
      ),
    );
  }

  Widget _buildBrushSettings() {
    return Column(
      children: [
        Row(
          children: [
            Text('Brush Type:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            SizedBox(width: 8),
            Expanded(
              child: DropdownButton<BrushType>(
                value: widget.toolManager.selectedBrush,
                onChanged: (BrushType? newValue) {
                  if (newValue != null && widget.onBrushTypeChanged != null) {
                    widget.toolManager.changeBrushType(newValue);
                    widget.onBrushTypeChanged!(newValue);
                  }
                },
                isExpanded: true,
                items: _brushPresets.map((preset) {
                  return DropdownMenuItem<BrushType>(
                    value: preset['type'],
                    child: Row(
                      children: [
                        Icon(preset['icon'], size: 16),
                        SizedBox(width: 8),
                        Text(preset['name']),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
        SizedBox(height: 8),
        Row(
          children: [
            Text('Smoothness:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            SizedBox(width: 8),
            Expanded(
              child: Slider(
                value: widget.toolManager.smoothness,
                onChanged: (value) {
                  setState(() {
                    widget.toolManager.smoothness = value;
                  });
                },
                min: 0,
                max: 1,
                divisions: 10,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFillSettings() {
    return Column(
      children: [
        Row(
          children: [
            Text('Tolerance:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            SizedBox(width: 8),
            Expanded(
              child: Slider(
                value: widget.toolManager.fillTolerance.toDouble(),
                onChanged: (value) {
                  if (widget.onFillToleranceChanged != null) {
                    widget.toolManager.fillTolerance = value.toInt();
                    widget.onFillToleranceChanged!(value.toInt());
                  }
                },
                min: 0,
                max: 50,
                divisions: 50,
                label: '${widget.toolManager.fillTolerance}',
              ),
            ),
          ],
        ),
        SizedBox(height: 8),
        Row(
          children: [
            Text('8-Direction Fill:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            SizedBox(width: 8),
            Switch(
              value: widget.toolManager.use8DirectionFill,
              onChanged: (value) {
                if (widget.onFillDirectionChanged != null) {
                  widget.toolManager.use8DirectionFill = value;
                  widget.onFillDirectionChanged!(value);
                }
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildShapeSettings() {
    return Column(
      children: [
        Row(
          children: [
            Text('Shape Type:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            SizedBox(width: 8),
            Expanded(
              child: Wrap(
                spacing: 4,
                runSpacing: 4,
                children: _shapePresets.map((preset) {
                  final isActive = widget.toolManager.selectedShape == preset['type'];
                  return GestureDetector(
                    onTap: () {
                      if (widget.onShapeTypeChanged != null) {
                        widget.toolManager.selectedShape = preset['type'];
                        widget.onShapeTypeChanged!(preset['type']);
                      }
                    },
                    child: Container(
                      padding: EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: isActive ? Colors.blue.withOpacity(0.1) : Colors.transparent,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: isActive ? Colors.blue : Colors.grey[300]!,
                        ),
                      ),
                      child: Icon(
                        preset['icon'],
                        size: 16,
                        color: isActive ? Colors.blue : Colors.grey[600],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
        SizedBox(height: 8),
        Row(
          children: [
            Text('Fill Shape:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            SizedBox(width: 8),
            Switch(
              value: widget.toolManager.fillShapes,
              onChanged: (value) {
                setState(() {
                  widget.toolManager.fillShapes = value;
                });
              },
            ),
            if (widget.toolManager.fillShapes) ...[
              SizedBox(width: 16),
              GestureDetector(
                onTap: () {
                  // Show fill color picker
                },
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: widget.toolManager.shapeFillColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.grey),
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildTextSettings() {
    return Column(
      children: [
        Row(
          children: [
            Text('Font Size:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            SizedBox(width: 8),
            Expanded(
              child: Slider(
                value: widget.toolManager.textSize,
                onChanged: (value) {
                  setState(() {
                    widget.toolManager.textSize = value;
                  });
                },
                min: 8,
                max: 72,
                divisions: 16,
                label: '${widget.toolManager.textSize.toInt()}',
              ),
            ),
          ],
        ),
        SizedBox(height: 8),
        Row(
          children: [
            Text('Font:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            SizedBox(width: 8),
            Expanded(
              child: DropdownButton<String>(
                value: widget.toolManager.selectedFont,
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() {
                      widget.toolManager.selectedFont = newValue;
                    });
                  }
                },
                isExpanded: true,
                items: ['Arial', 'Roboto', 'Comic Sans', 'Times New Roman', 'Courier New']
                    .map((String font) {
                  return DropdownMenuItem<String>(
                    value: font,
                    child: Text(font),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildGeneralSettings() {
    return Column(
      children: [
        Divider(),
        SizedBox(height: 8),
        Row(
          children: [
            Text('Pressure Sensitivity:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            SizedBox(width: 8),
            Switch(
              value: widget.toolManager.pressureSensitive,
              onChanged: (value) {
                setState(() {
                  widget.toolManager.pressureSensitive = value;
                });
              },
            ),
            Spacer(),
            Text('Auto-save:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            SizedBox(width: 8),
            Switch(
              value: widget.toolManager.autoSave,
              onChanged: (value) {
                setState(() {
                  widget.toolManager.autoSave = value;
                });
              },
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildMainTools(),
        if (widget.showAdvancedOptions && _showAdvancedSettings)
          _buildAdvancedSettings(),
      ],
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
}