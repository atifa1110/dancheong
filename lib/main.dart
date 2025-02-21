import 'package:flutter/material.dart';
import 'coloring_page.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Coloring App',
      home: ColoringSvgScreen(),
    );
  }
}