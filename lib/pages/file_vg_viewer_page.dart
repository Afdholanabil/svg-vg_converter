import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:vector_graphics/vector_graphics.dart';

class FileVgViewerPage extends StatefulWidget {
  const FileVgViewerPage({super.key});

  @override
  State<FileVgViewerPage> createState() => _FileVgViewerPageState();
}

class _FileVgViewerPageState extends State<FileVgViewerPage> {
  final List<_VgItem> _items = [];
  bool _loading = false;

  Future<void> _pickVgFiles() async {
    try {
      final picked = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['vg', 'bin'],
        allowMultiple: true,
        dialogTitle: 'Select .vg or .vg.bin files',
      );
      if (picked == null) return;
      await _addPaths(picked.files.map((f) => f.path).whereType<String>().toList());
    } catch (e) {
      _showSnack('Failed to pick files: $e', isError: true);
    }
  }

  Future<void> _pickFolder() async {
      // Directory picking API
      final dir = await FilePicker.platform.getDirectoryPath(dialogTitle: 'Select a folder to scan');
      if (dir == null) return;
      final all = await _scanFolder(dir);
      if (all.isEmpty) {
        _showSnack('No .vg/.vg.bin found under $dir');
        return;
      }
      await _addPaths(all);
  }

  Future<List<String>> _scanFolder(String dir) async {
    final result = <String>[];
    try {
      await for (final entity in Directory(dir).list(recursive: true, followLinks: false)) {
        if (entity is File) {
          final lower = entity.path.toLowerCase();
          if (lower.endsWith('.vg') || lower.endsWith('.vg.bin')) {
            result.add(entity.path);
          }
        }
      }
    } catch (e) {
      _showSnack('Scan error: $e', isError: true);
    }
    return result;
  }

  Future<void> _addPaths(List<String> paths) async {
    if (paths.isEmpty) return;
    setState(() => _loading = true);
    final uniques = <String>{..._items.map((e) => e.path)};
    for (final path in paths) {
      if (uniques.contains(path)) continue;
      try {
        final file = File(path);
        final stat = await file.stat();
        _items.add(_VgItem(path: path, size: stat.size));
        uniques.add(path);
      } catch (e) {
        // skip
      }
    }
    setState(() => _loading = false);
  }

  void _removeAt(int index) {
    setState(() => _items.removeAt(index));
  }

  void _clearAll() {
    setState(() => _items.clear());
  }

  void _showSnack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: isError ? Colors.red : Colors.black87),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('VG Viewer (Files)'),
        actions: [
          IconButton(
            tooltip: 'Pick VG files',
            onPressed: _loading ? null : _pickVgFiles,
            icon: const Icon(Icons.upload_file),
          ),
          IconButton(
            tooltip: 'Pick folder',
            onPressed: _loading ? null : _pickFolder,
            icon: const Icon(Icons.folder_open),
          ),
          if (_items.isNotEmpty)
            IconButton(
              tooltip: 'Clear all',
              onPressed: _clearAll,
              icon: const Icon(Icons.delete_sweep),
            ),
        ],
      ),
      body: Column(
        children: [
          if (_loading)
            const LinearProgressIndicator(minHeight: 2),
          Expanded(
            child: _items.isEmpty
                ? _EmptyState(onPick: _pickVgFiles, onPickFolder: _pickFolder)
                : ListView.separated(
                    padding: const EdgeInsets.all(12),
                    itemCount: _items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final it = _items[index];
                      return _VgCard(
                        item: it,
                        onRemove: () => _removeAt(index),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _VgCard extends StatelessWidget {
  final _VgItem item;
  final VoidCallback onRemove;
  const _VgCard({required this.item, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p.basename(item.path),
                        style: const TextStyle(fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.path,
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.withOpacity(0.3)),
                  ),
                  child: Text(_formatBytes(item.size), style: const TextStyle(color: Colors.green, fontSize: 12)),
                ),
                IconButton(onPressed: onRemove, icon: const Icon(Icons.close, color: Colors.red))
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 260,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300)),
                  child: Center(
                    child: VectorGraphic(
                      loader: _FileBytesLoader(item.path),
                      fit: BoxFit.contain,
                      clipBehavior: Clip.hardEdge,
                    ),
                  ),
                ),
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
}

class _VgItem {
  final String path;
  final int size;
  _VgItem({required this.path, required this.size});
}

/// Custom loader that reads VG bytes from a file path.
class _FileBytesLoader extends BytesLoader {
  final String filePath;
  _FileBytesLoader(this.filePath);

  @override
  Future<ByteData> loadBytes(BuildContext? context) async {
    final bytes = await File(filePath).readAsBytes();
    return Uint8List.fromList(bytes).buffer.asByteData();
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onPick;
  final VoidCallback onPickFolder;
  const _EmptyState({required this.onPick, required this.onPickFolder});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.insert_drive_file, size: 72, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          Text('No files selected', style: TextStyle(color: Colors.grey.shade600)),
          const SizedBox(height: 20),
          Wrap(
            spacing: 12,
            children: [
              ElevatedButton.icon(
                onPressed: onPick,
                icon: const Icon(Icons.upload_file),
                label: const Text('Pick VG files'),
              ),
              OutlinedButton.icon(
                onPressed: onPickFolder,
                icon: const Icon(Icons.folder_open),
                label: const Text('Pick folder'),
              ),
            ],
          )
        ],
      ),
    );
  }
}
