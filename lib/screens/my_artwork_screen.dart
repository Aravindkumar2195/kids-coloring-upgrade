import 'package:flutter/material.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class MyArtworkScreen extends StatefulWidget {
  const MyArtworkScreen({Key? key}) : super(key: key);

  @override
  _MyArtworkScreenState createState() => _MyArtworkScreenState();
}

class _MyArtworkScreenState extends State<MyArtworkScreen> {
  List<File> _savedDrawings = [];
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadSavedDrawings();
  }

  Future<void> _loadSavedDrawings() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      await Future.delayed(const Duration(milliseconds: 500)); // Simulate loading

      final Directory appDocDir = await getApplicationDocumentsDirectory();
      final String drawingsPath = '${appDocDir.path}/Drawings';
      final Directory drawingsDir = Directory(drawingsPath);

      if (await drawingsDir.exists()) {
        final List<FileSystemEntity> files = drawingsDir.listSync();
        final List<File> imageFiles = files
            .where((file) => file is File && file.path.toLowerCase().endsWith('.png'))
            .map((file) => file as File)
            .toList();

        // Sort by modification time (newest first)
        imageFiles.sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));

        setState(() {
          _savedDrawings = imageFiles;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load drawings: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _shareDrawing(File imageFile) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
              SizedBox(width: 16),
              Text('Preparing to share...'),
            ],
          ),
          duration: Duration(seconds: 3),
        ),
      );

      await Share.shareXFiles([XFile(imageFile.path)], text: 'My Coloring Drawing');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to share: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _deleteDrawing(File imageFile, int index) async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Drawing?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await imageFile.delete();
        setState(() {
          _savedDrawings.removeAt(index);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Drawing deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildEmptyState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.photo_library_outlined,
          size: 80,
          color: Colors.grey[400],
        ),
        const SizedBox(height: 20),
        Text(
          'No Artwork Yet',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Text(
            'Create your first masterpiece! Draw something and save it to see your artwork here.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[500],
            ),
          ),
        ),
        const SizedBox(height: 30),
        ElevatedButton.icon(
          onPressed: () {
            // Navigate to drawing screen
            Navigator.pop(context);
          },
          icon: const Icon(Icons.brush),
          label: const Text('Start Drawing'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.deepPurple,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.error_outline,
          size: 80,
          color: Colors.red[400],
        ),
        const SizedBox(height: 20),
        Text(
          'Oops!',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.red[600],
          ),
        ),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Text(
            _errorMessage,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
        ),
        const SizedBox(height: 30),
        ElevatedButton.icon(
          onPressed: _loadSavedDrawings,
          icon: const Icon(Icons.refresh),
          label: const Text('Try Again'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.deepPurple,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Artwork'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          if (_savedDrawings.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadSavedDrawings,
              tooltip: 'Refresh',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.deepPurple),
            ),
            SizedBox(height: 16),
            Text(
              'Loading your artwork...',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      )
          : _errorMessage.isNotEmpty
          ? _buildErrorState()
          : _savedDrawings.isEmpty
          ? _buildEmptyState()
          : RefreshIndicator(
        onRefresh: _loadSavedDrawings,
        color: Colors.deepPurple,
        child: GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 0.8,
          ),
          itemCount: _savedDrawings.length,
          itemBuilder: (context, index) {
            final drawing = _savedDrawings[index];
            final fileName = drawing.path.split('/').last;
            final date = File(drawing.path).lastModifiedSync();

            return Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(12),
                        topRight: Radius.circular(12),
                      ),
                      child: Image.file(
                        drawing,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey[200],
                            child: const Center(
                              child: Icon(Icons.broken_image, size: 40),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      '${date.day}/${date.month}/${date.year}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  ButtonBar(
                    alignment: MainAxisAlignment.spaceEvenly,
                    buttonHeight: 40,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.share, size: 20),
                        onPressed: () => _shareDrawing(drawing),
                        tooltip: 'Share',
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, size: 20),
                        onPressed: () => _deleteDrawing(drawing, index),
                        tooltip: 'Delete',
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}