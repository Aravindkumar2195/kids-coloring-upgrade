import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class ImageSaver {
  static final ImageSaver _instance = ImageSaver._internal();
  factory ImageSaver() => _instance;
  ImageSaver._internal();

  // Save drawing as image using RepaintBoundary
  Future<String?> saveDrawing(
      GlobalKey repaintKey, {
        String title = 'My Drawing',
      }) async {
    try {
      // Show loading state

      // Capture the drawing using RepaintBoundary
      final boundary = repaintKey.currentContext?.findRenderObject();
      if (boundary == null || boundary is! RenderRepaintBoundary) {
        return 'Unable to capture drawing. Please try again.';
      }

      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);

      if (byteData == null) {
        return 'Failed to process drawing image.';
      }

      final Uint8List imageBytes = byteData.buffer.asUint8List();

      // Get the app's temporary directory
      final Directory tempDir = await getTemporaryDirectory();
      final String fileName = '${title}_${DateTime.now().millisecondsSinceEpoch}.png';
      final String filePath = '${tempDir.path}/$fileName';
      final File imageFile = File(filePath);

      // Save the image
      await imageFile.writeAsBytes(imageBytes);

      // Use share to let user save to gallery or share
      try {
        await Share.shareXFiles(
            [XFile(filePath)],
            text: 'My Coloring Drawing - $title'
        );
      } catch (shareError) {
        // If sharing fails, try to save to app directory as fallback
        final Directory appDocDir = await getApplicationDocumentsDirectory();
        final String drawingsPath = '${appDocDir.path}/Drawings';
        final Directory drawingsDir = Directory(drawingsPath);
        if (!await drawingsDir.exists()) {
          await drawingsDir.create(recursive: true);
        }

        final String fallbackPath = '$drawingsPath/$fileName';
        await imageFile.copy(fallbackPath);

        return 'Drawing saved to app storage! You can find it in My Artwork.';
      }

      // Clean up the temp file after a delay
      Future.delayed(const Duration(seconds: 30), () {
        if (imageFile.existsSync()) {
          imageFile.delete();
        }
      });

      return null; // Success - share sheet is open
    } catch (e) {
      print('Error saving drawing: $e');
      return 'Sorry, we couldn\'t save your drawing. Please try again. Error: ${e.toString().split(':').first}';
    }
  }
}