# 📝 Sistem Hijaiyah Tracing - Dokumentasi

## 🎯 Konsep Sistem

Sistem tracing huruf Hijaiyah menggunakan pendekatan **dual-file system**:

1. **File PNG** (`assets/images/hijaiyah_original/*.png`) 
   - Gambar huruf Hijaiyah original yang jelas
   - Digunakan sebagai **background visual** agar user dapat melihat huruf dengan jelas

2. **File SVG Dashed** (`assets/images/hijaiyah_svg_dashed/*.svg`)
   - File SVG berisi path dengan garis putus-putus (dashed)
   - Digunakan sebagai **jalur tracing** yang harus diikuti user
   - Setiap elemen `<g>` dalam SVG merepresentasikan **grup terpisah**

## 🏗️ Struktur File SVG

Contoh struktur SVG dashed:

```xml
<svg xmlns="http://www.w3.org/2000/svg" width="160px" height="160px">
  <g>
    <!-- Path untuk body huruf -->
    <path style="opacity:0.875" fill="#f7f7f7" d="M 77.5,26.5 C ..."/>
  </g>
  <g>
    <!-- Path untuk titik pertama -->
    <path style="opacity:1" fill="#131313" d="M 80.5,33.5 C ..."/>
  </g>
  <g>
    <!-- Path untuk titik kedua -->
    <path style="opacity:1" fill="#0f0f0f" d="M 127.5,46.5 C ..."/>
  </g>
</svg>
```

### 📦 Grup `<g>` Element

- Setiap `<g>` adalah **grup terpisah** yang dapat di-trace secara independen
- **Tidak ada koneksi** antara grup satu dengan yang lain
- Mendukung huruf dengan titik seperti: ب، ت، ث، ن، dll.
- User dapat trace body huruf dulu, kemudian trace titik-titiknya terpisah

## 🎨 Rendering System

### Canvas Layers (dari bawah ke atas):

1. **Layer 1: White Background**
   - Background putih solid

2. **Layer 2: PNG Image**
   - Gambar huruf original sebagai panduan visual
   - Di-scale agar fit dengan canvas
   - Aspect ratio dijaga

3. **Layer 3: Dashed Guide Paths**
   - Path dari setiap grup `<g>` digambar terpisah
   - Warna abu-abu dengan efek dashed
   - Stroke width: 2.0

4. **Layer 4: User Traces**
   - Semua traces yang sudah selesai (dari `allTraces`)
   - Current trace yang sedang digambar (dari `currentTrace`)
   - Warna merah dengan stroke width: 6.0

## 🔄 Flow Tracing

### 1. Inisialisasi
```dart
// Load PNG background image
_loadBackgroundImage();

// Parse SVG dashed file
await SVGPathParser.parseLetter(letter);
```

### 2. User Tracing
```dart
// User mulai trace
onPanStart: tracingService.startTracing(position);

// User melanjutkan trace
onPanUpdate: tracingService.updateTracing(position);

// User selesai trace satu stroke
onPanEnd: tracingService.endTracing();
// → Current trace disimpan ke allTraces[]
// → Current trace di-clear untuk stroke berikutnya
```

### 3. Multiple Disconnected Traces

User dapat membuat **beberapa trace terpisah**:

```
Trace 1: Body huruf ب  (garis lengkung bawah)
Trace 2: Titik pertama di bawah
```

Setiap kali `endTracing()` dipanggil:
- Current trace disimpan ke `allTraces`
- User bisa mulai trace baru yang terpisah

### 4. Validasi Manual

User menekan tombol **"Cek"**:

```dart
tracingService.validateTracing();
```

#### Proses Validasi:

1. **Combine all traces**
   ```dart
   List<Offset> combinedTrace = [];
   for (final trace in allTraces) {
     combinedTrace.addAll(trace);
   }
   combinedTrace.addAll(currentTrace);
   ```

2. **Calculate coverage**
   - Check berapa persen dari target points yang ter-cover
   - Coverage radius: 25.0 pixels
   - **Requirement: 100% coverage**

3. **Result**
   - ✅ **100%**: Success! Play audio, show success message
   - ❌ **<100%**: Show feedback berdasarkan percentage
     - <30%: "Trace semua bagian huruf termasuk titik-titiknya"
     - <70%: "Hampir benar, lengkapi bagian yang terlewat"
     - <100%: "Sedikit lagi, pastikan semua bagian ter-trace"

## 🎮 User Controls

### Tombol "Cek" (Hijau)
- Trigger manual validation
- Tidak ada auto-validation
- User kontrol penuh kapan mau validasi

### Tombol "Sound" (Biru)
- Play audio nama huruf
- Helps user mengenali huruf

### Tombol "Reset" (Abu-abu)
- Clear semua traces (allTraces + currentTrace)
- Bisa mengulang dari awal
- Tidak reload data SVG/PNG

## 📊 Data Structure

### SVGLetterData
```dart
class SVGLetterData {
  final List<SVGPathPoint> pathPoints;        // All points for coverage
  final List<Path> strokePaths;               // All paths
  final List<int> strokeOrder;                // Stroke order
  final Size viewBox;                         // SVG viewbox
  final List<List<Path>> separatedPaths;      // Grouped paths by <g>
}
```

### SVGTracingService
```dart
class SVGTracingService {
  List<Offset> currentTrace = [];           // Current active trace
  List<List<Offset>> allTraces = [];        // All completed traces
  SVGLetterData? currentLetterData;         // Parsed SVG data
  Size? canvasSize;                         // Canvas dimensions
}
```

## 🎯 Coverage Calculation

### Algorithm:
```dart
1. Get all target points from SVG paths
2. Convert to canvas coordinates
3. Combine all user traces (allTraces + currentTrace)
4. For each target point:
   - Check if any trace point is within coverageRadius (25px)
   - If yes, mark as covered
5. Calculate: coveredPoints / totalPoints
```

### Tolerance:
- **Coverage radius**: 25.0 pixels
- **Required coverage**: 100% (1.0)

## 🔊 Audio Feedback

### Success Sound
```dart
// Play ketika coverage >= 100%
await _playSuccessSound(currentLetter);
```

### Audio Mapping
```dart
'ا': 'alif.m4a',
'ب': 'ba.m4a',
// dst...
```

## 🐛 Debugging

### Console Logs:
```
📋 Found X <g> elements in SVG for letter: X
  📦 Group 1: Found Y path(s)
    ✓ Added path to group 1
  ✅ Group 1 added with Y path(s), stroke order: 1
📊 Total: X groups, Y total paths

💾 Saved trace 1 with Z points
💾 Saved trace 2 with Z points

🎯 Coverage: 85.3% (123/144 points)
📝 Total traces: 2 completed + current (34 points)
```

## 📝 File Naming Convention

### PNG Files:
```
assets/images/hijaiyah_original/
  ├── alif.png
  ├── ba.png
  ├── ta.png
  └── ...
```

### SVG Dashed Files:
```
assets/images/hijaiyah_svg_dashed/
  ├── alif.svg
  ├── ba.svg
  ├── ta.svg
  └── ...
```

## ⚡ Performance Tips

1. **PNG Loading**: Async loading dengan caching
2. **SVG Parsing**: Parse sekali saat init, cache data
3. **Canvas Rendering**: Efficient path drawing
4. **Coverage Check**: Optimized distance calculation

## 🎓 Usage Example

```dart
// 1. Create service
final tracingService = SVGTracingService();

// 2. Initialize letter
await tracingService.initializeLetter('ب');

// 3. User traces body huruf
// ... user draws ...
tracingService.endTracing(); // Save to allTraces[0]

// 4. User traces titik pertama
// ... user draws ...
tracingService.endTracing(); // Save to allTraces[1]

// 5. User validates
await tracingService.validateTracing();
// → Check coverage dari allTraces[0] + allTraces[1]

// 6. Reset if needed
tracingService.resetTracing();
// → Clear all traces
```

## 🚀 Benefits

1. ✅ **Clear Visual**: PNG background memberikan panduan visual jelas
2. ✅ **Accurate Tracing**: SVG paths memberikan jalur tracing akurat
3. ✅ **Flexible**: Support disconnected traces untuk huruf dengan titik
4. ✅ **User Control**: Manual validation, user yang kontrol
5. ✅ **Feedback**: Detailed feedback berdasarkan coverage percentage
6. ✅ **Scalable**: Easy to add more letters

## 📚 Related Files

- `lib/services/svg_path_parser.dart` - SVG parsing logic
- `lib/services/svg_tracing_service.dart` - Tracing business logic
- `lib/widgets/svg_tracing_canvas.dart` - Canvas rendering
- `lib/screens/hijaiyah_tracing_detail_page.dart` - UI screen

## 🎉 Success Criteria

Tracing dianggap **berhasil** jika:
- ✅ Coverage >= 100%
- ✅ Semua grup `<g>` ter-cover (body + semua titik)
- ✅ User press tombol "Cek"

---

**Last Updated**: October 3, 2025
**Version**: 2.0 (Dual-File System)
