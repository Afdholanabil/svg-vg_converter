# SVG to Vector Graphics (VG) Converter

A comprehensive Flutter tooling & viewer for batch conversion of SVG files to Flutter Vector Graphics (.vg.bin) format, with side-by-side comparison and quality metrics.

## Features

- 🚀 **Batch Conversion**: Recursively convert entire directories of SVG files to VG format
- 📊 **Visual Comparison**: Side-by-side comparison viewer showing SVG vs VG rendering
- 📈 **File Metrics**: Display file sizes, compression ratios, and quality statistics
- 🎯 **High Quality Rendering**: Optimized rendering parameters for crystal-clear vector graphics
- 💾 **Space Savings**: VG files are typically 40-60% smaller than SVG files
- ⚡ **Performance**: VG format eliminates runtime XML parsing for better performance

## Prerequisites

- Flutter SDK (3.0+)
- Dart SDK
- Windows/Linux/macOS desktop support enabled

## Installation

1. Clone the repository:
```bash
git clone https://github.com/Afdholanabil/svg-vg_converter.git
cd svg-vg_converter
```

2. Install dependencies:
```bash
flutter pub get
```

3. Ensure your `pubspec.yaml` includes all asset directories:
```yaml
flutter:
  assets:
    - assets/pet/
    - assets/pet/1/
    - assets/pet/1/env_1/
    # ... (all subdirectories must be explicitly listed)
    - assets/pet_vg/
    - assets/pet_vg/1/
    # ... (corresponding VG directories)
```

## Usage

### Step 1: Prepare Your SVG Files

Place all SVG files in the `assets/pet/` directory. The converter will recursively process all subdirectories.

Example structure:
```
assets/pet/
  ├── 1/
  │   ├── env_1/
  │   │   ├── item_decoration/
  │   │   │   └── env_cat1.svg
  │   │   └── resource/
  │   │       └── resource_cat1.svg
  ├── 2/
  │   └── env_1/...
  └── ...
```

### Step 2: Run the Batch Converter

**Important**: Always run the batch converter from the project root directory.

```bash
# Navigate to project root
cd C:\Users\YourName\path\to\svg-vg_converter

# Run the batch converter
dart run lib/batch_converter.dart
```

**Custom Input/Output Directories** (optional):
```bash
dart run lib/batch_converter.dart <inputDir> <outputDir>

# Example:
dart run lib/batch_converter.dart assets/icons assets/icons_vg
```

**Default Behavior**:
- Input: `assets/pet/`
- Output: `assets/pet_vg/`
- Maintains directory structure (mirrored output)

### Step 3: View the Comparison

Run the Flutter application:
```bash
flutter run -d windows  # or -d linux, -d macos
```

The app will display:
- **Left Panel**: Original SVG files
- **Right Panel**: Converted VG files
- **Metrics**: File sizes, compression ratio, and statistics

### Step 4: Update Assets (If Needed)

If you add or modify SVG files:

1. Re-run the batch converter:
   ```bash
   dart run lib/batch_converter.dart
   ```

2. Hot restart the app (press `R` in the Flutter terminal, or restart the app)

## Ensuring High-Quality VG Rendering

### Problem: Blurry or Pixelated VG Files

If your VG files appear low quality, pixelated, or blurry, follow these guidelines:

### ✅ Solution 1: Proper Widget Configuration

**DO THIS** - Use constrained containers with proper sizing:

```dart
// ✅ CORRECT: Use SizedBox with specific dimensions
SizedBox(
  height: 250,  // Fixed height
  child: VectorGraphic(
    loader: AssetBytesLoader('assets/pet_vg/icon.vg.bin'),
    fit: BoxFit.contain,
    clipBehavior: Clip.hardEdge,
  ),
)

// ✅ CORRECT: Use LayoutBuilder for responsive sizing
LayoutBuilder(
  builder: (context, constraints) {
    return VectorGraphic(
      loader: AssetBytesLoader('assets/pet_vg/icon.vg.bin'),
      width: constraints.maxWidth,
      height: constraints.maxHeight,
      fit: BoxFit.contain,
    );
  },
)
```

**DON'T DO THIS** - Avoid infinite constraints:

```dart
// ❌ WRONG: double.infinity causes rendering errors
VectorGraphic(
  loader: AssetBytesLoader('assets/pet_vg/icon.vg.bin'),
  width: double.infinity,   // ❌ Causes "Infinity or NaN toInt" error
  height: double.infinity,  // ❌ Causes rendering issues
)
```

### ✅ Solution 2: BoxFit Options

Choose the right `BoxFit` mode:

- **`BoxFit.contain`** - Maintains aspect ratio, scales to fit (recommended)
- **`BoxFit.cover`** - Fills space, may crop edges
- **`BoxFit.fill`** - Stretches to fill (may distort)
- **`BoxFit.scaleDown`** - Like contain, but never scales up

```dart
VectorGraphic(
  loader: AssetBytesLoader('assets/pet_vg/icon.vg.bin'),
  fit: BoxFit.contain,  // Best for maintaining quality
)
```

### ✅ Solution 3: Check SVG Source Quality

The VG output quality depends on the SVG source:

1. **Use clean SVG files**: Avoid overly complex paths or nested groups
2. **Optimize SVG first**: Use tools like SVGO to clean up SVG files
3. **Check viewport**: Ensure SVG has proper `viewBox` and dimensions

### ✅ Solution 4: Encoder Settings

The batch converter uses optimized encoding settings:

```dart
// Attempt 1: Optimizers OFF (safer for complex SVGs)
encodeSvg(
  xml: svgString,
  debugName: filename,
  enableMaskingOptimizer: false,
  enableClippingOptimizer: false,
  enableOverdrawOptimizer: false,
)

// Attempt 2: Optimizers ON (fallback for malformed paths)
encodeSvg(
  xml: svgString,
  debugName: filename,
  enableMaskingOptimizer: true,
  enableClippingOptimizer: true,
  enableOverdrawOptimizer: true,
)
```

## Output Structure

The converter maintains the original directory structure:

```
assets/pet/1/env_1/icon.svg
  → assets/pet_vg/1/env_1/icon.vg.bin

assets/pet/2/resource/image.svg
  → assets/pet_vg/2/resource/image.vg.bin
```

## Why Use Vector Graphics (VG)?

1. **Performance**: Eliminates runtime XML parsing
2. **File Size**: Typically 40-60% smaller than SVG
3. **Reliability**: Pre-compiled format reduces rendering errors
4. **Consistency**: Guaranteed rendering across platforms
5. **Startup Time**: Faster app launch and asset loading

## Troubleshooting

### Error: "Input directory not found"
- Ensure you're running the command from the project root
- Check that `assets/pet/` directory exists

### Error: "Infinity or NaN toInt"
- Remove `width: double.infinity` and `height: double.infinity` from VectorGraphic
- Use constrained containers (SizedBox, Container with fixed dimensions)

### Error: "Failed to convert [file.svg]"
- Check if the SVG file is valid XML
- Try optimizing the SVG with SVGO or similar tools
- Check console output for specific error details

### VG files not found in app
- Ensure `pubspec.yaml` includes all asset directories
- Run `flutter pub get` after modifying pubspec.yaml
- Perform hot restart (R) to reload asset manifest

### Blurry or low-quality rendering
- Use `BoxFit.contain` for proper scaling
- Provide explicit dimensions instead of infinity
- Ensure SVG source files have proper viewBox
- Check that container has bounded constraints

## Performance Tips

1. **Pre-compile in CI/CD**: Run batch converter during build process
2. **Cache VG files**: Commit VG files to version control
3. **Use VG in release builds**: Full performance benefits in release mode
4. **Lazy loading**: Load VG assets on-demand for large collections

## Development Commands

```bash
# Install dependencies
flutter pub get

# Check for outdated packages
flutter pub outdated

# Run batch converter
dart run lib/batch_converter.dart

# Run app on desktop
flutter run -d windows
flutter run -d linux
flutter run -d macos

# Build release
flutter build windows --release
```

## Project Structure

```
svg-vg_converter/
├── lib/
│   ├── main.dart              # App entry point
│   ├── compare_page.dart      # Comparison viewer UI
│   └── batch_converter.dart   # CLI conversion tool
├── assets/
│   ├── pet/                   # Source SVG files
│   └── pet_vg/                # Generated VG files
├── pubspec.yaml               # Flutter dependencies
└── README.md                  # This file
```

## Notes

- **UI doesn't convert**: Conversion is CLI-only to avoid runtime overhead
- **Two-stage encoding**: Tries safe mode first, then optimized mode on failure
- **Manifest required**: Both `assets/pet/` and `assets/pet_vg/` must be in pubspec.yaml
- **Desktop only**: Currently configured for desktop platforms (Windows/Linux/macOS)

## Contributing

Contributions are welcome! Please:

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

## License

Internal / TBD

## References

- [Flutter Vector Graphics Package](https://pub.dev/packages/vector_graphics)
- [Vector Graphics Compiler](https://pub.dev/packages/vector_graphics_compiler)
- [Flutter SVG Package](https://pub.dev/packages/flutter_svg)
