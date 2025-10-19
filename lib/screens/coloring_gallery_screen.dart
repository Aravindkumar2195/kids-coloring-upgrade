import 'package:flutter/material.dart';
import '../models/coloring_page.dart';  // Make sure this line exists
import '../models/coloring_data.dart';  // And this one
import '../widgets/coloring_page_item.dart';
import 'coloring_page_screen.dart';

class ColoringGalleryScreen extends StatefulWidget {
  const ColoringGalleryScreen({Key? key}) : super(key: key);

  @override
  _ColoringGalleryScreenState createState() => _ColoringGalleryScreenState();
}

class _ColoringGalleryScreenState extends State<ColoringGalleryScreen> {
  String _selectedCategory = 'All';

  List<ColoringPage> get _filteredPages {
    if (_selectedCategory == 'All') {
      return ColoringData.coloringPages;
    }
    return ColoringData.coloringPages
        .where((page) => page.category == _selectedCategory)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Category Filter
        Container(
          height: 60,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: ColoringData.categories.length,
            itemBuilder: (context, index) {
              final category = ColoringData.categories[index];
              return Padding(
                padding: const EdgeInsets.all(8.0),
                child: FilterChip(
                  label: Text(category),
                  selected: _selectedCategory == category,
                  onSelected: (selected) {
                    setState(() {
                      _selectedCategory = category;
                    });
                  },
                ),
              );
            },
          ),
        ),

        // Grid of Coloring Pages
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.8,
              ),
              itemCount: _filteredPages.length,
              itemBuilder: (context, index) {
                final coloringPage = _filteredPages[index];
                return ColoringPageItem(
                  coloringPage: coloringPage,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ColoringPageScreen(
                          coloringPage: coloringPage,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}