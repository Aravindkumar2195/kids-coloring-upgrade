import 'dart:ui' as ui;
import 'dart:typed_data'; // Add this import
import 'package:flutter/material.dart';

class FloodFill {
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
}