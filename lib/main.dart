import 'package:flutter/material.dart';
import 'package:svg_vg_converter/pages/show_vg_pages.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:path_provider/path_provider.dart';
import 'package:vector_graphics/vector_graphics.dart';
import 'dart:io';
import 'dart:typed_data';
import 'svg_to_vg_converter.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SVG to VG Converter',
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      home: const SvgToVgConverterPage(),
    );
  }
}

// class SvgVgPage extends StatefulWidget {
//   const SvgVgPage({super.key});
//   @override
//   State<SvgVgPage> createState() => _SvgVgPageState();
// }

// class _SvgVgPageState extends State<SvgVgPage> {
//   List<PlatformFile> _selected = [];
//   double _progress = 0;
//   List<String> _outputs = [];
//   bool _busy = false;
//   String? _outDirPath;

//   Future<void> _pickSvgs() async {
//     final res = await FilePicker.platform.pickFiles(
//       allowMultiple: true,
//       type: FileType.custom,
//       allowedExtensions: ['svg'],
//     );
//     if (res != null) {
//       setState(() => _selected = res.files.where((f) => f.path != null).toList());
//     }
//   }

//   Future<void> _convertAll() async {
//     setState(() { _busy = true; _progress = 0; _outputs = []; });

//     final files = _selected
//         .where((f) => f.path != null)
//         .map((f) => File(f.path!))
//         .toList();

//     final outputs = await SvgToVgConverter.convertMany(
//       svgFiles: files,
//       onProgress: (v) => setState(() => _progress = v),
//     );

//     setState(() {
//       _busy = false;
//       _outputs = outputs;
//       _outDirPath = outputs.isNotEmpty ? File(outputs.first).parent.path : null;
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text('SVG → VG Converter')),
//       body: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           children: [
//             Wrap(
//               spacing: 8,
//               children: [
//                 ElevatedButton.icon(
//                   onPressed: _busy ? null : _pickSvgs,
//                   icon: const Icon(Icons.folder_open),
//                   label: const Text('Pilih SVG'),
//                 ),
//                 ElevatedButton.icon(
//                   onPressed: _busy || _selected.isEmpty ? null : _convertAll,
//                   icon: const Icon(Icons.auto_fix_high),
//                   label: const Text('Convert'),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 12),
//             if (_busy) LinearProgressIndicator(value: _progress),
//             const SizedBox(height: 12),
//             Expanded(
//               child: ListView(
//                 children: [
//                   Text('Terpilih: ${_selected.length} file'),
//                   const SizedBox(height: 8),
//                   ..._selected.map((f) => Text('• ${f.name}')),
//                   const Divider(),
//                   Text('Hasil (${_outDirPath ?? "-"})'),
//                   const SizedBox(height: 8),
//                   ..._outputs.map((p) => Text('✓ ${p.split(Platform.pathSeparator).last}')),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

class SvgToVgConverterPage extends StatefulWidget {
  const SvgToVgConverterPage({super.key});

  @override
  State<SvgToVgConverterPage> createState() => _SvgToVgConverterPageState();
}

class _SvgToVgConverterPageState extends State<SvgToVgConverterPage> {
  File? _selectedSvgFile;
  Uint8List? _convertedVgData;
  bool _isConverting = false;
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SVG to VG Converter'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // File Selection Section
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Pilih File SVG',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: _pickSvgFile,
                        icon: const Icon(Icons.file_upload),
                        label: const Text('Pilih File SVG'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                      ),
                      if (_selectedSvgFile != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: SvgPicture.file(
                            _selectedSvgFile!,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Convert Button
              ElevatedButton.icon(
                onPressed: _selectedSvgFile != null && !_isConverting
                    ? _convertSvgToVg
                    : null,
                icon: _isConverting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.transform),
                label: Text(_isConverting ? 'Converting...' : 'Convert ke VG'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),

              const SizedBox(height: 16),

              // Error Message
              if (_errorMessage != null)
                Card(
                  color: Colors.red[50],
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        const Icon(Icons.error, color: Colors.red),
                        const SizedBox(width: 8),
                        Text(
                          _errorMessage!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ],
                    ),
                  ),
                ),

              // Result Section
              if (_convertedVgData != null)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Hasil Konversi VG',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            ElevatedButton.icon(
                              onPressed: _exportVgFile,
                              icon: const Icon(Icons.download),
                              label: const Text('Export VG'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'VG Binary Data (Vector Graphics Format)',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Size: ${_convertedVgData!.length} bytes',
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: VectorGraphic(
                                  loader: MemoryBytesLoader(_convertedVgData!),
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickSvgFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['svg'],
      );

      if (result != null) {
        setState(() {
          _selectedSvgFile = File(result.files.single.path!);
          _convertedVgData = null;
          _errorMessage = null;
        });
      }
    } catch (e) {
      print("err: $e");
      setState(() {
        _errorMessage = 'Error memilih file: $e';
      });
    }
  }

  Future<void> _convertSvgToVg() async {
    if (_selectedSvgFile == null) return;

    setState(() {
      _isConverting = true;
      _errorMessage = null;
    });

    try {
      // Convert SVG to VG using vector_graphics_compiler
      final vgData = await SvgToVgConverter.convertSvgToVg(_selectedSvgFile!);

      setState(() {
        _convertedVgData = vgData;
        _isConverting = false;
      });

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('SVG berhasil dikonversi ke VG!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print("err: $e");
      setState(() {
        _errorMessage = 'Error konversi: $e';
        _isConverting = false;
      });
    }
  }

  Future<void> _exportVgFile() async {
    if (_convertedVgData == null || _selectedSvgFile == null) return;

    try {
      // Get the downloads directory
      Directory? downloadsDirectory;
      if (Platform.isAndroid) {
        downloadsDirectory = Directory('/storage/emulated/0/Download');
      } else {
        downloadsDirectory = await getDownloadsDirectory();
      }

      downloadsDirectory ??= await getApplicationDocumentsDirectory();

      // Create output file name
      final originalFileName = _selectedSvgFile!.path.split('/').last;
      final vgFileName = originalFileName.replaceAll('.svg', '.vec');
      final outputPath = '${downloadsDirectory.path}/$vgFileName';

      // Save VG binary data to file
      await SvgToVgConverter.saveVgToFile(_convertedVgData!, outputPath);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('File VG berhasil disimpan: $outputPath'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      print("err: $e");
      setState(() {
        _errorMessage = 'Error export file: $e';
      });
    }
  }
}

class MemoryBytesLoader extends BytesLoader {
  final Uint8List data;

  const MemoryBytesLoader(this.data);

  @override
  Future<ByteData> loadBytes(BuildContext? context) async {
    return ByteData.view(data.buffer);
  }

  @override
  Object cacheKey(BuildContext? context) => this;

  @override
  String toString() => 'VectorGraphicMemory(${data.length} bytes)';
}
