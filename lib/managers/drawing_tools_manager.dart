import 'dart:ui' as ui;
import 'package:flutter/material.dart';

enum DrawingTool {
  brush,
  eraser,
  fill,
  shapes,
  text,
  highlighter,
  spray,
  stamp,
}

enum ShapeType {
  circle,
  rectangle,
  line,
  triangle,
  star,
  heart,
}

enum BrushType {
  normal,
  calligraphy,
  airbrush,
  charcoal,
  watercolor,
}

class DrawingToolManager {
  // Current tool settings
  DrawingTool currentTool = DrawingTool.brush;
  Color currentColor = Colors.black;
  double brushSize = 5.0;
  ShapeType selectedShape = ShapeType.circle;
  BrushType selectedBrush = BrushType.normal;

  // Tool properties
  double opacity = 1.0;
  double smoothness = 0.5;
  bool pressureSensitive = false;

  // Fill properties
  int fillTolerance = 10;
  bool use8DirectionFill = true;

  // Shape properties
  bool fillShapes = true;
  Color shapeFillColor = Colors.transparent;
  double shapeBorderWidth = 2.0;

  // Text properties
  String textContent = '';
  double textSize = 16.0;
  String selectedFont = 'Arial';

  // History management
  final List<DrawingState> undoStack = [];
  final List<DrawingState> redoStack = [];
  final int maxHistorySteps = 50;

  // Preferences
  bool autoSave = true;
  int autoSaveInterval = 30; // seconds
  String defaultFormat = 'PNG';

  // Tool methods
  void changeTool(DrawingTool tool) {
    _saveCurrentState();
    currentTool = tool;
  }

  void changeColor(Color color) {
    currentColor = color.withOpacity(opacity);
  }

  void changeBrushSize(double size) {
    brushSize = size.clamp(0.1, 100.0);
  }

  void changeOpacity(double value) {
    opacity = value.clamp(0.0, 1.0);
    currentColor = currentColor.withOpacity(opacity);
  }

  void changeBrushType(BrushType brush) {
    selectedBrush = brush;
    _adjustBrushForType();
  }

  void changeShapeType(ShapeType shape) {
    selectedShape = shape;
  }

  // History management methods
  void _saveCurrentState() {
    // This will be implemented when integrated with drawing canvas
  }

  void saveState(ui.Image currentImage, List<dynamic> drawingData) {
    if (undoStack.length >= maxHistorySteps) {
      undoStack.removeAt(0);
    }

    undoStack.add(DrawingState(
      image: currentImage,
      drawingData: List.from(drawingData),
      timestamp: DateTime.now(),
    ));

    // Clear redo stack when new action is performed
    redoStack.clear();
  }

  DrawingState? undo() {
    if (canUndo) {
      final state = undoStack.removeLast();
      redoStack.add(state);
      return state;
    }
    return null;
  }

  DrawingState? redo() {
    if (canRedo) {
      final state = redoStack.removeLast();
      undoStack.add(state);
      return state;
    }
    return null;
  }

  void clearHistory() {
    undoStack.clear();
    redoStack.clear();
  }

  // Utility methods
  void _adjustBrushForType() {
    switch (selectedBrush) {
      case BrushType.normal:
        smoothness = 0.5;
        break;
      case BrushType.calligraphy:
        smoothness = 0.8;
        break;
      case BrushType.airbrush:
        smoothness = 0.3;
        opacity = 0.7;
        break;
      case BrushType.charcoal:
        smoothness = 0.6;
        break;
      case BrushType.watercolor:
        smoothness = 0.4;
        opacity = 0.8;
        break;
    }
  }

  // Getters
  bool get canUndo => undoStack.isNotEmpty;
  bool get canRedo => redoStack.isNotEmpty;
  int get undoCount => undoStack.length;
  int get redoCount => redoStack.length;

  // Export settings
  Map<String, dynamic> toJson() {
    return {
      'currentTool': currentTool.toString(),
      'currentColor': {
        'red': currentColor.red,
        'green': currentColor.green,
        'blue': currentColor.blue,
        'alpha': currentColor.alpha,
      },
      'brushSize': brushSize,
      'selectedShape': selectedShape.toString(),
      'selectedBrush': selectedBrush.toString(),
      'opacity': opacity,
      'fillTolerance': fillTolerance,
      'use8DirectionFill': use8DirectionFill,
    };
  }

  void fromJson(Map<String, dynamic> json) {
    // Implementation for loading from JSON
  }
}

class DrawingState {
  final ui.Image image;
  final List<dynamic> drawingData;
  final DateTime timestamp;

  DrawingState({
    required this.image,
    required this.drawingData,
    required this.timestamp,
  });
}

class DrawingPreferences {
  static const String keyToolSettings = 'drawing_tool_settings';
  static const String keyRecentColors = 'recent_colors';
  static const String keyFavoriteBrushes = 'favorite_brushes';

  static Future<void> saveToolManager(DrawingToolManager manager) async {
    // Implementation using shared_preferences
  }

  static Future<DrawingToolManager?> loadToolManager() async {
    // Implementation using shared_preferences
    return null;
  }
}