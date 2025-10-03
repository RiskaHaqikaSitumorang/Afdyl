# 🔧 Troubleshooting Guide - Hijaiyah Tracing

## ✅ Fixes Applied (Oct 3, 2025)

### Problem 1: SVG Dashed Paths Kecil di Pojok Kiri Atas
**Root Cause**: SVG paths menggunakan koordinat viewBox asli tanpa scaling

**Solution**: 
- Added canvas transformation (translate + scale) sebelum render paths
- Scale calculated: `min(canvasWidth/viewBoxWidth, canvasHeight/viewBoxHeight)`
- Offset for centering: `(canvasSize - scaledSize) / 2`

```dart
// In _drawSeparatedDashedPaths()
canvas.save();
canvas.translate(offsetX, offsetY);
canvas.scale(scale, scale);
// ... draw paths ...
canvas.restore();
```

### Problem 2: Tracing Coverage Selalu Salah
**Root Cause**: Coordinate system mismatch
- User traces: Canvas coordinates
- Target points: Normalized (0-1) then scaled to full canvas
- SVG paths: Viewbox coordinates with centering offset

**Solution**: 
Applied same transformation to coverage calculation:
```dart
// Convert normalized points to canvas coordinates
final svgX = point.position.dx * viewBox.width;
final svgY = point.position.dy * viewBox.height;
final canvasX = (svgX * scale) + offsetX;
final canvasY = (svgY * scale) + offsetY;
```

### Problem 3: PNG Background Not Aligned with SVG Paths
**Root Cause**: Different scaling logic for PNG vs SVG

**Solution**:
- Use SVG viewBox as reference for PNG scaling
- Apply same scale and offset calculations
- Make PNG semi-transparent (opacity 0.4) so dashed lines visible

## 🎨 Current Rendering Pipeline

### Layer Order (bottom to top):
1. **White Background** - Solid white
2. **PNG Image** - Semi-transparent (40%), scaled and centered using SVG viewBox
3. **Dashed Paths** - Grey dashed lines from SVG, transformed to match PNG
4. **User Traces** - Red lines, drawn in canvas coordinates

### Coordinate Systems:

```
SVG ViewBox Space:
  - Origin: (0, 0)
  - Size: viewBox.width x viewBox.height
  - Example: 160 x 160

Canvas Space:
  - Origin: (0, 0)  
  - Size: size.width x size.height
  - Example: 350 x 350

Transformation:
  scale = min(350/160, 350/160) = 2.1875
  offsetX = (350 - 160*2.1875) / 2 = 0
  offsetY = (350 - 160*2.1875) / 2 = 0

Point Conversion:
  canvasX = (svgX * scale) + offsetX
  canvasY = (svgY * scale) + offsetY
```

## 🐛 Debug Mode

To visualize target points for debugging, uncomment this line in `paint()`:

```dart
// 4. [DEBUG] Draw target points (uncomment untuk debug)
_drawDebugTargetPoints(canvas, size);
```

This will show blue dots at every target point location. Should align with dashed paths.

## 📊 Coverage Parameters

Current settings:
```dart
const double coverageRadius = 30.0;  // Pixels tolerance
const double requiredCoverage = 1.0; // 100% required
```

### Adjusting Tolerance:

**Too Strict** (users complain "sudah mengikuti tapi tetap salah"):
```dart
const double coverageRadius = 40.0; // Increase
```

**Too Lenient** (accepts sloppy tracing):
```dart
const double coverageRadius = 20.0; // Decrease
```

## 🔍 Verification Checklist

When testing, verify:

### 1. Visual Alignment
- [ ] Dashed paths centered in canvas
- [ ] Dashed paths match PNG background shape
- [ ] Dashed paths same size as PNG background
- [ ] No tiny paths in corner

### 2. Tracing Accuracy
- [ ] User trace directly on dashed path = High coverage
- [ ] Slightly off path = Medium coverage
- [ ] Very off path = Low coverage

### 3. Console Logs
Check for these logs:
```
📋 Found X <g> elements in SVG for letter: X
📊 Total: X groups, Y total paths
💾 Saved trace 1 with Z points
🎯 Coverage: XX.X% (covered/total points)
📐 Scale: X.XX, Offset: (X.X, Y.Y)
```

## 🎯 Common Issues

### Issue: "Coverage 0% even when tracing perfectly"
**Diagnosis**:
- Uncomment `_drawDebugTargetPoints()`
- Check if blue dots align with dashed paths

**Possible Causes**:
1. Coordinate transformation mismatch
2. Wrong viewBox size
3. PNG and SVG different sizes

**Solution**:
- Verify SVG viewBox in console logs
- Check PNG dimensions match SVG conceptually

### Issue: "Dashed paths stretched/squashed"
**Diagnosis**: 
- Check aspect ratio calculation

**Fix**:
```dart
// Should use min() not max()
final scale = scaleX < scaleY ? scaleX : scaleY;
```

### Issue: "Can't see dashed paths"
**Possible Causes**:
1. PNG too opaque
2. Stroke width too thin
3. Color too light

**Fix**:
```dart
// Adjust PNG opacity
..color = Colors.white.withOpacity(0.4); // Lower = more transparent

// Adjust stroke width
..strokeWidth = 3.0; // Increase for thicker lines

// Adjust color
..color = Colors.grey[600]!; // Darker grey
```

## 📝 File Requirements

### SVG Dashed Files:
```xml
<svg xmlns="http://www.w3.org/2000/svg" width="160px" height="160px" viewBox="0 0 160 160">
  <g>
    <path d="M 77.5,26.5 C ..."/>
  </g>
  <g>
    <path d="M 80.5,33.5 C ..."/>
  </g>
</svg>
```

**Requirements**:
- ✅ Must have `viewBox` attribute
- ✅ Each `<g>` is a separate trace group
- ✅ Paths should be the actual letter shape (not border/frame)
- ✅ Coordinates should be within viewBox bounds

### PNG Original Files:
**Requirements**:
- ✅ Same conceptual size as SVG viewBox
- ✅ Clear, high-contrast image
- ✅ Transparent or white background recommended
- ✅ Letter should fill most of the image

## 🎓 Testing Strategy

### Test Case 1: Simple Letter (no dots)
Example: ا (Alif)
1. Trace vertical line from top to bottom
2. Should get 100% coverage

### Test Case 2: Letter with Dots
Example: ب (Ba)
1. Trace body (curved line)
2. Trace dot below
3. Should get 100% coverage

### Test Case 3: Complex Letter
Example: ض (Dhad) - from your screenshot
1. Trace main curved body
2. Trace small head loop
3. Trace dot on top
4. Should get 100% coverage

## 🚀 Performance Notes

Current implementation is optimized:
- **Path caching**: SVG parsed once, reused
- **PNG caching**: Image loaded once
- **Efficient coverage**: Only checks within radius
- **Canvas transforms**: Hardware accelerated

Expected performance:
- **Parse SVG**: ~10-50ms
- **Load PNG**: ~50-100ms  
- **Coverage check**: ~5-20ms
- **Frame render**: ~16ms (60 FPS)

## 📚 Related Code Sections

### Key Files:
- `svg_path_parser.dart` - Line 187-230: Coverage calculation
- `svg_tracing_canvas.dart` - Line 169-210: Path rendering with transforms
- `svg_tracing_canvas.dart` - Line 137-165: PNG background rendering

### Key Methods:
- `_drawSeparatedDashedPaths()` - Renders dashed guides
- `_calculateDashedPathCoverage()` - Validates tracing
- `_drawBackground()` - Renders PNG with correct scaling

---

**Last Updated**: October 3, 2025
**Status**: ✅ All critical issues resolved
