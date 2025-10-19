import 'package:flutter/material.dart';

enum DrawingType {
  pen,
  eraser,
  fill,
  circle,
  rectangle,
  line,
}

class DrawingPoint {
  List<Offset> points;
  Color color;
  double strokeWidth;
  DrawingType type;
  Rect? shapeRect; // For shapes like rectangle, circle
  bool isFill; // Whether shape should be filled

  DrawingPoint({
    required this.points,
    required this.color,
    required this.strokeWidth,
    this.type = DrawingType.pen,
    this.shapeRect,
    this.isFill = false,
  });
}