import 'package:flutter/material.dart';
import 'package:svg_vg_converter/pages/show_vg_pages.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: ShowVgPages(),
      ),
    );
  }
}
