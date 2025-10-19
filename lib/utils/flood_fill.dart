import 'dart:ui' as ui;
import 'dart:typed_data';
import 'dart:collection';
import 'package:flutter/material.dart';

/// Advanced Flood Fill implementation with multiple algorithms and performance optimizations
class FloodFill {
  /// Original flood fill method - maintained for backward compatibility
  static Future<List<Offset>> performFloodFill({
    required ui.Image image,
    required Offset startPoint,
    required Color targetColor,
    required Color replacementColor,
    int tolerance = 10,
  }) async {
    final List<Offset> filledPixels = [];

    final int width = image.width;
    final int height = image.height;

    final int startX = startPoint.dx.toInt().clamp(0, width - 1);
    final int startY = startPoint.dy.toInt().clamp(0, height - 1);

    final ByteData? byteData = await image.toByteData();
    if (byteData == null) return filledPixels;

    final Uint8List pixels = byteData.buffer.asUint8List();

    // Simple 4-direction flood fill
    final List<Offset> queue = [];
    final Set<String> visited = {};

    Color getPixelColor(int x, int y) {
      final int index = (y * width + x) * 4;
      if (index < 0 || index + 3 >= pixels.length) {
        return const Color(0x00000000);
      }

      return Color.fromARGB(
        pixels[index + 3],
        pixels[index + 0],
        pixels[index + 1],
        pixels[index + 2],
      );
    }

    bool colorsSimilar(Color c1, Color c2) {
      return (c1.red - c2.red).abs() <= tolerance &&
          (c1.green - c2.green).abs() <= tolerance &&
          (c1.blue - c2.blue).abs() <= tolerance &&
          (c1.alpha - c2.alpha).abs() <= tolerance;
    }

    final Color startColor = getPixelColor(startX, startY);

    // Don't fill if already the same color
    if (colorsSimilar(startColor, replacementColor)) {
      return filledPixels;
    }

    queue.add(Offset(startX.toDouble(), startY.toDouble()));
    visited.add('$startX,$startY');

    while (queue.isNotEmpty) {
      final Offset current = queue.removeAt(0);
      final int x = current.dx.toInt();
      final int y = current.dy.toInt();

      if (x < 0 || x >= width || y < 0 || y >= height) continue;

      final Color currentColor = getPixelColor(x, y);
      if (!colorsSimilar(currentColor, startColor)) continue;

      filledPixels.add(Offset(x.toDouble(), y.toDouble()));

      // Check 4-directional neighbors
      final neighbors = [
        Offset((x - 1).toDouble(), y.toDouble()), // left
        Offset((x + 1).toDouble(), y.toDouble()), // right
        Offset(x.toDouble(), (y - 1).toDouble()), // up
        Offset(x.toDouble(), (y + 1).toDouble()), // down
      ];

      for (final neighbor in neighbors) {
        final int nx = neighbor.dx.toInt();
        final int ny = neighbor.dy.toInt();
        final String key = '$nx,$ny';

        if (nx >= 0 && nx < width && ny >= 0 && ny < height &&
            !visited.contains(key)) {
          visited.add(key);
          queue.add(neighbor);
        }
      }
    }

    return filledPixels;
  }

  /// NEW: Enhanced flood fill that returns a modified image with better performance
  static Future<ui.Image> performFloodFillToImage({
    required ui.Image image,
    required Offset startPoint,
    required Color replacementColor,
    int tolerance = 10,
    bool use8Direction = true,
  }) async {
    final ByteData? byteData = await image.toByteData();
    if (byteData == null) return image;

    final Uint8List pixels = byteData.buffer.asUint8List();
    final int width = image.width;
    final int height = image.height;

    // Create a copy of pixels to modify
    final Uint8List newPixels = Uint8List.fromList(pixels);

    // Perform flood fill
    await _floodFill(
      newPixels,
      startPoint,
      replacementColor,
      tolerance,
      width,
      height,
      use8Direction,
    );

    // Convert back to image
    return await _uint8ListToImage(newPixels, width, height);
  }

  /// NEW: Fast flood fill algorithm with configurable direction
  static Future<void> _floodFill(
      Uint8List pixels,
      Offset startPoint,
      Color replacementColor,
      int tolerance,
      int width,
      int height,
      bool use8Direction,
      ) async {
    final int startX = startPoint.dx.toInt().clamp(0, width - 1);
    final int startY = startPoint.dy.toInt().clamp(0, height - 1);

    final Color startColor = _getPixelColor(pixels, startX, startY, width);

    if (_colorsSimilar(startColor, replacementColor, tolerance)) {
      return;
    }

    final Queue<Offset> queue = Queue();
    final Set<String> visited = {};

    queue.add(Offset(startX.toDouble(), startY.toDouble()));
    visited.add('$startX,$startY');

    while (queue.isNotEmpty) {
      final Offset current = queue.removeFirst();
      final int x = current.dx.toInt();
      final int y = current.dy.toInt();

      if (!_isWithinBounds(x, y, width, height)) continue;

      final Color currentColor = _getPixelColor(pixels, x, y, width);
      if (!_colorsSimilar(currentColor, startColor, tolerance)) continue;

      // Set the pixel color
      _setPixelColor(pixels, x, y, replacementColor, width);

      // Generate neighbors based on direction setting
      final neighbors = use8Direction ? [
        Offset((x - 1).toDouble(), y.toDouble()), // left
        Offset((x + 1).toDouble(), y.toDouble()), // right
        Offset(x.toDouble(), (y - 1).toDouble()), // up
        Offset(x.toDouble(), (y + 1).toDouble()), // down
        Offset((x - 1).toDouble(), (y - 1).toDouble()), // top-left
        Offset((x + 1).toDouble(), (y - 1).toDouble()), // top-right
        Offset((x - 1).toDouble(), (y + 1).toDouble()), // bottom-left
        Offset((x + 1).toDouble(), (y + 1).toDouble()), // bottom-right
      ] : [
        Offset((x - 1).toDouble(), y.toDouble()), // left
        Offset((x + 1).toDouble(), y.toDouble()), // right
        Offset(x.toDouble(), (y - 1).toDouble()), // up
        Offset(x.toDouble(), (y + 1).toDouble()), // down
      ];

      for (final neighbor in neighbors) {
        final int nx = neighbor.dx.toInt();
        final int ny = neighbor.dy.toInt();
        final String key = '$nx,$ny';

        if (_isWithinBounds(nx, ny, width, height) &&
            !visited.contains(key)) {
          visited.add(key);
          queue.add(neighbor);
        }
      }
    }
  }

  /// NEW: Boundary fill algorithm for alternative approach
  static Future<ui.Image> performBoundaryFill({
    required ui.Image image,
    required Offset startPoint,
    required Color boundaryColor,
    required Color fillColor,
    int tolerance = 10,
  }) async {
    final ByteData? byteData = await image.toByteData();
    if (byteData == null) return image;

    final Uint8List pixels = byteData.buffer.asUint8List();
    final int width = image.width;
    final int height = image.height;

    final Uint8List newPixels = Uint8List.fromList(pixels);

    await _boundaryFill(
      newPixels,
      startPoint,
      boundaryColor,
      fillColor,
      tolerance,
      width,
      height,
    );

    return await _uint8ListToImage(newPixels, width, height);
  }

  static Future<void> _boundaryFill(
      Uint8List pixels,
      Offset startPoint,
      Color boundaryColor,
      Color fillColor,
      int tolerance,
      int width,
      int height,
      ) async {
    final int startX = startPoint.dx.toInt().clamp(0, width - 1);
    final int startY = startPoint.dy.toInt().clamp(0, height - 1);

    final Queue<Offset> queue = Queue();
    final Set<String> visited = {};

    queue.add(Offset(startX.toDouble(), startY.toDouble()));
    visited.add('$startX,$startY');

    while (queue.isNotEmpty) {
      final Offset current = queue.removeFirst();
      final int x = current.dx.toInt();
      final int y = current.dy.toInt();

      if (!_isWithinBounds(x, y, width, height)) continue;

      final Color currentColor = _getPixelColor(pixels, x, y, width);

      // Fill if not boundary color and not already filled
      if (!_colorsSimilar(currentColor, boundaryColor, tolerance) &&
          !_colorsSimilar(currentColor, fillColor, tolerance)) {

        _setPixelColor(pixels, x, y, fillColor, width);

        final neighbors = [
          Offset((x - 1).toDouble(), y.toDouble()),
          Offset((x + 1).toDouble(), y.toDouble()),
          Offset(x.toDouble(), (y - 1).toDouble()),
          Offset(x.toDouble(), (y + 1).toDouble()),
        ];

        for (final neighbor in neighbors) {
          final int nx = neighbor.dx.toInt();
          final int ny = neighbor.dy.toInt();
          final String key = '$nx,$ny';

          if (_isWithinBounds(nx, ny, width, height) &&
              !visited.contains(key)) {
            visited.add(key);
            queue.add(neighbor);
          }
        }
      }
    }
  }

  // Utility methods
  static bool _isWithinBounds(int x, int y, int width, int height) {
    return x >= 0 && x < width && y >= 0 && y < height;
  }

  static Color _getPixelColor(Uint8List pixels, int x, int y, int width) {
    final int index = (y * width + x) * 4;
    if (index < 0 || index + 3 >= pixels.length) {
      return const Color(0x00000000);
    }
    return Color.fromARGB(
      pixels[index + 3],
      pixels[index + 0],
      pixels[index + 1],
      pixels[index + 2],
    );
  }

  static void _setPixelColor(
      Uint8List pixels,
      int x,
      int y,
      Color color,
      int width
      ) {
    final int index = (y * width + x) * 4;
    if (index >= 0 && index + 3 < pixels.length) {
      pixels[index + 0] = color.red;
      pixels[index + 1] = color.green;
      pixels[index + 2] = color.blue;
      pixels[index + 3] = color.alpha;
    }
  }

  static bool _colorsSimilar(Color c1, Color c2, int tolerance) {
    return (c1.red - c2.red).abs() <= tolerance &&
        (c1.green - c2.green).abs() <= tolerance &&
        (c1.blue - c2.blue).abs() <= tolerance &&
        (c1.alpha - c2.alpha).abs() <= tolerance;
  }

  static Future<ui.Image> _uint8ListToImage(
      Uint8List pixels,
      int width,
      int height
      ) async {
    final Completer<ui.Image> completer = Completer();
    ui.decodeImageFromPixels(
      pixels,
      width,
      height,
      ui.PixelFormat.rgba8888,
          (ui.Image image) {
        completer.complete(image);
      },
    );
    return completer.future;
  }

  /// NEW: Get image dimensions
  static Size getImageSize(ui.Image image) {
    return Size(image.width.toDouble(), image.height.toDouble());
  }

  /// NEW: Check if point is within image bounds
  static bool isPointInImage(ui.Image image, Offset point) {
    return point.dx >= 0 &&
        point.dx < image.width &&
        point.dy >= 0 &&
        point.dy < image.height;
  }
}