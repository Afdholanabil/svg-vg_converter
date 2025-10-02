import 'dart:io';
import 'package:flutter/material.dart';
import 'package:vector_graphics/vector_graphics.dart';
import 'package:path/path.dart' as path;

class ShowVgPages extends StatefulWidget {
  const ShowVgPages({super.key});

  @override
  State<ShowVgPages> createState() => _ShowVgPagesState();
}

class _ShowVgPagesState extends State<ShowVgPages> {
  final String assetPath = 'assets/vg/1/env1/';
  List<FileSystemEntity> vgFiles = [];

  @override
  void initState() {
    super.initState();
    loadVgFiles();
  }

  Future<void> loadVgFiles() async {
    final directory = Directory(assetPath);
    if (await directory.exists()) {
      final files = directory
          .listSync(recursive: true)
          .where((file) => file.path.toLowerCase().endsWith('.vg'))
          .toList();
      setState(() {
        vgFiles = files;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vector Graphics Viewer'),
      ),
      body: vgFiles.isEmpty
          ? const Center(
              child: Text('No VG files found in assets folder'),
            )
          : GridView.builder(
              padding: const EdgeInsets.all(8.0),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1.0,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: vgFiles.length,
              itemBuilder: (context, index) {
                final file = vgFiles[index];
                final fileName = path.basename(file.path);
                return Card(
                  child: Column(
                    children: [
                      Expanded(
                        child: _buildVgPreview(file.path),
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
                );
              },
            ),
    );
  }

  Widget _buildVgPreview(String filePath) {
    final assetPath = filePath.replaceAll('\\', '/');
    try {
      return VectorGraphic(
        loader: AssetBytesLoader(assetPath),
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.contain,
      );
    } catch (e) {
      return Container(
        color: Colors.grey[200],
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.broken_image, size: 40, color: Colors.grey[400]),
              const SizedBox(height: 4),
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