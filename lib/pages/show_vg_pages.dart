import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:svg_vg_converter/pages/vector_detail_page.dart';
import 'package:vector_graphics/vector_graphics.dart';
import 'package:path/path.dart' as path;

class ShowVgPages extends StatefulWidget {
  const ShowVgPages({super.key});

  @override
  State<ShowVgPages> createState() => _ShowVgPagesState();
}

class _ShowVgPagesState extends State<ShowVgPages> {
  final String assetPath = 'assets/vg/1/env-cat';
  List<String> vgFiles = [];

  @override
  void initState() {
    super.initState();
    loadVgFiles();
  }

  Future<void> loadVgFiles() async {
    try {
      final manifestContent = await DefaultAssetBundle.of(context).loadString('AssetManifest.json');
      final Map<String, dynamic> manifestMap = json.decode(manifestContent);

      // Debug print untuk melihat semua assets
      print('All assets in manifest:');
      manifestMap.keys.forEach((key) => print(key));

      // Filter file .vg
      final vgFiles = manifestMap.keys
          .where((String key) => key.endsWith('.vg'))
          .toList();

      print('\nFound VG files:');
      vgFiles.forEach((file) => print(file));

      setState(() {
        this.vgFiles = vgFiles;
      });
      
      print('\nTotal VG files: ${vgFiles.length} in $assetPath');
    } catch (e) {
      print('Error loading assets: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: AppBar(title: const Text('Vector Graphics Viewer')),
      body: vgFiles.isEmpty
          ? const Center(child: Text('No VG files found in assets folder'))
          : GridView.builder(
              padding: const EdgeInsets.all(8.0),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 1,
                childAspectRatio: 1.0, // Keep this 1.0 for square items
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: vgFiles.length,
              itemBuilder: (context, index) {
                final file = vgFiles[index];
                final fileName = path.basename(file);
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => VectorDetailPage(
                          filePath: file,
                          fileName: fileName,
                        ),
                      ),
                    );
                  },
                  child: Card(
                    child: Column(
                      children: [
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: _buildVgPreview(file),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            fileName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildVgPreview(String filePath) {
    try {
      return Flexible(
        flex: 1,
        child: VectorGraphic(
          loader: AssetBytesLoader(filePath),
          fit: BoxFit.contain,
        ),
      );
    } catch (e) {
      print('Error loading VG: $e'); // Add debug print
      return Container(
        width: 200, // Fixed width
        height: 200, // Fixed height
        color: Colors.grey[200],
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.broken_image, size: 40, color: Colors.grey[400]),
              const SizedBox(height: 8),
              Text(
                'Error loading file',
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
            ],
          ),
        ),
      );
    }
  }
}
