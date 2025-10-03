import 'package:flutter/material.dart';
<<<<<<< HEAD
import 'package:svg_vg_converter/pages/show_vg_pages.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:path_provider/path_provider.dart';
import 'package:vector_graphics/vector_graphics.dart';
import 'dart:io';
import 'dart:typed_data';
import 'svg_to_vg_converter.dart';
=======
import 'compare_page.dart';
>>>>>>> 87a5111af131a0ad6026fa6944d647fac75fff8c

// Tidak ada proses konversi di UI. Konversi hanya lewat CLI:
// dart run lib/batch_converter.dart
// Aplikasi ini hanya untuk membandingkan SVG asli dengan hasil VG.
void main() => runApp(const MainApp());

class MainApp extends StatelessWidget {
  const MainApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SVG vs VG Compare',
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.blue),
      home: const CompareSvgVgPage(),
    );
  }
}
