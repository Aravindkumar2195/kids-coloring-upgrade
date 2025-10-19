import 'coloring_page.dart';

class ColoringData {
  static List<ColoringPage> get coloringPages => [
    ColoringPage(
      id: '1',
      title: 'Butterfly',
      imagePath: 'assets/images/butterfly.png',
      category: 'Animals',
    ),
    ColoringPage(
      id: '2',
      title: 'Flowers',
      imagePath: 'assets/images/flowers.png',
      category: 'Nature',
    ),
    ColoringPage(
      id: '3',
      title: 'Castle',
      imagePath: 'assets/images/castle.png',
      category: 'Fantasy',
    ),
    ColoringPage(
      id: '4',
      title: 'Dinosaur',
      imagePath: 'assets/images/dinosaur.png',
      category: 'Animals',
    ),
    ColoringPage(
      id: '5',
      title: 'Car',
      imagePath: 'assets/images/car.png',
      category: 'Vehicles',
    ),
    ColoringPage(
      id: '6',
      title: 'Unicorn',
      imagePath: 'assets/images/unicorn.png',
      category: 'Fantasy',
    ),
  ];

  static List<String> get categories => [
    'All',
    'Animals',
    'Nature',
    'Fantasy',
    'Vehicles',
  ];
}