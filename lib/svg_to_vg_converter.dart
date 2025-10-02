// import 'dart:io';
// import 'dart:typed_data';

// import 'package:flutter/foundation.dart';
// import 'package:path/path.dart' as p;
// import 'package:path_provider/path_provider.dart';
// import 'package:vector_graphics_compiler/vector_graphics_compiler.dart';
// // import 'package:flutter_svg/flutter_svg.dart' show SvgTheme;

// class SvgToVgConverter {
//   /// Mengubah 1 file SVG menjadi VG dan menulis ke [outputDir].
//   /// Mengembalikan path file .vg yang dihasilkan.
//   static Future<String> convertOne({
//     required File svgFile,
//     Directory? outputDir,
//     bool enableMaskingOptimizer = true,
//     bool enableClippingOptimizer = true,
//     bool enableOverdrawOptimizer = true,
//     bool useHalfPrecision = false,
//   }) async {
//     final xml = await svgFile.readAsString();

//     // Encode jadi VG bytes
//     final Uint8List vgBytes = encodeSvg(
//       xml: xml,
//       debugName: p.basename(svgFile.path),
//       theme: const SvgTheme(),
//       enableMaskingOptimizer: enableMaskingOptimizer,
//       enableClippingOptimizer: enableClippingOptimizer,
//       enableOverdrawOptimizer: enableOverdrawOptimizer,
//       useHalfPrecisionControlPoints: useHalfPrecision,
//       // colorMapper: ... // kalau mau remap warna saat compile
//     );

//     final Directory outDir =
//         outputDir ?? await _defaultOutputDir(create: true);

//     final outPath = p.setExtension(
//       p.join(outDir.path, p.basename(svgFile.path)),
//       '.vg', // atau '.svg.vec' jika kamu ingin kompatibel dengan contoh flutter_svg.
//     );
//     final outFile = File(outPath);
//     await outFile.writeAsBytes(vgBytes, flush: true);
//     return outPath;
//   }

//   /// Batch convert banyak file SVG.
//   static Future<List<String>> convertMany({
//     required List<File> svgFiles,
//     Directory? outputDir,
//     bool enableMaskingOptimizer = true,
//     bool enableClippingOptimizer = true,
//     bool enableOverdrawOptimizer = true,
//     bool useHalfPrecision = false,
//     ValueChanged<double>? onProgress, // 0..1
//   }) async {
//     final results = <String>[];
//     final total = svgFiles.length;
//     for (var i = 0; i < total; i++) {
//       final path = await convertOne(
//         svgFile: svgFiles[i],
//         outputDir: outputDir,
//         enableMaskingOptimizer: enableMaskingOptimizer,
//         enableClippingOptimizer: enableClippingOptimizer,
//         enableOverdrawOptimizer: enableOverdrawOptimizer,
//         useHalfPrecision: useHalfPrecision,
//       );
//       results.add(path);
//       onProgress?.call((i + 1) / total);
//     }
//     return results;
//   }

//   static Future<Directory> _defaultOutputDir({bool create = false}) async {
//     final base = await getApplicationDocumentsDirectory();
//     final dir = Directory(p.join(base.path, 'vg_output'));
//     if (create && !await dir.exists()) {
//       await dir.create(recursive: true);
//     }
//     return dir;
//   }
// }
import 'dart:io';
import 'dart:typed_data';
import 'package:vector_graphics_compiler/vector_graphics_compiler.dart';

class SvgToVgConverter {
  /// Converts SVG file to VG (Vector Graphics) binary format
  /// using the vector_graphics_compiler package
  static Future<Uint8List> convertSvgToVg(File svgFile) async {
    try {
      // Read SVG file content
      final svgContent = await svgFile.readAsString();
      
      // Use vector_graphics_compiler to compile SVG to binary format
      final compiledBytes = encodeSvg(
        xml: svgContent,
        debugName: svgFile.path.split('/').last,
        enableClippingOptimizer: false,
        enableMaskingOptimizer: false,
        enableOverdrawOptimizer: false,
      );
      
      return compiledBytes.buffer.asUint8List();
    } catch (e) {
      throw Exception('Failed to convert SVG to VG: $e');
    }
  }
  
  /// Converts SVG string content to VG binary format
  static Future<Uint8List> convertSvgStringToVg(String svgContent) async {
    try {
      // Use vector_graphics_compiler to compile SVG to binary format
      final compiledBytes = encodeSvg(
        xml: svgContent,
        debugName: 'svg_string',
        enableClippingOptimizer: false,
        enableMaskingOptimizer: false,
        enableOverdrawOptimizer: false,
      );
      
      return compiledBytes.buffer.asUint8List();
    } catch (e) {
      throw Exception('Failed to convert SVG string to VG: $e');
    }
  }
  
  /// Saves VG binary data to file
  static Future<void> saveVgToFile(Uint8List vgData, String outputPath) async {
    try {
      final file = File(outputPath);
      await file.writeAsBytes(vgData);
    } catch (e) {
      throw Exception('Failed to save VG file: $e');
    }
  }
}