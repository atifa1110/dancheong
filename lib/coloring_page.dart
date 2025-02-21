import 'package:dancheong/svg_painter.dart';
import 'package:dancheong/utils.dart';
import 'package:dancheong/vector_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:io';

import 'package:path_provider/path_provider.dart';

class ColoringSvgScreen extends StatefulWidget {
  const ColoringSvgScreen({super.key});

  @override
  State<ColoringSvgScreen> createState() => _ColoringSvgScreenState();
}

Future<VectorImage> getVectorImageFromFile(String assetPath) async {
  try {
    String svgData = await rootBundle.loadString(assetPath); // Load from asset
    return getVectorImageFromStringXml(svgData);
  } catch (e) {
    print('Error loading SVG from asset: $e');
    return const VectorImage(items: [], size: Size.zero); // Return empty on error
  }
}

class _ColoringSvgScreenState extends State<ColoringSvgScreen> {

  @override
  void initState() {
    _init();
    super.initState();
  }

  final GlobalKey _globalKey = GlobalKey(); // GlobalKey for RepaintBoundary

  // Function to save the image
  Future<void> _saveImage() async {
    try {
      RenderRepaintBoundary boundary =
      _globalKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage();
      ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      Uint8List pngBytes = byteData!.buffer.asUint8List();

      // Get the external storage directory
      final directory = await getExternalStorageDirectory();
      if (directory!= null) {
        final imagePath = '${directory.path}/colored_image.png';
        final file = File(imagePath);
        await file.writeAsBytes(pngBytes);

        // Show a success message or a dialog
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Image saved successfully!')),
        );
      }
    } catch (e) {
      print('Error saving image: $e');
      // Show an error message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to save image.')),
      );
    }
  }

  Size? _size;
  List<PathSvgItem>? _items;

  static const String assetPathDogWithSmile = 'assets/kukhwa.svg';

  Future<void> _init() async {
    final value = await getVectorImageFromFile(assetPathDogWithSmile);
    setState(() {
      _items = value.items;
      _size = value.size;
    });
  }

  Color _currentColor = Colors.red; // Default color
  final List<Color> _availableColors = [
    Colors.red,
    Colors.green,
    Colors.blue,
    Colors.yellow,
    Colors.purple,
    Colors.orange,
    // Add more colors as needed
  ];

  void _onTap(int index) {
    setState(() {
      _items![index] = _items![index].copyWith(
        fill: _currentColor,
      );
      _items = List.from(_items!); // Important: Create a new list
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Coloring SVG'),
        actions: [
          IconButton(
            onPressed: _saveImage, // Call the save function
            icon: const Icon(Icons.save),
          ),
        ],
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Expanded SVG Picture
          Expanded( // Use Expanded to make the SVG area fill the remaining space
            child: _items == null || _size == null
                ? const Center(child: CircularProgressIndicator())
                : InteractiveViewer(
              child: Center(
                //... (rest of your InteractiveViewer and SVG display code)
                child: FittedBox(
                  child: RepaintBoundary(
                    key : _globalKey,
                    child: SizedBox(
                      width: _size!.width,
                      height: _size!.height,
                      child: Stack(
                        children: [
                          for (int index = 0; index < _items!.length; index++)
                            SvgPainterImage( // No GestureDetector needed
                              item: _items![index],
                              size: _size!,
                              onTap: () => _onTap(index), // Pass the _onTap callback
                            )
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Color Selection List
          Container(
            height: 120,
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              border: Border.all(
                color: Colors.grey,
                width: 1,
              ),
            ),
            child: Row(
              children: [
                const SizedBox(width: 16),
                const SizedBox(
                  width: 120,// Expand the first section to push the text to the middle
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center, // Center the text horizontally
                    children: [
                      Icon(Icons.palette, size: 22, color: Colors.grey),
                      SizedBox(width: 5),
                      Text(
                        'Colors',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 10),
                  width: 1,
                  color: Colors.grey,
                ),
                const SizedBox(width: 16),
                Expanded( // Expand the ListView to fill available space
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.only(left: 50, right: 50), // Add left padding for "Colors" text
                    itemCount: _availableColors.length,
                    itemBuilder: (context, index) {
                      final color = _availableColors[index];
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _currentColor = color;
                          });
                        },
                        child: Container(
                          width: 100,
                          margin: const EdgeInsets.only(right: 8, top: 8, bottom: 8), // Adjust margin
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.grey,
                              width: 2,
                            ),
                          ),
                          child: _currentColor == color
                              ? Center(
                            child: Icon(
                              Icons.check,
                              color: color.computeLuminance() > 0.5? Colors.black: Colors.white,
                            ),
                          )
                              : null,
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 16), // Spacing on the right
              ],
            ),
          ),

        ],
      ),
    );
  }
}

class SvgPainterImage extends StatelessWidget {
  const SvgPainterImage({
    super.key,
    required this.item,
    required this.size,
    required this.onTap,
  });
  final PathSvgItem item;
  final Size size;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: size,
      foregroundPainter: SvgPainter(item, onTap),
    );
  }
}