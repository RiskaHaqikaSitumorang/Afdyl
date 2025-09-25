# Page Transitions - Animation Guide

## ✅ Implementasi Animasi Halaman Profile

### Fitur yang telah ditambahkan:
- ✅ Animasi slide dari kanan ke kiri saat membuka ProfilePage
- ✅ Animasi smooth dengan curve easing
- ✅ Duration 300ms untuk transisi yang responsif
- ✅ Extension method untuk kemudahan penggunaan

### Cara Penggunaan:

#### 1. Import Page Transitions
```dart
import '../widgets/page_transitions.dart';
```

#### 2. Gunakan Extension Methods
```dart
// Slide dari kanan (untuk Profile Page)
context.pushSlideRight(const ProfilePage());

// Slide dari kiri 
context.pushSlideLeft(const SomePage());

// Slide dari bawah
context.pushSlideUp(const SomePage());

// Fade transition
context.pushFade(const SomePage());

// Replace dengan slide
context.pushReplacementSlideRight(const SomePage());
```

## 🔧 Tipe Animasi yang Tersedia:

### SlideRightRoute
- **Mulai dari**: Kanan layar (Offset(1.0, 0.0))
- **Berakhir di**: Tengah layar (Offset.zero)
- **Durasi**: 300ms
- **Curve**: Curves.easeInOut
- **Penggunaan**: Ideal untuk navigasi ke detail page atau profile

### SlideLeftRoute
- **Mulai dari**: Kiri layar (Offset(-1.0, 0.0))
- **Berakhir di**: Tengah layar (Offset.zero)
- **Durasi**: 300ms
- **Curve**: Curves.easeInOut
- **Penggunaan**: Ideal untuk navigasi back atau previous page

### SlideUpRoute
- **Mulai dari**: Bawah layar (Offset(0.0, 1.0))
- **Berakhir di**: Tengah layar (Offset.zero)
- **Durasi**: 400ms
- **Curve**: Curves.easeInOut
- **Penggunaan**: Ideal untuk modal atau popup pages

### FadeRoute
- **Efek**: Fade in/out opacity
- **Durasi**: 500ms fade in, 300ms fade out
- **Penggunaan**: Ideal untuk splash screens atau gentle transitions

## 📱 Implementasi di Dashboard

### Sebelum:
```dart
Navigator.pushNamed(context, AppRoutes.profile);
```

### Sesudah:
```dart
context.pushSlideRight(const ProfilePage());
```

## 🎯 Rekomendasi Penggunaan untuk Halaman Lain:

### 1. Quran Reading Page
```dart
// Slide dari kanan untuk detail
context.pushSlideRight(const ReadingPage(...));
```

### 2. Hijaiyah Tracing
```dart
// Slide dari bawah untuk interactive page
context.pushSlideUp(const HijaiyahTracingPage());
```

### 3. Settings atau Qibla
```dart
// Fade untuk settings
context.pushFade(const QiblaPage());
```

### 4. Back Navigation
```dart
// Manual slide left untuk custom back
context.pushSlideLeft(const PreviousPage());
```

## 🔄 Kemungkinan Enhancement:

### Custom Animations
```dart
class CustomBounceRoute<T> extends PageRouteBuilder<T> {
  // Implementasi custom bounce animation
}
```

### Scale Transitions
```dart
class ScaleRoute<T> extends PageRouteBuilder<T> {
  // Implementasi scale up/down animation
}
```

### Rotation Transitions
```dart
class RotationRoute<T> extends PageRouteBuilder<T> {
  // Implementasi rotation animation
}
```

## 📋 Testing Checklist:

- [x] Profile page membuka dengan slide dari kanan
- [x] Animasi smooth dan tidak lag
- [x] Back gesture berfungsi normal
- [x] Durasi animasi sesuai (300ms)
- [x] Tidak ada error atau crash
- [x] Compatible dengan web build

## 🚀 Next Steps (Optional):

1. **Implement di halaman lain**:
   - Quran reading → SlideRight
   - Hijaiyah tracing → SlideUp
   - Settings → Fade
   - Modal dialogs → SlideUp

2. **Add custom gestures**:
   - Swipe right to open profile
   - Swipe down to close modal

3. **Add hero animations**:
   - Profile picture transition
   - Icon to page transitions

4. **Add page transition configuration**:
   - Global theme untuk consistent animations
   - User preference untuk animation speed

## 💡 Tips:

- Gunakan `SlideRightRoute` untuk detail pages
- Gunakan `SlideUpRoute` untuk modal/bottom sheets
- Gunakan `FadeRoute` untuk subtle transitions
- Pertahankan konsistensi animasi di seluruh app
- Test di device yang lambat untuk memastikan performance
