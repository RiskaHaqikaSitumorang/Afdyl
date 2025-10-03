# 🐛 Troubleshooting - Log Tidak Muncul

## Masalah
Log tidak muncul di terminal saat menjalankan aplikasi dan menggunakan fitur recording.

## Kemungkinan Penyebab & Solusi

### 1. ✅ Flutter Run Mode

**Kemungkinan:** App dijalankan dalam mode release atau profile.

**Cek dengan:**
```bash
# Pastikan running di debug mode
flutter run --debug
```

**Atau lihat di VS Code/Android Studio:**
- Di VS Code: Tekan `Ctrl+Shift+P` → ketik "Flutter: Select Device"
- Pastikan tidak ada flag `--release` atau `--profile`

---

### 2. ✅ Terminal Output Filter

**Kemungkinan:** Terminal memfilter output tertentu.

**Solusi:**
```bash
# Jalankan dengan verbose
flutter run --verbose

# Atau redirect semua output
flutter run 2>&1 | tee app_log.txt

# Ini akan menyimpan semua log ke file app_log.txt
```

---

### 3. ✅ Platform Specific

#### Untuk Android:
```bash
# Cek logcat langsung
adb logcat | grep -E "flutter:|LatihanKataPage|QuranSTT"

# Atau gunakan flutter logs
flutter logs
```

#### Untuk iOS:
```bash
# Buka Console app di Mac
# Filter by: flutter

# Atau terminal:
flutter logs
```

---

### 4. ✅ IDE Configuration

#### VS Code:
1. Buka **Output** panel (View → Output)
2. Pilih "Dart & Flutter" dari dropdown
3. Pastikan "Debug Console" juga terbuka

#### Android Studio:
1. Buka tab **Run** di bawah
2. Pastikan filter tidak aktif (ikon filter harus off)
3. Cek tab **Logcat** untuk Android-specific logs

---

### 5. ✅ Cara Mudah - Gunakan debugPrint

Jika `print()` tidak muncul, kita bisa ganti dengan `debugPrint()`:

**File yang perlu diubah:**
- `lib/services/quran_stt_service.dart`
- `lib/services/latihan_service.dart`
- `lib/screens/latihan_kata_page.dart`
- `lib/widgets/recording_button.dart`

**Find & Replace:**
```
Find: print(
Replace: debugPrint(
```

---

### 6. ✅ Test Log Sederhana

Buat file test untuk memastikan logging berfungsi:

**Buat file:** `test_logging.dart`
```dart
void main() {
  print('🔴 TEST 1: print() berfungsi');
  debugPrint('🟢 TEST 2: debugPrint() berfungsi');
  
  for (int i = 0; i < 5; i++) {
    print('Test $i');
  }
}
```

**Jalankan:**
```bash
dart run test_logging.dart
```

Jika ini muncul, berarti `print()` berfungsi.

---

### 7. ✅ Check Build Configuration

**File:** `android/app/build.gradle`

Pastikan tidak ada konfigurasi yang memblok logging:
```gradle
buildTypes {
    release {
        // Jangan sampai ada ini:
        // minifyEnabled true
        // shrinkResources true
    }
}
```

---

### 8. ✅ Alternatif - Gunakan Logger Package

Jika `print()` tetap tidak muncul, install package logger:

```bash
flutter pub add logger
```

**Buat helper:**
```dart
// lib/utils/app_logger.dart
import 'package:logger/logger.dart';

final logger = Logger(
  printer: PrettyPrinter(
    methodCount: 0,
    errorMethodCount: 5,
    lineLength: 80,
    colors: true,
    printEmojis: true,
  ),
);
```

**Gunakan:**
```dart
import 'package:afdyl/utils/app_logger.dart';

logger.d('[LatihanKataPage] Debug message');
logger.i('[LatihanKataPage] Info message');
logger.w('[LatihanKataPage] Warning message');
logger.e('[LatihanKataPage] Error message');
```

---

### 9. ✅ UI Logging (Fallback)

Jika semua gagal, tampilkan log di UI sementara:

```dart
// Di LatihanKataPage, tambahkan state:
List<String> _logs = [];

// Di initState atau fungsi lain:
void _addLog(String message) {
  setState(() {
    _logs.add('${DateTime.now().toIso8601String()}: $message');
    if (_logs.length > 20) _logs.removeAt(0); // Keep last 20
  });
  print(message); // Tetap print juga
}

// Di build(), tambahkan:
Positioned(
  bottom: 100,
  left: 0,
  right: 0,
  child: Container(
    height: 200,
    color: Colors.black.withOpacity(0.7),
    child: ListView.builder(
      itemCount: _logs.length,
      itemBuilder: (context, index) {
        return Text(
          _logs[index],
          style: TextStyle(color: Colors.white, fontSize: 10),
        );
      },
    ),
  ),
)
```

---

### 10. ✅ Restart Everything

Kadang masalah sederhana:

```bash
# Stop app
flutter run # Tekan 'q' untuk quit

# Hot restart tidak cukup, perlu full restart
flutter clean
flutter pub get
flutter run --debug
```

---

## 🎯 Quick Test Commands

Jalankan ini satu per satu untuk isolate masalah:

```bash
# 1. Test basic print
echo "print('TEST LOG');" | flutter run --debug

# 2. Check flutter version
flutter doctor -v

# 3. Check connected devices
flutter devices

# 4. Run with all logs
flutter run --debug --verbose

# 5. Check if app crashed
flutter logs

# 6. Monitor in real-time
flutter run --debug & flutter logs
```

---

## 📱 Platform Specific Solutions

### Android Only:
```bash
# Clear logcat buffer
adb logcat -c

# Then run app and monitor
adb logcat | grep -i "flutter"
```

### iOS Only:
```bash
# Open simulator logs
open -a Console

# Filter by: flutter or process name
```

---

## 🆘 Jika Masih Tidak Muncul

1. **Screenshot error** (jika ada)
2. **Paste output** dari `flutter doctor -v`
3. **Paste output** dari `flutter run --verbose`
4. **Cek** apakah ada crash: `flutter logs`

---

## ✅ Checklist Debugging

- [ ] Running di debug mode (`flutter run --debug`)
- [ ] Terminal tidak filtered
- [ ] IDE output panel terbuka
- [ ] App tidak crash (cek `flutter logs`)
- [ ] Sudah coba `flutter clean && flutter run`
- [ ] Sudah coba `print()` di main() (harus muncul)
- [ ] Sudah coba tap button recording
- [ ] Sudah cek logcat/console (Android/iOS)

---

## 📄 Contoh Output yang Seharusnya Muncul

Ketika app pertama kali dibuka:
```
🚀🚀🚀 [MAIN] APP STARTING 🚀🚀🚀
[MAIN] Loading environment variables...
[MAIN] ✅ Environment variables loaded
[MAIN] Initializing Supabase...
[MAIN] ✅ Supabase initialized
[MAIN] Running app...
[MAIN] ✅ App started
```

Ketika masuk ke Latihan Kata page:
```
[LatihanKataPage] 🎬 initState dipanggil
[LatihanKataPage] 🎨 Setup animations...
[LatihanKataPage] 🚀 Memulai inisialisasi services...
[LatihanService] 🚀 Inisialisasi LatihanService...
[QuranSTT] 🚀 Memulai inisialisasi...
```

Ketika tap button:
```
[RecordingButton] 🔘 Button ditekan! isListening: false, isProcessing: false
[LatihanKataPage] 👆 onTap callback dipanggil
[LatihanKataPage] ▶️  Memanggil startListening...
[LatihanService] 🎙️  Mulai listening...
[QuranSTT] 🎙️  Memulai listening...
```

**Jika TIDAK ADA satupun dari log ini yang muncul**, ada masalah dengan konfigurasi Flutter atau IDE.
