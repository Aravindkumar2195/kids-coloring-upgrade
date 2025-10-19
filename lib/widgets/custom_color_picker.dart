import 'package:flutter/material.dart';
import 'dart:ui' as ui;

class CustomColorPicker extends StatefulWidget {
  final ValueChanged<Color> onColorChanged;
  final ValueChanged<List<Color>>? onRecentColorsUpdated;
  final Color currentColor;
  final List<Color> recentColors;
  final List<Color> favoriteColors;
  final bool showRecentColors;
  final bool showFavoriteColors;
  final bool showColorWheel;
  final bool showOpacitySlider;
  final double pickerHeight;

  const CustomColorPicker({
    Key? key,
    required this.onColorChanged,
    this.onRecentColorsUpdated,
    required this.currentColor,
    this.recentColors = const [],
    this.favoriteColors = const [],
    this.showRecentColors = true,
    this.showFavoriteColors = true,
    this.showColorWheel = true,
    this.showOpacitySlider = true,
    this.pickerHeight = 400,
  }) : super(key: key);

  @override
  _CustomColorPickerState createState() => _CustomColorPickerState();
}

class _CustomColorPickerState extends State<CustomColorPicker> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late Color _currentColor;
  List<Color> _recentColors = [];
  List<Color> _favoriteColors = [];

  // Color palettes
  final List<Color> _basicColors = [
    Colors.black, Colors.white, Colors.grey,
    Colors.red, Colors.pink, Colors.purple,
    Colors.deepPurple, Colors.indigo, Colors.blue,
    Colors.lightBlue, Colors.cyan, Colors.teal,
    Colors.green, Colors.lightGreen, Colors.lime,
    Colors.yellow, Colors.amber, Colors.orange,
    Colors.deepOrange, Colors.brown,
  ];

  final List<Color> _pastelColors = [
    Color(0xFFFFF0F5), Color(0xFFFFE4E1), Color(0xFFFFFACD),
    Color(0xFFF0FFF0), Color(0xFFF0FFFF), Color(0xFFF0F8FF),
    Color(0xFFE6E6FA), Color(0xFFFFF5EE), Color(0xFFF5F5DC),
    Color(0xFFFFEFD5), Color(0xFFFAFAD2), Color(0xFFF0E68C),
    Color(0xFFE0FFFF), Color(0xFFAFEEEE), Color(0xFF98FB98),
    Color(0xFF90EE90), Color(0xFFF5DEB3), Color(0xFFFFDAB9),
    Color(0xFFFFC0CB), Color(0xFFDDA0DD),
  ];

  final List<Color> _vibrantColors = [
    Color(0xFFFF0000), Color(0xFFFF00FF), Color(0xFF800080),
    Color(0xFF0000FF), Color(0xFF00FFFF), Color(0xFF00FF00),
    Color(0xFFFFFF00), Color(0xFFFFA500), Color(0xFFFF4500),
    Color(0xFF8B0000), Color(0xFF006400), Color(0xFF000080),
    Color(0xFF4B0082), Color(0xFF8B008B), Color(0xFFDC143C),
    Color(0xFF00CED1), Color(0xFFFF69B4), Color(0xFF32CD32),
    Color(0xFFFFD700), Color(0xFFFF8C00),
  ];

  @override
  void initState() {
    super.initState();
    _currentColor = widget.currentColor;
    _recentColors = List.from(widget.recentColors);
    _favoriteColors = List.from(widget.favoriteColors);
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void didUpdateWidget(CustomColorPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentColor != widget.currentColor) {
      setState(() {
        _currentColor = widget.currentColor;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: widget.pickerHeight,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 16,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Current color preview
          Container(
            height: 60,
            decoration: BoxDecoration(
              color: _currentColor,
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Center(
              child: Text(
                'Current Color',
                style: TextStyle(
                  color: _currentColor.computeLuminance() > 0.5 ? Colors.black : Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          // Tabs
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.vertical(top: Radius.circular(0)),
            ),
            child: TabBar(
              controller: _tabController,
              labelColor: Colors.blue,
              unselectedLabelColor: Colors.grey,
              indicatorColor: Colors.blue,
              tabs: [
                Tab(text: 'Basic'),
                Tab(text: 'Pastel'),
                Tab(text: 'Vibrant'),
                Tab(text: 'Custom'),
              ],
            ),
          ),

          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildColorGrid(_basicColors),
                _buildColorGrid(_pastelColors),
                _buildColorGrid(_vibrantColors),
                _buildCustomColorPicker(),
              ],
            ),
          ),

          // Recent and Favorite colors
          if (widget.showRecentColors || widget.showFavoriteColors)
            Container(
              height: 60,
              padding: EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                border: Border(top: BorderSide(color: Colors.grey[300]!)),
              ),
              child: Row(
                children: [
                  if (widget.showRecentColors) ...[
                    Expanded(
                      child: _buildColorSection('Recent', _recentColors),
                    ),
                  ],
                  if (widget.showFavoriteColors) ...[
                    SizedBox(width: 16),
                    Expanded(
                      child: _buildColorSection('Favorites', _favoriteColors),
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildColorGrid(List<Color> colors) {
    return Padding(
      padding: EdgeInsets.all(16),
      child: GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 5,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        itemCount: colors.length,
        itemBuilder: (context, index) {
          final color = colors[index];
          return GestureDetector(
            onTap: () => _selectColor(color),
            onLongPress: () => _showColorOptions(color),
            child: Container(
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.grey,
                  width: color == _currentColor ? 3 : 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: color == _currentColor
                  ? Icon(Icons.check, color: color.computeLuminance() > 0.5 ? Colors.black : Colors.white)
                  : null,
            ),
          );
        },
      ),
    );
  }

  Widget _buildCustomColorPicker() {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          Expanded(
            child: ColorWheelPicker(
              color: _currentColor,
              onColorChanged: (color) {
                setState(() {
                  _currentColor = color;
                });
                widget.onColorChanged(color);
              },
            ),
          ),
          if (widget.showOpacitySlider) ...[
            SizedBox(height: 16),
            Row(
              children: [
                Text('Opacity:'),
                SizedBox(width: 16),
                Expanded(
                  child: Slider(
                    value: _currentColor.opacity,
                    onChanged: (value) {
                      final newColor = _currentColor.withOpacity(value);
                      setState(() {
                        _currentColor = newColor;
                      });
                      widget.onColorChanged(newColor);
                    },
                    min: 0,
                    max: 1,
                  ),
                ),
                SizedBox(width: 8),
                Text('${(_currentColor.opacity * 100).round()}%'),
              ],
            ),
          ],
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  icon: Icon(Icons.favorite_border),
                  label: Text('Add to Favorites'),
                  onPressed: () => _addToFavorites(_currentColor),
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  icon: Icon(Icons.colorize),
                  label: Text('Use Color'),
                  onPressed: () => _selectColor(_currentColor),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildColorSection(String title, List<Color> colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
        SizedBox(height: 4),
        Expanded(
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: colors.length,
            itemBuilder: (context, index) {
              final color = colors[index];
              return GestureDetector(
                onTap: () => _selectColor(color),
                child: Container(
                  width: 30,
                  height: 30,
                  margin: EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.grey),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _selectColor(Color color) {
    setState(() {
      _currentColor = color;
    });
    widget.onColorChanged(color);
    _addToRecent(color);
  }

  void _addToRecent(Color color) {
    if (!_recentColors.contains(color)) {
      setState(() {
        _recentColors.insert(0, color);
        if (_recentColors.length > 10) {
          _recentColors.removeLast();
        }
      });
      widget.onRecentColorsUpdated?.call(_recentColors);
    }
  }

  void _addToFavorites(Color color) {
    if (!_favoriteColors.contains(color)) {
      setState(() {
        _favoriteColors.add(color);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Color added to favorites')),
      );
    }
  }

  void _showColorOptions(Color color) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              title: Text('Color Options'),
              subtitle: Text('RGB: ${color.red}, ${color.green}, ${color.blue}\nHex: ${color.value.toRadixString(16)}'),
            ),
            Divider(),
            ListTile(
              leading: Icon(Icons.favorite_border),
              title: Text('Add to Favorites'),
              onTap: () {
                Navigator.pop(context);
                _addToFavorites(color);
              },
            ),
            ListTile(
              leading: Icon(Icons.content_copy),
              title: Text('Copy Color Code'),
              onTap: () {
                Navigator.pop(context);
                _copyColorCode(color);
              },
            ),
            ListTile(
              leading: Icon(Icons.cancel),
              title: Text('Cancel'),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  void _copyColorCode(Color color) {
    final hexCode = '#${color.value.toRadixString(16).padLeft(8, '0').toUpperCase()}';
    // You would use Clipboard.setData here
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Color code $hexCode copied to clipboard')),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}

// Custom Color Wheel Picker
class ColorWheelPicker extends StatefulWidget {
  final Color color;
  final ValueChanged<Color> onColorChanged;

  const ColorWheelPicker({
    Key? key,
    required this.color,
    required this.onColorChanged,
  }) : super(key: key);

  @override
  _ColorWheelPickerState createState() => _ColorWheelPickerState();
}

class _ColorWheelPickerState extends State<ColorWheelPicker> {
  late Color _currentColor;

  @override
  void initState() {
    super.initState();
    _currentColor = widget.color;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: CustomPaint(
        size: Size(200, 200),
        painter: ColorWheelPainter(
          currentColor: _currentColor,
          onColorChanged: (color) {
            setState(() {
              _currentColor = color;
            });
            widget.onColorChanged(color);
          },
        ),
      ),
    );
  }
}

class ColorWheelPainter extends CustomPainter {
  final Color currentColor;
  final ValueChanged<Color> onColorChanged;

  ColorWheelPainter({
    required this.currentColor,
    required this.onColorChanged,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Draw color wheel
    for (double angle = 0; angle < 360; angle += 1) {
      final hue = angle / 360;
      final color = HSVColor.fromAHSV(1.0, angle, 1.0, 1.0).toColor();

      final paint = Paint()
        ..color = color
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke;

      final startAngle = (angle - 0.5) * (3.14159 / 180);
      final endAngle = (angle + 0.5) * (3.14159 / 180);

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius - 1),
        startAngle,
        endAngle - startAngle,
        false,
        paint,
      );
    }

    // Draw current color indicator
    final indicatorPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    canvas.drawCircle(center, radius - 10, indicatorPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}