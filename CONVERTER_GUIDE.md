# Interactive Converter Guide

## Overview

The **Interactive Converter Page** allows you to convert SVG files to VG (Vector Graphics) format directly from the Flutter UI using a file picker. This is an alternative to the CLI batch converter for quick, on-demand conversions.

## Features

✅ **File Picker Integration** - Select one or multiple SVG files from your file system  
✅ **Live Conversion** - Convert SVG to VG in real-time  
✅ **Side-by-Side Comparison** - View SVG and VG rendering simultaneously  
✅ **File Metrics** - See file sizes and compression ratios  
✅ **Save VG Files** - Export converted VG files to your chosen location  
✅ **Batch Processing** - Select and convert multiple files at once  

## How to Use

### Step 1: Launch the App

Run the Flutter application:
```bash
flutter run -d windows
```

From the home screen, click on **"Interactive Converter"** button.

### Step 2: Pick SVG Files

1. Click the **"Pick SVG Files to Convert"** button
2. A file picker dialog will open
3. Navigate to your SVG files
4. Select one or multiple SVG files (use Ctrl+Click or Shift+Click for multiple selection)
5. Click **"Open"**

### Step 3: Conversion Process

The app will automatically:
- Read each selected SVG file
- Convert it to VG format using the vector_graphics_compiler
- Display the conversion result in a card

### Step 4: Review Results

Each conversion result card shows:

**Header Section:**
- File name
- Full file path
- Conversion timestamp

**Metrics:**
- 🔵 **SVG Size** - Original SVG file size
- 🟢 **VG Size** - Converted VG file size
- 🟠 **Saved** - Compression ratio (percentage saved)

**Comparison View:**
- **Left Panel** - SVG Original rendering
- **Right Panel** - VG Converted rendering

### Step 5: Save VG Files

To save a converted VG file:
1. Click the **💾 Save** icon button on any result card
2. Choose the destination folder
3. Enter the file name (defaults to `filename.vg.bin`)
4. Click **"Save"**

### Step 6: Manage Results

- **Remove Single Result**: Click the ❌ close icon on any card
- **Clear All Results**: Click the 🗑️ sweep icon in the app bar

## Understanding the Interface

### Status Indicator

At the top of the page, you'll see a status indicator:

- ✅ **Green Check**: "Vector Graphics libraries ready" - All systems operational
- ⚠️ **Orange Warning**: "Some libraries not initialized" - Conversion may fail for complex SVGs

### Conversion Button States

- **Normal State**: Blue button with "Pick SVG Files to Convert"
- **Converting State**: Button disabled with spinner showing "Converting..."

### Result Cards

Each card is color-coded:
- **Blue border** for SVG preview
- **Green border** for VG preview
- **Color chips** for metrics (Blue=SVG, Green=VG, Orange=Compression)

## Tips for Best Results

### ✅ DO:
- Select clean, well-formed SVG files
- Check the compression ratio - higher is better (40-60% is typical)
- Compare the visual quality between SVG and VG previews
- Save VG files with the `.vg.bin` extension

### ❌ DON'T:
- Don't convert extremely complex SVGs with thousands of paths
- Don't expect 100% identical rendering (minor differences are normal)
- Don't use this for batch conversion of large directories (use CLI instead)

## Troubleshooting

### "Warning: Some libraries not initialized"

**Cause**: Vector graphics native libraries failed to load  
**Solution**: 
1. Ensure you're running on a supported platform (Windows/Linux/macOS)
2. Try hot restarting the app (press `R` in terminal)
3. If issue persists, use the CLI batch converter instead

### Conversion fails for specific SVG

**Cause**: SVG file may have invalid syntax or unsupported features  
**Solution**:
1. Validate the SVG file in a browser or SVG editor
2. Try optimizing the SVG with SVGO or similar tools
3. Check the console/terminal for specific error messages

### VG preview appears blurry or pixelated

**Cause**: Rendering constraints issue  
**Solution**:
- This is already fixed in the code with proper sizing
- If still occurs, try resizing the window
- The saved VG file will still be high quality

### Save dialog doesn't appear

**Cause**: File picker permissions or platform issue  
**Solution**:
1. Ensure the app has file system permissions
2. Try running the app with administrator privileges
3. Use an alternative method to save (copy bytes programmatically)

### Out of memory when converting many files

**Cause**: Loading too many files at once  
**Solution**:
1. Convert files in smaller batches (10-20 at a time)
2. Remove old results before converting new files
3. For large batches, use the CLI batch converter instead

## Comparison: UI Converter vs CLI Batch Converter

| Feature | Interactive Converter (UI) | Batch Converter (CLI) |
|---------|---------------------------|----------------------|
| **Selection** | File picker (manual) | Recursive directory scan |
| **Preview** | Live SVG/VG comparison | No preview |
| **Best for** | Quick testing, single files | Large batches, automation |
| **Save location** | User chooses per file | Automatic mirror structure |
| **Speed** | Slower (UI overhead) | Faster (no UI) |
| **Convenience** | High (visual feedback) | Low (command-line) |
| **Memory usage** | Higher (keeps results) | Lower (streaming) |

## When to Use Each Method

### Use Interactive Converter (UI) When:
- ✅ Testing conversion of a few files
- ✅ Need to see visual comparison immediately
- ✅ Want to selectively save certain conversions
- ✅ Don't know exact file paths
- ✅ Prefer graphical interface

### Use Batch Converter (CLI) When:
- ✅ Converting entire directory trees
- ✅ Processing hundreds of files
- ✅ Automating in CI/CD pipeline
- ✅ Need consistent output structure
- ✅ Running on headless server

## Advanced Features

### Multiple File Selection

To select multiple files efficiently:

**Windows**:
- Hold `Ctrl` and click to select individual files
- Hold `Shift` and click to select range
- Press `Ctrl+A` to select all files in current folder

**macOS**:
- Hold `Cmd` and click for individual selection
- Hold `Shift` and click for range selection

### Understanding Compression Ratios

The compression ratio shows how much space VG saves compared to SVG:

- **50-70%**: Excellent - VG is much smaller
- **30-50%**: Good - Significant savings
- **10-30%**: Fair - Moderate savings
- **< 10%**: Poor - Consider keeping SVG
- **Negative**: Bad - VG is larger (rare, usually means the SVG was already optimized)

### Quality Assurance

Always visually compare the SVG and VG previews:

1. Check for missing elements
2. Verify colors are correct
3. Look for distorted shapes
4. Ensure text renders properly (if any)
5. Zoom in to check fine details

## Integration with Existing Workflow

### Workflow 1: Test Before Batch

1. Use **Interactive Converter** to test a few sample SVGs
2. Verify conversion quality
3. If good, use **CLI Batch Converter** for the entire directory
4. Use **Compare Assets** page to verify final results

### Workflow 2: Selective Conversion

1. Use **Interactive Converter** to convert only specific files
2. Save VG files to project's `assets/pet_vg/` directory
3. Update `pubspec.yaml` if needed
4. Hot restart app to load new assets

### Workflow 3: Quick Preview

1. Use **Interactive Converter** to preview how SVG will look as VG
2. Don't save the VG file
3. Make adjustments to SVG source if needed
4. Re-convert and compare again

## Performance Considerations

### Memory Usage
Each conversion result is kept in memory with:
- Original SVG bytes
- Converted VG bytes
- Preview widgets

**Recommendation**: Clear results after saving to free memory

### Conversion Speed
Typical conversion times:
- Simple SVG (< 10 KB): < 100ms
- Medium SVG (10-50 KB): 100-500ms
- Complex SVG (> 50 KB): 500ms-2s

**Note**: First conversion may be slower due to library initialization

## Keyboard Shortcuts

While in the Interactive Converter page:

- `Esc` - Go back to home
- `Ctrl+O` - Open file picker (when button is focused)
- `Ctrl+S` - Save first result (custom implementation needed)
- `Delete` - Remove focused result card (custom implementation needed)

## API Reference (for Developers)

### Main Classes

**ConverterPage** - Main widget for the converter UI
- State management for conversion results
- File picker integration
- Library initialization

**ConversionResult** - Data model for each conversion
```dart
class ConversionResult {
  final String fileName;
  final String filePath;
  final Uint8List svgData;
  final Uint8List vgData;
  final int svgSize;
  final int vgSize;
  final DateTime timestamp;
}
```

**_MemoryBytesLoader** - Custom BytesLoader for in-memory VG data
```dart
class _MemoryBytesLoader extends BytesLoader {
  final Uint8List bytes;
  Future<ByteData> loadBytes(BuildContext? context);
}
```

### Key Methods

**_pickAndConvertFiles()** - Opens file picker and converts selected files
**_convertFile(File)** - Converts a single file to VG
**_encodeToVg(String, String)** - Encodes SVG string to VG bytes
**_saveVgFile(ConversionResult)** - Saves VG file to user-selected location

## Security Considerations

### File Access
The app requires permission to:
- Read files from file system (for SVG input)
- Write files to file system (for VG output)

### Data Privacy
- SVG files are read into memory temporarily
- VG data is kept in memory until cleared
- No data is sent to external servers
- All processing is done locally

## Future Enhancements

Potential features for future versions:

- [ ] Drag & drop file support
- [ ] Directory selection (convert entire folder)
- [ ] Export all VG files at once
- [ ] Conversion settings (optimizer toggles)
- [ ] Undo/redo functionality
- [ ] Search/filter results
- [ ] Sort results by size/name/date
- [ ] Compare mode (diff highlighting)
- [ ] Batch export with custom naming
- [ ] History of conversions
- [ ] Settings persistence

## FAQ

**Q: Can I convert files from network locations?**  
A: Yes, as long as your file picker can access them

**Q: What happens if I close the app?**  
A: All conversion results are lost (not persisted)

**Q: Can I convert non-SVG files?**  
A: No, the file picker only allows .svg files

**Q: Is there a file size limit?**  
A: No hard limit, but very large files (>10MB) may cause memory issues

**Q: Can I edit the SVG before conversion?**  
A: No, use an external SVG editor, then re-convert

**Q: Why does VG look different from SVG?**  
A: Minor rendering differences are normal due to different rendering engines

**Q: Can I convert VG back to SVG?**  
A: No, VG is a compiled binary format (one-way conversion)

## Support

For issues or questions:
1. Check this guide first
2. Review the main [README.md](README.md)
3. Check console output for error messages
4. Create an issue on the repository

## License

Same as main project - Internal / TBD
