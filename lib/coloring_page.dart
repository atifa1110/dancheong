import 'package:dancheong/constant.dart';
import 'package:dancheong/svg_painter.dart';
import 'package:dancheong/utils.dart';
import 'package:dancheong/vector_image.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';

import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:io';

import 'package:permission_handler/permission_handler.dart';
import 'package:saver_gallery/saver_gallery.dart';


class ColoringSvgScreen extends StatefulWidget {
  final String imagePath;

  const ColoringSvgScreen({super.key, required this.imagePath});

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
    _requestPermission();
  }

  final GlobalKey _globalKey = GlobalKey(); // GlobalKey for RepaintBoundary

  /// Requests necessary permissions based on the platform.
  Future<void> _requestPermission() async {
    bool statuses;
    if (Platform.isAndroid) {
      final deviceInfoPlugin = DeviceInfoPlugin();
      final deviceInfo = await deviceInfoPlugin.androidInfo;
      final sdkInt = deviceInfo.version.sdkInt;
      statuses = sdkInt < 29 ? await Permission.storage
          .request()
          .isGranted : true;
    } else {
      statuses = await Permission.photosAddOnly
          .request()
          .isGranted;
    }
    print('Permission Request Result: $statuses');
  }

  // Example usage within your existing _saveScreen function or elsewhere:
  Future<void> _saveScreen() async {
    try {
      RenderRepaintBoundary boundary =
      _globalKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await  boundary.toImage(pixelRatio: 2.0);
      ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);

      if (byteData != null) {
        Uint8List pngBytes = byteData.buffer.asUint8List();
        String picturesPath = "${DateTime
            .now()
            .millisecondsSinceEpoch}.png";
        final result = await SaverGallery.saveImage(
          pngBytes,
          quality: 100,
          fileName: picturesPath,
          skipIfExists: false,
        );
        print("Result : ${result.toString()}");
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Image saved to gallery!')));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to save image')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to save image')),
      );
    }
  }

  Size? _size;
  List<PathSvgItem>? _items;

  Future<void> _init() async {
    final value = await getVectorImageFromFile(widget.imagePath);
    setState(() {
      _items = value.items;
      _size = value.size;
    });
  }

  Color _currentColor = Colors.red; // Default color
  final List<Color> _availableColors = [
    color1,
    color2,
    color3,
    color4,
    color5,
    color6,
    color7,
    color8,
    color9,
    color10,
    color11,
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
        title: const Text('Dancheong Coloring'),
        actions: [
          IconButton(
            onPressed: _saveScreen, // Call the save function
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
              minScale: 0.1, // Allow zooming out to 10%
              maxScale: 10.0, // Allow zooming in to 1000% (10x)
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
            height: 80,
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
                  width: 80,// Expand the first section to push the text to the middle
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center, // Center the text horizontally
                    children: [
                      Icon(Icons.palette, size: 20, color: Colors.grey),
                      SizedBox(width: 5),
                      Text(
                        'Colors',
                        style: TextStyle(
                          fontSize: 16,
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
                  color: Colors.black,
                ),
                const SizedBox(width: 16),
                Expanded( // Expand the ListView to fill available space
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.only(right: 50), // Add left padding for "Colors" text
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
                          width: 50,
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