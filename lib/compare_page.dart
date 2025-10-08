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
  int _selectedPet = 1;
  bool _showSvg = false;
  bool _showVg = true;

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

    // Get SVG assets only for selected pet
    final svgAssets = manifestMap.keys
        .where(
          (k) =>
              k.startsWith('$rootPrefix$_selectedPet/') &&
              k.toLowerCase().endsWith('.svg'),
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

      pairs.add(
        _Pair(
          svgAsset: svgPath,
          vgAsset: vgExists ? vgPath : null,
          svgSize: svgSize,
          vgSize: vgSize,
        ),
      );
    }

    print('Created ${pairs.length} pairs total');
    print('VG files found: ${pairs.where((p) => p.vgAsset != null).length}');

    return pairs;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bandingkan SVG vs VG'),
        actions: [
          // Toggle buttons in AppBar
          Row(
            children: [
              // SVG Toggle
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('SVG', style: TextStyle(fontSize: 12)),
                    Switch(
                      value: _showSvg,
                      onChanged: (value) => setState(() => _showSvg = value),
                    ),
                  ],
                ),
              ),
              // VG Toggle
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('VG', style: TextStyle(fontSize: 12)),
                    Switch(
                      value: _showVg,
                      onChanged: (value) => setState(() => _showVg = value),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Pet selector
          Container(
            height: 60,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _PetButton(
                  title: 'Cat',
                  petNumber: 1,
                  isSelected: _selectedPet == 1,
                  onTap: () => _selectPet(1),
                ),
                _PetButton(
                  title: 'Dog',
                  petNumber: 2,
                  isSelected: _selectedPet == 2,
                  onTap: () => _selectPet(2),
                ),
                _PetButton(
                  title: 'Rabbit',
                  petNumber: 3,
                  isSelected: _selectedPet == 3,
                  onTap: () => _selectPet(3),
                ),
                _PetButton(
                  title: 'Squirrel',
                  petNumber: 4,
                  isSelected: _selectedPet == 4,
                  onTap: () => _selectPet(4),
                ),
                _PetButton(
                  title: 'Owl',
                  petNumber: 5,
                  isSelected: _selectedPet == 5,
                  onTap: () => _selectPet(5),
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: FutureBuilder<List<_Pair>>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }

                final data = snapshot.data ?? [];
                if (data.isEmpty) {
                  return Center(
                    child: Text('No files found for Pet $_selectedPet'),
                  );
                }

                final totalFiles = data.length;
                final vgFound = data.where((p) => p.vgAsset != null).length;
                final vgMissing = totalFiles - vgFound;

                return Column(
                  children: [
                    // Stats summary
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
                            title: 'VG Found',
                            value: vgFound.toString(),
                            icon: Icons.check_circle,
                            color: Colors.green,
                          ),
                          _StatCard(
                            title: 'VG Missing',
                            value: vgMissing.toString(),
                            icon: Icons.error,
                            color: Colors.red,
                          ),
                        ],
                      ),
                    ),

                    // File comparisons
                    Expanded(
                      child: ListView.builder(
                        itemCount: data.length,
                        itemBuilder: (context, index) {
                          final pair = data[index];
                          return _buildComparisonCard(pair);
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _selectPet(int petNumber) {
    setState(() {
      _selectedPet = petNumber;
      _future = _scan();
    });
  }

  Widget _buildComparisonCard(_Pair pair) {
    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              p.basename(pair.svgAsset),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 200,
              child: Row(
                children: [
                  // Show SVG conditionally
                  if (_showSvg)
                    Expanded(
                      child: _ImageCard(
                        title: 'SVG',
                        child: SvgPicture.asset(
                          pair.svgAsset,
                          fit: BoxFit.contain,
                          placeholderBuilder: (ctx) =>
                              const Center(child: CircularProgressIndicator()),
                        ),
                      ),
                    ),
                  if (_showSvg && _showVg) const SizedBox(width: 8),
                  // Show VG conditionally
                  if (_showVg)
                    Expanded(
                      child: _ImageCard(
                        title: 'VG',
                        child: pair.vgAsset != null
                            ? VectorGraphic(
                                loader: AssetBytesLoader(pair.vgAsset!),
                                fit: BoxFit.contain,
                                placeholderBuilder: (ctx) => const Center(
                                  child: CircularProgressIndicator(),
                                ),
                              )
                            : const Center(child: Text('VG not found')),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _InfoChip(
                  label: 'SVG Size',
                  value: pair.svgSizeFormatted,
                  icon: Icons.image,
                  color: Colors.blue,
                ),
                const SizedBox(width: 8),
                _InfoChip(
                  label: 'VG Size',
                  value: pair.vgSizeFormatted,
                  icon: Icons.memory,
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
          ],
        ),
      ),
    );
  }
}

class _PetButton extends StatelessWidget {
  final String title;
  final int petNumber;
  final bool isSelected;
  final VoidCallback onTap;

  const _PetButton({
    required this.title,
    required this.petNumber,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: MaterialButton(
        onPressed: onTap,
        color: isSelected
            ? Theme.of(context).primaryColor
            : Colors.grey.shade200,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Text(
          'Pet $petNumber - $title',
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black87,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

class _ImageCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _ImageCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
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
            child: ClipRRect(
              // Add ClipRRect
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(8),
                bottomRight: Radius.circular(8),
              ),
              child: Container(
                padding: const EdgeInsets.all(8.0),
                color: Colors.white,
                child: Center(child: child),
              ),
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
                    style: TextStyle(fontSize: 9, color: Colors.grey.shade700),
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
          style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
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
