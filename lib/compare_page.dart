import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:vector_graphics/vector_graphics.dart';
import 'package:path/path.dart' as p;

/// Page to compare all SVG files (left) with generated VG binaries (right)
/// Assumes VG files are stored next to svg or in parallel output tree.
class CompareSvgVgPage extends StatefulWidget {
  final String assetRoot; // folder svg
  final String vgAssetRoot; // folder hasil vg
  final String? vgRootDir; // optional disk folder (dev desktop)
  const CompareSvgVgPage({
    super.key,
    this.assetRoot = 'assets/pet',
    this.vgAssetRoot = 'assets/pet_vg',
    this.vgRootDir,
  });

  @override
  State<CompareSvgVgPage> createState() => _CompareSvgVgPageState();
}

class _CompareSvgVgPageState extends State<CompareSvgVgPage> {
  late Future<List<_Pair>> _future;

  @override
  void initState() {
    super.initState();
    _future = _scan();
  }

  Future<List<_Pair>> _scan() async {
    final manifestRaw = await rootBundle.loadString('AssetManifest.json');
    final manifestMap = json.decode(manifestRaw) as Map<String, dynamic>;
    final rootPrefix = widget.assetRoot.endsWith('/')
        ? widget.assetRoot
        : '${widget.assetRoot}/';
    final vgRootPrefix = widget.vgAssetRoot.endsWith('/')
        ? widget.vgAssetRoot
        : '${widget.vgAssetRoot}/';
    
    // Get all SVG assets from the pet folder
    final svgAssets = manifestMap.keys
        .where(
          (k) => k.startsWith(rootPrefix) && k.toLowerCase().endsWith('.svg'),
        )
        .toList();
    svgAssets.sort();
    
    print('Found ${svgAssets.length} SVG files in $rootPrefix');
    
    final pairs = <_Pair>[];
    for (final svgPath in svgAssets) {
      final rel = svgPath.substring(
        rootPrefix.length,
      ); // relative path e.g. 1/env_1/env_cat1.svg
      
      // Construct the corresponding VG path
      final vgPath =
          '${vgRootPrefix}${rel.substring(0, rel.length - 4)}.vg.bin';
      
      // Check if VG file exists in manifest
      final vgExists = manifestMap.containsKey(vgPath);
      
      // Load file data to get sizes
      final svgData = await rootBundle.load(svgPath);
      final svgSize = svgData.lengthInBytes;
      
      int? vgSize;
      if (vgExists) {
        final vgData = await rootBundle.load(vgPath);
        vgSize = vgData.lengthInBytes;
      }
      
      pairs.add(_Pair(
        svgAsset: svgPath,
        vgAsset: vgExists ? vgPath : null,
        svgSize: svgSize,
        vgSize: vgSize,
      ));
    }
    
    print('Created ${pairs.length} pairs total');
    print('VG files found: ${pairs.where((p) => p.vgAsset != null).length}');
    
    return pairs;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bandingkan SVG vs VG')),
      body: FutureBuilder<List<_Pair>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          final data = snapshot.data ?? [];
          if (data.isEmpty) {
            return const Center(child: Text('Tidak ada file ditemukan'));
          }
          
          // Calculate statistics
          final totalFiles = data.length;
          final vgFound = data.where((p) => p.vgAsset != null).length;
          final vgMissing = totalFiles - vgFound;
          
          return Column(
            children: [
              // Summary card
              Container(
                padding: const EdgeInsets.all(16.0),
                margin: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _StatCard(
                      title: 'Total SVG',
                      value: totalFiles.toString(),
                      icon: Icons.image,
                      color: Colors.blue,
                    ),
                    _StatCard(
                      title: 'VG Ditemukan',
                      value: vgFound.toString(),
                      icon: Icons.check_circle,
                      color: Colors.green,
                    ),
                    _StatCard(
                      title: 'VG Hilang',
                      value: vgMissing.toString(),
                      icon: Icons.error,
                      color: Colors.red,
                    ),
                  ],
                ),
              ),
              // List of comparisons
              Expanded(
                child: ListView.separated(
                  itemCount: data.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final pair = data[index];
                    return Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Card(
                        elevation: 1,
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // File info header
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          p.basename(pair.svgAsset),
                                          style: Theme.of(context).textTheme.titleSmall,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        Text(
                                          pair.svgAsset,
                                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                            fontSize: 10,
                                            color: Colors.grey.shade600,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              // Statistics row
                              Row(
                                children: [
                                  _InfoChip(
                                    label: 'SVG Size',
                                    value: pair.svgSizeFormatted,
                                    icon: Icons.insert_drive_file,
                                    color: Colors.blue,
                                  ),
                                  const SizedBox(width: 8),
                                  _InfoChip(
                                    label: 'VG Size',
                                    value: pair.vgSizeFormatted,
                                    icon: Icons.file_present,
                                    color: Colors.green,
                                  ),
                                  const SizedBox(width: 8),
                                  _InfoChip(
                                    label: 'Compression',
                                    value: pair.compressionRatioFormatted,
                                    icon: Icons.compress,
                                    color: Colors.orange,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              // Images comparison
                              SizedBox(
                                height: 250,
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    Expanded(
                                      child: _ImageCard(
                                        title: 'SVG',
                                        child: SvgPicture.asset(
                                          pair.svgAsset,
                                          fit: BoxFit.contain,
                                          clipBehavior: Clip.hardEdge,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: _ImageCard(
                                        title: 'VG',
                                        child: pair.vgAsset != null
                                            ? VectorGraphic(
                                                loader: AssetBytesLoader(pair.vgAsset!),
                                                fit: BoxFit.contain,
                                                clipBehavior: Clip.hardEdge,
                                              )
                                            : const Center(
                                                child: Text('Belum ada VG'),
                                              ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          setState(() {
            _future = _scan();
          });
        },
        label: const Text('Reload'),
        icon: const Icon(Icons.refresh),
      ),
    );
  }
}

class _ImageCard extends StatelessWidget {
  final String title;
  final Widget child;
  
  const _ImageCard({
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Center(child: child),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  
  const _InfoChip({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });
  
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 4),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 9,
                      color: Colors.grey.shade700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  
  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });
  
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 32),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade700,
          ),
        ),
      ],
    );
  }
}

class _Pair {
  final String svgAsset; // asset path
  final String? vgAsset; // asset path for binary (null if missing)
  final int svgSize; // SVG file size in bytes
  final int? vgSize; // VG file size in bytes (null if missing)
  
  _Pair({
    required this.svgAsset,
    required this.vgAsset,
    required this.svgSize,
    this.vgSize,
  });
  
  String get svgSizeFormatted => _formatBytes(svgSize);
  String get vgSizeFormatted => vgSize != null ? _formatBytes(vgSize!) : 'N/A';
  
  double? get compressionRatio {
    if (vgSize == null || svgSize == 0) return null;
    return ((svgSize - vgSize!) / svgSize * 100);
  }
  
  String get compressionRatioFormatted {
    final ratio = compressionRatio;
    if (ratio == null) return 'N/A';
    return '${ratio.toStringAsFixed(1)}%';
  }
  
  static String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(2)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }
}
