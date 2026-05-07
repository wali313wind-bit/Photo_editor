import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'آتلیه حرفه‌ای',
      theme: ThemeData.dark().copyWith(
        primaryColor: Colors.amber,
        scaffoldBackgroundColor: const Color(0xFF1E1E2F),
      ),
      debugShowCheckedModeBanner: false,
      home: const ImageEditorScreen(),
    );
  }
}

class ImageEditorScreen extends StatefulWidget {
  const ImageEditorScreen({super.key});

  @override
  State<ImageEditorScreen> createState() => _ImageEditorScreenState();
}

class _ImageEditorScreenState extends State<ImageEditorScreen> {
  ui.Image? _editedImage;
  String _selectedFilter = 'none';
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _pickImageFromGallery(); // مستقیماً از گالری بخواهد عکس انتخاب کند
  }

  Future<void> _pickImageFromGallery() async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final File imageFile = File(pickedFile.path);
      final Uint8List bytes = await imageFile.readAsBytes();
      final ui.Codec codec = await ui.instantiateImageCodec(bytes);
      final ui.FrameInfo frameInfo = await codec.getNextFrame();
      setState(() {
        _editedImage = frameInfo.image;
      });
    }
  }

  ui.ColorFilter _getColorFilter() {
    switch (_selectedFilter) {
      case 'grayscale':
        return const ui.ColorFilter.matrix(<double>[0.2126,0.7152,0.0722,0,0, 0.2126,0.7152,0.0722,0,0, 0.2126,0.7152,0.0722,0,0, 0,0,0,1,0]);
      case 'sepia':
        return const ui.ColorFilter.matrix(<double>[0.393,0.769,0.189,0,0, 0.349,0.686,0.168,0,0, 0.272,0.534,0.131,0,0, 0,0,0,1,0]);
      case 'invert':
        return const ui.ColorFilter.matrix(<double>[-1,0,0,0,255, 0,-1,0,0,255, 0,0,-1,0,255, 0,0,0,1,0]);
      default:
        return const ui.ColorFilter.mode(Colors.transparent, BlendMode.src);
    }
  }

  Future<void> _saveImage() async {
    if (_editedImage == null) return;
    if (await Permission.storage.request().isGranted || await Permission.photos.request().isGranted) {
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      canvas.drawImage(_editedImage!, Offset.zero, Paint());
      final picture = recorder.endRecording();
      final img = await picture.toImage(_editedImage!.width, _editedImage!.height);
      final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
      if (byteData != null) {
        await ImageGallerySaver.saveImage(byteData.buffer.asUint8List());
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تصویر ذخیره شد')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('آتلیه حرفه‌ای'),
        actions: [IconButton(icon: const Icon(Icons.save), onPressed: _saveImage)],
      ),
      body: Column(
        children: [
          Expanded(
            child: _editedImage == null
                ? const Center(child: CircularProgressIndicator())
                : InteractiveViewer(
                    child: RawImage(image: _editedImage, fit: BoxFit.contain),
                  ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            child: Wrap(
              spacing: 8,
              children: [
                _buildFilterChip('بدون فیلتر', 'none'),
                _buildFilterChip('سیاه‌وسفید', 'grayscale'),
                _buildFilterChip('سپیا', 'sepia'),
                _buildFilterChip('نگاتیو', 'invert'),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _pickImageFromGallery,
        child: const Icon(Icons.add_photo_alternate),
      ),
    );
  }

  Widget _buildFilterChip(String label, String filterId) {
    return FilterChip(
      label: Text(label),
      selected: _selectedFilter == filterId,
      onSelected: (selected) {
        setState(() {
          _selectedFilter = selected ? filterId : 'none';
        });
      },
      backgroundColor: Colors.grey[800],
      selectedColor: Colors.amber,
    );
  }
}
