import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:vector_graphics/vector_graphics.dart';
import 'package:vector_graphics_compiler/vector_graphics_compiler.dart' as vg;
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;

/// Custom BytesLoader for in-memory VG data
class _MemoryBytesLoader extends BytesLoader {
  final Uint8List bytes;

  _MemoryBytesLoader(this.bytes);

  @override
  Future<ByteData> loadBytes(BuildContext? context) async {
    return bytes.buffer.asByteData();
  }
}

/// Interactive page for converting SVG files to VG format with file picker
class ConverterPage extends StatefulWidget {
  const ConverterPage({super.key});

  @override
  State<ConverterPage> createState() => _ConverterPageState();
}

class _ConverterPageState extends State<ConverterPage> {
  final List<ConversionResult> _results = [];
  bool _isConverting = false;
  bool _libsInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeLibs();
  }

  void _initializeLibs() {
    try {
      final pathOpsOk = vg.initializePathOpsFromFlutterCache();
      final tessOk = vg.initializeTessellatorFromFlutterCache();
      setState(() {
        _libsInitialized = pathOpsOk && tessOk;
      });
      if (_libsInitialized) {
        print('Vector graphics libraries initialized successfully');
      } else {
        print('Warning: Some vector graphics libraries failed to initialize');
      }
    } catch (e) {
      print('Error initializing libraries: $e');
      setState(() {
        _libsInitialized = false;
      });
    }
  }

  Future<void> _pickAndConvertFiles() async {
    try {
      // Pick multiple SVG files
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['svg'],
        allowMultiple: true,
        dialogTitle: 'Select SVG files to convert',
      );

      if (result == null || result.files.isEmpty) {
        return;
      }

      setState(() {
        _isConverting = true;
      });

      // Convert each file
      for (final platformFile in result.files) {
        if (platformFile.path == null) continue;

        final file = File(platformFile.path!);
        await _convertFile(file);
      }

      setState(() {
        _isConverting = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully converted ${result.files.length} file(s)'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isConverting = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking files: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _convertFile(File svgFile) async {
    try {
      // Read SVG file
      final svgString = await svgFile.readAsString();
      final svgBytes = await svgFile.readAsBytes();

      // Convert to VG
      final vgBytes = _encodeToVg(svgString, p.basename(svgFile.path));

      // Create result
      final result = ConversionResult(
        fileName: p.basename(svgFile.path),
        filePath: svgFile.path,
        svgData: svgBytes,
        vgData: Uint8List.fromList(vgBytes),
        svgSize: svgBytes.length,
        vgSize: vgBytes.length,
        timestamp: DateTime.now(),
      );

      setState(() {
        _results.insert(0, result); // Add to top of list
      });
    } catch (e, st) {
      print('Failed to convert ${svgFile.path}: $e\n$st');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to convert ${p.basename(svgFile.path)}: $e'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  List<int> _encodeToVg(String xml, String name) {
    // Try encoding with optimizers off first
    try {
      return vg.encodeSvg(
        xml: xml,
        debugName: name,
        enableMaskingOptimizer: false,
        enableClippingOptimizer: false,
        enableOverdrawOptimizer: false,
      );
    } catch (_) {
      // Fallback: try with optimizers on
      return vg.encodeSvg(
        xml: xml,
        debugName: name,
        enableMaskingOptimizer: true,
        enableClippingOptimizer: true,
        enableOverdrawOptimizer: true,
      );
    }
  }

  Future<void> _saveVgFile(ConversionResult result) async {
    try {
      final outputPath = await FilePicker.platform.saveFile(
        dialogTitle: 'Save VG file',
        fileName: '${p.basenameWithoutExtension(result.fileName)}.vg.bin',
        type: FileType.custom,
        allowedExtensions: ['bin'],
      );

      if (outputPath == null) return;

      final outputFile = File(outputPath);
      await outputFile.writeAsBytes(result.vgData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('VG file saved to: $outputPath'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving file: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _clearResults() {
    setState(() {
      _results.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SVG to VG Converter'),
        actions: [
          if (_results.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              tooltip: 'Clear all results',
              onPressed: _clearResults,
            ),
        ],
      ),
      body: Column(
        children: [
          // Header section with status and action button
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.blue.shade50,
                  Colors.blue.shade100,
                ],
              ),
              border: Border(
                bottom: BorderSide(color: Colors.blue.shade200),
              ),
            ),
            child: Column(
              children: [
                // Status indicator
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _libsInitialized ? Icons.check_circle : Icons.warning,
                      color: _libsInitialized ? Colors.green : Colors.orange,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _libsInitialized
                          ? 'Vector Graphics libraries ready'
                          : 'Warning: Some libraries not initialized',
                      style: TextStyle(
                        color: _libsInitialized ? Colors.green.shade700 : Colors.orange.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Main action button
                ElevatedButton.icon(
                  onPressed: _isConverting ? null : _pickAndConvertFiles,
                  icon: _isConverting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.file_upload, size: 28),
                  label: Text(
                    _isConverting ? 'Converting...' : 'Pick SVG Files to Convert',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                
                const SizedBox(height: 12),
                
                // Info text
                Text(
                  'Select one or more SVG files to convert to VG format',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),

          // Results section
          Expanded(
            child: _results.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.image_not_supported,
                          size: 80,
                          color: Colors.grey.shade300,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No conversions yet',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Click the button above to select SVG files',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: _results.length,
                    itemBuilder: (context, index) {
                      final result = _results[index];
                      return _ConversionResultCard(
                        result: result,
                        onSave: () => _saveVgFile(result),
                        onRemove: () {
                          setState(() {
                            _results.removeAt(index);
                          });
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _ConversionResultCard extends StatelessWidget {
  final ConversionResult result;
  final VoidCallback onSave;
  final VoidCallback onRemove;

  const _ConversionResultCard({
    required this.result,
    required this.onSave,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final compressionRatio = ((result.svgSize - result.vgSize) / result.svgSize * 100);
    
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: filename and actions
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        result.fileName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        result.filePath,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Converted at ${_formatTime(result.timestamp)}',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.save_alt),
                  tooltip: 'Save VG file',
                  color: Colors.blue,
                  onPressed: onSave,
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  tooltip: 'Remove',
                  color: Colors.red,
                  onPressed: onRemove,
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Statistics chips
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _MetricChip(
                  icon: Icons.insert_drive_file,
                  label: 'SVG',
                  value: _formatBytes(result.svgSize),
                  color: Colors.blue,
                ),
                _MetricChip(
                  icon: Icons.file_present,
                  label: 'VG',
                  value: _formatBytes(result.vgSize),
                  color: Colors.green,
                ),
                _MetricChip(
                  icon: Icons.compress,
                  label: 'Saved',
                  value: '${compressionRatio.toStringAsFixed(1)}%',
                  color: compressionRatio > 0 ? Colors.orange : Colors.red,
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Comparison view
            SizedBox(
              height: 300,
              child: Row(
                children: [
                  // SVG preview
                  Expanded(
                    child: _PreviewCard(
                      title: 'SVG Original',
                      color: Colors.blue,
                      child: SvgPicture.memory(
                        result.svgData,
                        fit: BoxFit.contain,
                        placeholderBuilder: (context) => const Center(
                          child: CircularProgressIndicator(),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  
                  // VG preview
                  Expanded(
                    child: _PreviewCard(
                      title: 'VG Converted',
                      color: Colors.green,
                      child: VectorGraphic(
                        loader: _MemoryBytesLoader(result.vgData),
                        fit: BoxFit.contain,
                        clipBehavior: Clip.hardEdge,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(2)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }

  static String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:${time.second.toString().padLeft(2, '0')}';
  }
}

class _PreviewCard extends StatelessWidget {
  final String title;
  final Color color;
  final Widget child;

  const _PreviewCard({
    required this.title,
    required this.color,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: color.withOpacity(0.3), width: 2),
        borderRadius: BorderRadius.circular(8),
        color: color.withOpacity(0.05),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(6),
                topRight: Radius.circular(6),
              ),
              border: Border(
                bottom: BorderSide(color: color.withOpacity(0.3)),
              ),
            ),
            child: Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          
          // Preview area
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Center(child: child),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _MetricChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade700,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class ConversionResult {
  final String fileName;
  final String filePath;
  final Uint8List svgData;
  final Uint8List vgData;
  final int svgSize;
  final int vgSize;
  final DateTime timestamp;

  ConversionResult({
    required this.fileName,
    required this.filePath,
    required this.svgData,
    required this.vgData,
    required this.svgSize,
    required this.vgSize,
    required this.timestamp,
  });
}
