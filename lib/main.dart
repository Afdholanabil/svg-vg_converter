import 'package:flutter/material.dart';
import 'compare_page.dart';

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
