import 'package:flutter/material.dart';
import 'package:vector_graphics/vector_graphics.dart';

class VectorDetailPage extends StatelessWidget {
  final String filePath;
  final String fileName;

  const VectorDetailPage({
    super.key,
    required this.filePath,
    required this.fileName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(fileName),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height * 0.8,
              child: VectorGraphic(
                loader: AssetBytesLoader(filePath),
                fit: BoxFit.contain,
              ),
            ),
          ],
        ),
      ),
    );
  }
}