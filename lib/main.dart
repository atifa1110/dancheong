import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'coloring_page.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Coloring App',
      home: ImageSelectionScreen(),
    );
  }
}

class ImageSelectionScreen extends StatelessWidget {
  final List<String> images = [
    'assets/kukhwa.svg',
    'assets/moran.svg',
    'assets/namuip.svg',
  ];

  ImageSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Choose Your Coloring Page')),
      body: GridView.builder(
        padding: const EdgeInsets.all(10),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
        ),
        itemCount: images.length,
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ColoringSvgScreen(imagePath: images[index]),
                ),
              );
            },
            child: Card(
              elevation: 5,
              child: SvgPicture.asset(images[index], fit: BoxFit.contain),
            ),
          );
        },
      ),
    );
  }
}
