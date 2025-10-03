import 'dart:io';
import 'package:vector_graphics_compiler/vector_graphics_compiler.dart' as vg;
import 'package:path/path.dart' as p;

/// Recursively converts semua file SVG di [inputDirPath] menjadi file VG biner
/// (.vg.bin) dengan struktur mirror di bawah [outputDirPath]. Jika
/// [outputDirPath] == null maka file biner ditulis di direktori yang sama dengan
/// SVG sumber.
///
/// Rekomendasi proyek ini: input = assets/pet, output = assets/pet_vg.
Future<void> convertSvgsRecursively({
  required String inputDirPath,
  String? outputDirPath,
  bool verbose = true,
  bool initNativeLibs = true,
}) async {
  final inputDir = Directory(inputDirPath);
  if (!await inputDir.exists()) {
    throw Exception('Input directory not found: $inputDirPath');
  }

  if (initNativeLibs) {
    _ensureInitialized(verbose: verbose);
  }
  final outRoot = outputDirPath == null ? null : Directory(outputDirPath);
  if (outRoot != null && !await outRoot.exists()) {
    await outRoot.create(recursive: true);
  }
  final stopwatch = Stopwatch()..start();
  int converted = 0;
  await for (final entity in inputDir.list(
    recursive: true,
    followLinks: false,
  )) {
    if (entity is File && entity.path.toLowerCase().endsWith('.svg')) {
      final relPath = p.relative(entity.path, from: inputDir.path);
      final outDir = outRoot == null
          ? Directory(p.dirname(entity.path))
          : Directory(p.join(outRoot.path, p.dirname(relPath)));
      if (!await outDir.exists()) {
        await outDir.create(recursive: true);
      }
      final outFile = File(
        p.join(outDir.path, p.basenameWithoutExtension(relPath) + '.vg.bin'),
      );
      try {
        final svgString = await entity.readAsString();
        // Encode SVG into vector graphics binary format.
        final bytes = _safeEncode(svgString, p.basename(entity.path));
        await outFile.writeAsBytes(bytes, flush: true);
        converted++;
        if (verbose) {
          // ignore: avoid_print
          print('Converted: ${entity.path} -> ${outFile.path}');
        }
      } catch (e, st) {
        // ignore: avoid_print
        print('Failed to convert ${entity.path}: $e\n$st');
      }
    }
  }
  stopwatch.stop();
  if (verbose) {
    // ignore: avoid_print
    print('Conversion finished. $converted file(s) in ${stopwatch.elapsed}');
  }
}

/// Simple CLI entrypoint (dart run lib/batch_converter.dart)
Future<void> main(List<String> args) async {
  final input = args.isNotEmpty ? args[0] : 'assets/pet';
  final output = args.length > 1 ? args[1] : 'assets/pet_vg';
  await convertSvgsRecursively(inputDirPath: input, outputDirPath: output);
}

bool _initialized = false;
void _ensureInitialized({bool verbose = true}) {
  if (_initialized) return;
  try {
    final pathOpsOk = vg.initializePathOpsFromFlutterCache();
    final tessOk = vg.initializeTessellatorFromFlutterCache();
    _initialized = pathOpsOk && tessOk; // mark true only if both succeeded
    if (verbose) {
      // ignore: avoid_print
      print('Init vector libs: pathOps=$pathOpsOk tessellator=$tessOk');
    }
  } catch (e) {
    if (verbose) {
      // ignore: avoid_print
      print(
        'Warning: gagal inisialisasi native libs ($e). Beberapa SVG kompleks bisa gagal.',
      );
    }
  }
}

/// Try encoding SVG with safer settings first (optimizers off) then fall back.
List<int> _safeEncode(String xml, String name) {
  // Attempt 1: all optimizers OFF
  try {
    return vg.encodeSvg(
      xml: xml,
      debugName: name,
      enableMaskingOptimizer: false,
      enableClippingOptimizer: false,
      enableOverdrawOptimizer: false,
    );
  } catch (_) {
    // Attempt 2: enable optimizers (may fix some malformed path references)
    try {
      return vg.encodeSvg(
        xml: xml,
        debugName: name,
        enableMaskingOptimizer: true,
        enableClippingOptimizer: true,
        enableOverdrawOptimizer: true,
      );
    } catch (e2) {
      // Re-throw; caller will log and continue
      throw e2;
    }
  }
}
