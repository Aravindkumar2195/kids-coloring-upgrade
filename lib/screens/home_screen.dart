import 'package:flutter/material.dart';
import 'coloring_gallery_screen.dart';
import 'free_draw_screen.dart';
import 'my_artwork_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const ColoringGalleryScreen(),
    const FreeDrawScreen(),
    const MyArtworkScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Coloring & Drawing'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.collections),
            label: 'Gallery',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.brush),
            label: 'Draw',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.photo_library),
            label: 'My Art',
          ),
        ],
      ),
    );
  }
}