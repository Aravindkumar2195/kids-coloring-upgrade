class ColoringPage {
  final String id;
  final String title;
  final String imagePath;
  final bool isLocked;
  final String category;

  ColoringPage({
    required this.id,
    required this.title,
    required this.imagePath,
    this.isLocked = false,
    this.category = 'General',
  });
}