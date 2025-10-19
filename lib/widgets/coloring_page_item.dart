import 'package:flutter/material.dart';
import '../models/coloring_page.dart';

class ColoringPageItem extends StatelessWidget {
  final ColoringPage coloringPage;
  final VoidCallback onTap;

  const ColoringPageItem({
    Key? key,
    required this.coloringPage,
    required this.onTap,
  }) : super(key: key);

  // Function to generate a color based on the page title
  Color _getColorFromTitle(String title) {
    final colors = [
      Colors.red[100]!,
      Colors.blue[100]!,
      Colors.green[100]!,
      Colors.yellow[100]!,
      Colors.purple[100]!,
      Colors.orange[100]!,
      Colors.pink[100]!,
      Colors.teal[100]!,
    ];

    int index = title.codeUnits.fold(0, (a, b) => a + b) % colors.length;
    return colors[index];
  }

  // Function to get an appropriate icon based on category
  IconData _getIconFromCategory(String category) {
    switch (category) {
      case 'Animals':
        return Icons.pets;
      case 'Nature':
        return Icons.nature;
      case 'Fantasy':
        return Icons.auto_awesome;
      case 'Vehicles':
        return Icons.directions_car;
      default:
        return Icons.image;
    }
  }

  @override
  Widget build(BuildContext context) {
    final backgroundColor = _getColorFromTitle(coloringPage.title);
    final icon = _getIconFromCategory(coloringPage.category);

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          children: [
            // Image or colored background with icon
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: backgroundColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                ),
                child: Stack(
                  children: [
                    // Try to load image, fallback to icon if image doesn't exist
                    // For now, we'll use the colored background with icon
                    // Later, replace this with actual image loading:
                    // Image.asset(
                    //   coloringPage.imagePath,
                    //   fit: BoxFit.cover,
                    //   width: double.infinity,
                    //   height: double.infinity,
                    //   errorBuilder: (context, error, stackTrace) {
                    //     return _buildPlaceholder(backgroundColor, icon, coloringPage.title);
                    //   },
                    // ),
                    _buildPlaceholder(backgroundColor, icon, coloringPage.title),
                  ],
                ),
              ),
            ),
            // Category label at bottom
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
              ),
              child: Text(
                coloringPage.category,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.black54,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder(Color backgroundColor, IconData icon, String title) {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 40,
              color: Colors.black54,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.black54,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}