# svg_vg_converter

Tooling & viewer untuk konversi massal SVG -> Flutter Vector Graphic (.vg.bin) dan membandingkan hasil render.

## Workflow
1. Letakkan semua SVG di folder: `assets/pet/` (subfolder bebas / recursive).
2. Jalankan konversi via CLI (bukan di UI):
	```bash
	dart run lib/batch_converter.dart
	```
	- Default input: `assets/pet`
	- Default output: `assets/pet_vg`
	- Argumen kustom (opsional): `dart run lib/batch_converter.dart <inputDir> <outputDir>`
3. Jalankan aplikasi Flutter & halaman utama akan langsung menampilkan perbandingan:
	- Kiri: SVG asli
	- Kanan: VG hasil kompilasi (`assets/pet_vg/...`)
4. Jika menambah / mengubah SVG, jalankan ulang perintah konversi lalu lakukan hot restart agar manifest ter-update.

## Struktur Output
Contoh mapping:
```
assets/pet/1/env_1/icon.svg
-> assets/pet_vg/1/env_1/icon.vg.bin
```

## Kenapa VG?
Format vector_graphics Flutter mengurangi parsing XML runtime & bisa meningkatkan performa/ukuran build.

## Catatan
- UI tidak melakukan konversi (dipindahkan agar tidak membebani runtime / release build).
- Encoder mencoba dua tahap: tanpa optimizer dulu, lalu dengan optimizer jika gagal.
- Pastikan `assets/pet/` dan `assets/pet_vg/` terdaftar di `pubspec.yaml`.

## Perintah Berguna
Audit dependency usang:
```bash
flutter pub outdated
```

## Lisensi
Internal / TBD.
