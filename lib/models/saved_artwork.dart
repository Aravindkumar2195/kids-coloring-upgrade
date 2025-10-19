import 'dart:io';

class SavedArtwork {
  final String id;
  final String title;
  final File imageFile;
  final DateTime savedDate;
  final String? coloringPageId;

  SavedArtwork({
    required this.id,
    required this.title,
    required this.imageFile,
    required this.savedDate,
    this.coloringPageId,
  });

  String get displayDate {
    final now = DateTime.now();
    final difference = now.difference(savedDate);

    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes} min ago';
    if (difference.inHours < 24) return '${difference.inHours} hours ago';
    if (difference.inDays < 7) return '${difference.inDays} days ago';

    return '${savedDate.day}/${savedDate.month}/${savedDate.year}';
  }
}