import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class ShareManager {
  static const List<Map<String, dynamic>> exportFormats = [
    {'name': 'PNG', 'extension': '.png', 'quality': 100},
    {'name': 'JPEG', 'extension': '.jpg', 'quality': 90},
    {'name': 'WEBP', 'extension': '.webp', 'quality': 80},
  ];

  /// Share drawing to social media and other apps
  static Future<ShareResult> shareDrawing({
    required ui.Image image,
    required String title,
    String message = 'Check out my amazing drawing! 🎨',
    List<String>? hashtags,
    String format = 'PNG',
  }) async {
    try {
      final formatInfo = exportFormats.firstWhere(
            (f) => f['name'] == format,
        orElse: () => exportFormats.first,
      );

      final byteData = await image.toByteData(
        format: format == 'PNG' ? ui.ImageByteFormat.png : ui.ImageByteFormat.jpg,
      );

      if (byteData == null) {
        return ShareResult(success: false, error: 'Failed to convert image to bytes');
      }

      final tempDir = await getTemporaryDirectory();
      final fileName = '${_sanitizeFileName(title)}_${DateTime.now().millisecondsSinceEpoch}${formatInfo['extension']}';
      final file = File('${tempDir.path}/$fileName');

      await file.writeAsBytes(byteData.buffer.asUint8List());

      // Prepare share text with hashtags
      String shareText = message;
      if (hashtags != null && hashtags.isNotEmpty) {
        shareText += '\n\n${hashtags.map((h) => '#$h').join(' ')}';
      }

      final result = await Share.shareFiles(
        [file.path],
        text: shareText,
        subject: title,
      );

      return ShareResult(
        success: true,
        filePath: file.path,
        shareActivity: result.activity,
      );
    } catch (e) {
      print('Error sharing drawing: $e');
      return ShareResult(success: false, error: e.toString());
    }
  }

  /// Save drawing to app's documents directory
  static Future<SaveResult> saveToGallery({
    required ui.Image image,
    required String name,
    String format = 'PNG',
    int quality = 90,
  }) async {
    try {
      // Request storage permission
      final status = await Permission.storage.request();
      if (!status.isGranted) {
        return SaveResult(success: false, error: 'Storage permission denied');
      }

      final byteData = await image.toByteData(
        format: format == 'PNG' ? ui.ImageByteFormat.png : ui.ImageByteFormat.jpg,
      );

      if (byteData == null) {
        return SaveResult(success: false, error: 'Failed to convert image to bytes');
      }

      // Save to app documents directory
      final directory = await getApplicationDocumentsDirectory();
      final drawingsDir = Directory('${directory.path}/drawings');
      if (!await drawingsDir.exists()) {
        await drawingsDir.create(recursive: true);
      }

      final fileName = '${_sanitizeFileName(name)}_${DateTime.now().millisecondsSinceEpoch}.${format.toLowerCase()}';
      final file = File('${drawingsDir.path}/$fileName');

      await file.writeAsBytes(byteData.buffer.asUint8List());

      // Create metadata
      final metadata = {
        'fileName': fileName,
        'title': name,
        'savedAt': DateTime.now().toIso8601String(),
        'format': format,
        'fileSize': file.lengthSync(),
        'dimensions': {'width': image.width, 'height': image.height},
      };

      final metadataFile = File('${drawingsDir.path}/${fileName}_metadata.json');
      await metadataFile.writeAsString(json.encode(metadata));

      return SaveResult(
        success: true,
        filePath: file.path,
        fileName: fileName,
        metadata: metadata,
      );
    } catch (e) {
      print('Error saving drawing: $e');
      return SaveResult(success: false, error: e.toString());
    }
  }

  /// Export drawing to file with multiple format options
  static Future<ExportResult> exportDrawing({
    required ui.Image image,
    required String fileName,
    String format = 'PNG',
    int quality = 90,
    bool includeMetadata = true,
  }) async {
    try {
      final formatInfo = exportFormats.firstWhere(
            (f) => f['name'] == format,
        orElse: () => exportFormats.first,
      );

      final byteData = await image.toByteData(
        format: format == 'PNG' ? ui.ImageByteFormat.png : ui.ImageByteFormat.jpg,
      );

      if (byteData == null) {
        return ExportResult(success: false, error: 'Failed to convert image to bytes');
      }

      final directory = await getApplicationDocumentsDirectory();
      final exportsDir = Directory('${directory.path}/exports');
      if (!await exportsDir.exists()) {
        await exportsDir.create(recursive: true);
      }

      final safeFileName = _sanitizeFileName(fileName);
      final fileExtension = formatInfo['extension'];
      final fullFileName = '$safeFileName$fileExtension';

      final file = File('${exportsDir.path}/$fullFileName');
      await file.writeAsBytes(byteData.buffer.asUint8List());

      // Create metadata file if requested
      Map<String, dynamic>? metadata;
      if (includeMetadata) {
        metadata = {
          'fileName': fullFileName,
          'format': format,
          'quality': quality,
          'exportedAt': DateTime.now().toIso8601String(),
          'imageWidth': image.width,
          'imageHeight': image.height,
          'fileSize': file.lengthSync(),
        };

        final metadataFile = File('${exportsDir.path}/${safeFileName}_metadata.json');
        await metadataFile.writeAsString(json.encode(metadata));
      }

      return ExportResult(
        success: true,
        filePath: file.path,
        fileName: fullFileName,
        fileSize: file.lengthSync(),
        format: format,
        metadata: metadata,
      );
    } catch (e) {
      print('Error exporting drawing: $e');
      return ExportResult(success: false, error: e.toString());
    }
  }

  /// Get list of saved drawings
  static Future<List<SavedDrawing>> getSavedDrawings() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final drawingsDir = Directory('${directory.path}/drawings');

      if (!await drawingsDir.exists()) {
        return [];
      }

      final files = await drawingsDir.list().toList();

      final drawingFiles = files.where((file) {
        final path = file.path.toLowerCase();
        return path.endsWith('.png') ||
            path.endsWith('.jpg') ||
            path.endsWith('.jpeg') ||
            path.endsWith('.webp');
      }).toList();

      final List<SavedDrawing> savedDrawings = [];

      for (final file in drawingFiles) {
        try {
          final fileStat = await file.stat();
          final metadataFile = File('${file.path}_metadata.json');

          Map<String, dynamic> metadata = {};
          if (await metadataFile.exists()) {
            try {
              final metadataContent = await metadataFile.readAsString();
              metadata = json.decode(metadataContent);
            } catch (e) {
              print('Error reading metadata for ${file.path}: $e');
            }
          }

          savedDrawings.add(SavedDrawing(
            filePath: file.path,
            fileName: file.uri.pathSegments.last,
            fileSize: fileStat.size,
            savedAt: fileStat.modified,
            metadata: metadata,
            thumbnail: await _createThumbnail(File(file.path)),
          ));
        } catch (e) {
          print('Error processing file ${file.path}: $e');
        }
      }

      // Sort by modification date, newest first
      savedDrawings.sort((a, b) => b.savedAt.compareTo(a.savedAt));

      return savedDrawings;
    } catch (e) {
      print('Error getting saved drawings: $e');
      return [];
    }
  }

  /// Get list of exported drawings
  static Future<List<ExportedFile>> getExportedDrawings() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final exportsDir = Directory('${directory.path}/exports');

      if (!await exportsDir.exists()) {
        return [];
      }

      final files = await exportsDir.list().toList();

      final drawingFiles = files.where((file) {
        final path = file.path.toLowerCase();
        return path.endsWith('.png') ||
            path.endsWith('.jpg') ||
            path.endsWith('.jpeg') ||
            path.endsWith('.webp');
      }).toList();

      final List<ExportedFile> exportedFiles = [];

      for (final file in drawingFiles) {
        final fileStat = await file.stat();
        final metadataFile = File('${file.path}_metadata.json');

        Map<String, dynamic>? metadata;
        if (await metadataFile.exists()) {
          try {
            final metadataContent = await metadataFile.readAsString();
            metadata = json.decode(metadataContent);
          } catch (e) {
            print('Error reading metadata for ${file.path}: $e');
          }
        }

        exportedFiles.add(ExportedFile(
          filePath: file.path,
          fileName: file.uri.pathSegments.last,
          fileSize: fileStat.size,
          modifiedAt: fileStat.modified,
          metadata: metadata,
        ));
      }

      // Sort by modification date, newest first
      exportedFiles.sort((a, b) => b.modifiedAt.compareTo(a.modifiedAt));

      return exportedFiles;
    } catch (e) {
      print('Error getting exported drawings: $e');
      return [];
    }
  }

  /// Delete saved drawing
  static Future<bool> deleteSavedDrawing(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();

        // Also delete metadata file if it exists
        final metadataPath = '${filePath}_metadata.json';
        final metadataFile = File(metadataPath);
        if (await metadataFile.exists()) {
          await metadataFile.delete();
        }

        return true;
      }
      return false;
    } catch (e) {
      print('Error deleting saved drawing: $e');
      return false;
    }
  }

  /// Delete exported drawing
  static Future<bool> deleteExportedDrawing(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();

        // Also delete metadata file if it exists
        final metadataPath = filePath.replaceAll(RegExp(r'\.(png|jpg|jpeg|webp)$'), '_metadata.json');
        final metadataFile = File(metadataPath);
        if (await metadataFile.exists()) {
          await metadataFile.delete();
        }

        return true;
      }
      return false;
    } catch (e) {
      print('Error deleting exported drawing: $e');
      return false;
    }
  }

  /// Create drawing preview for sharing
  static Future<Uint8List?> createDrawingPreview({
    required ui.Image image,
    Size size = const Size(300, 300),
    Color backgroundColor = Colors.white,
    bool addWatermark = false,
  }) async {
    try {
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);

      // Draw background
      final backgroundPaint = Paint()..color = backgroundColor;
      canvas.drawRect(
        Rect.fromLTWH(0, 0, size.width, size.height),
        backgroundPaint,
      );

      // Calculate scale to fit image while maintaining aspect ratio
      final imageRatio = image.width / image.height;
      final targetRatio = size.width / size.height;

      double scale;
      double dx = 0, dy = 0;

      if (imageRatio > targetRatio) {
        scale = size.width / image.width;
        dy = (size.height - image.height * scale) / 2;
      } else {
        scale = size.height / image.height;
        dx = (size.width - image.width * scale) / 2;
      }

      canvas.translate(dx, dy);
      canvas.scale(scale);

      // Draw the image
      canvas.drawImage(image, Offset.zero, Paint());

      // Add watermark if requested
      if (addWatermark) {
        final textPainter = TextPainter(
          text: TextSpan(
            text: 'Created with Coloring App',
            style: TextStyle(
              color: Colors.black54,
              fontSize: 12,
              fontStyle: FontStyle.italic,
            ),
          ),
          textDirection: TextDirection.ltr,
        );

        textPainter.layout();
        textPainter.paint(
          canvas,
          Offset(size.width - textPainter.width - 10, size.height - textPainter.height - 10),
        );
      }

      final picture = recorder.endRecording();
      final previewImage = await picture.toImage(size.width.toInt(), size.height.toInt());
      final byteData = await previewImage.toByteData(format: ui.ImageByteFormat.png);

      return byteData?.buffer.asUint8List();
    } catch (e) {
      print('Error creating drawing preview: $e');
      return null;
    }
  }

  /// Create thumbnail for saved drawing
  static Future<Uint8List?> _createThumbnail(File imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      final image = frame.image;

      final thumbnailSize = Size(100, 100);
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);

      // Calculate scale to fit while maintaining aspect ratio
      final imageRatio = image.width / image.height;
      final targetRatio = thumbnailSize.width / thumbnailSize.height;

      double scale;
      double dx = 0, dy = 0;

      if (imageRatio > targetRatio) {
        scale = thumbnailSize.width / image.width;
        dy = (thumbnailSize.height - image.height * scale) / 2;
      } else {
        scale = thumbnailSize.height / image.height;
        dx = (thumbnailSize.width - image.width * scale) / 2;
      }

      canvas.translate(dx, dy);
      canvas.scale(scale);
      canvas.drawImage(image, Offset.zero, Paint());

      final picture = recorder.endRecording();
      final thumbnailImage = await picture.toImage(
        thumbnailSize.width.toInt(),
        thumbnailSize.height.toInt(),
      );

      final byteData = await thumbnailImage.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (e) {
      print('Error creating thumbnail: $e');
      return null;
    }
  }

  // Utility methods
  static String _sanitizeFileName(String name) {
    return name.replaceAll(RegExp(r'[^a-zA-Z0-9_\-\s]'), '_').replaceAll(RegExp(r'\s+'), '_');
  }

  /// Get available storage space
  static Future<int> getAvailableStorage() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final stat = FileStat.statSync(directory.path);
      return stat.size;
    } catch (e) {
      return 0;
    }
  }

  /// Clear all saved drawings
  static Future<void> clearAllSavedDrawings() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final drawingsDir = Directory('${directory.path}/drawings');
      if (await drawingsDir.exists()) {
        await drawingsDir.delete(recursive: true);
      }
    } catch (e) {
      print('Error clearing saved drawings: $e');
    }
  }

  /// Clear all exported drawings
  static Future<void> clearAllExportedDrawings() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final exportsDir = Directory('${directory.path}/exports');
      if (await exportsDir.exists()) {
        await exportsDir.delete(recursive: true);
      }
    } catch (e) {
      print('Error clearing exported drawings: $e');
    }
  }
}

// Result classes for better error handling
class ShareResult {
  final bool success;
  final String? filePath;
  final String? shareActivity;
  final String? error;

  ShareResult({
    required this.success,
    this.filePath,
    this.shareActivity,
    this.error,
  });
}

class SaveResult {
  final bool success;
  final String? filePath;
  final String? fileName;
  final Map<String, dynamic>? metadata;
  final String? error;

  SaveResult({
    required this.success,
    this.filePath,
    this.fileName,
    this.metadata,
    this.error,
  });
}

class ExportResult {
  final bool success;
  final String? filePath;
  final String? fileName;
  final int? fileSize;
  final String? format;
  final Map<String, dynamic>? metadata;
  final String? error;

  ExportResult({
    required this.success,
    this.filePath,
    this.fileName,
    this.fileSize,
    this.format,
    this.metadata,
    this.error,
  });
}

class SavedDrawing {
  final String filePath;
  final String fileName;
  final int fileSize;
  final DateTime savedAt;
  final Map<String, dynamic> metadata;
  final Uint8List? thumbnail;

  SavedDrawing({
    required this.filePath,
    required this.fileName,
    required this.fileSize,
    required this.savedAt,
    required this.metadata,
    this.thumbnail,
  });

  String get readableSize {
    if (fileSize < 1024) return '$fileSize B';
    if (fileSize < 1024 * 1024) return '${(fileSize / 1024).toStringAsFixed(1)} KB';
    return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  String get format {
    final ext = fileName.toLowerCase().split('.').last;
    return ext.toUpperCase();
  }

  String get title {
    return metadata['title'] ?? fileName.split('_').first;
  }
}

class ExportedFile {
  final String filePath;
  final String fileName;
  final int fileSize;
  final DateTime modifiedAt;
  final Map<String, dynamic>? metadata;

  ExportedFile({
    required this.filePath,
    required this.fileName,
    required this.fileSize,
    required this.modifiedAt,
    this.metadata,
  });

  String get readableSize {
    if (fileSize < 1024) return '$fileSize B';
    if (fileSize < 1024 * 1024) return '${(fileSize / 1024).toStringAsFixed(1)} KB';
    return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  String get format {
    final ext = fileName.toLowerCase().split('.').last;
    return ext.toUpperCase();
  }
}