# 📊 Panduan Logging - Latihan Kata Feature

## Overview
Logging telah ditambahkan ke seluruh alur kerja fitur Latihan Kata untuk memudahkan debugging dan monitoring proses speech-to-text.

## 🎯 Lokasi Logging

### 1. **LatihanKataPage** (`lib/screens/latihan_kata_page.dart`)
- Inisialisasi services
- Status update dari stream
- Microphone permission checking
- Animasi pulse control

### 2. **LatihanService** (`lib/services/latihan_service.dart`)
- Delegasi ke QuranSTTService
- Stream forwarding
- Start/stop listening

### 3. **QuranSTTService** (`lib/services/quran_stt_service.dart`)
- Inisialisasi Speech-to-Text
- Listening lifecycle
- Text recognition
- Verse matching (exact, fuzzy, partial)
- Status broadcasting

## 🔍 Format Log

Setiap log menggunakan format:
```
[ServiceName] 🎯 Pesan log
```

### Emoji Legend:
- 🚀 = Memulai proses
- ✅ = Berhasil
- ❌ = Error/Gagal
- ⚠️  = Warning
- 🎙️  = Audio/Listening related
- 🛑 = Stop operation
- ⏳ = Processing/Waiting
- 🔍 = Searching
- 📊 = Status update
- 📡 = Broadcasting/Streaming
- 📨 = Receiving data
- 🎯 = Result/Match
- 🔚 = Disposal/Cleanup
- 🧹 = Data cleaning
- ✂️  = Text trimming
- 💔 = No match found

## 📋 Alur Proses dengan Log

### A. Inisialisasi (saat halaman dibuka)
```
[LatihanKataPage] 🚀 Memulai inisialisasi services...
[LatihanService] 🚀 Inisialisasi LatihanService...
[QuranSTT] 🚀 Memulai inisialisasi...
[QuranSTT] 🎤 Menginisialisasi Speech-to-Text...
[QuranSTT] ✅ Inisialisasi selesai. Speech enabled: true
[QuranSTT] 📡 Broadcasting status: listening=false, processing=false, arabicText=kosong
[LatihanService] ✅ QuranSTTService berhasil diinisialisasi
[LatihanService] 📡 Stream listener terpasang
[LatihanKataPage] ✅ Services berhasil diinisialisasi
[LatihanKataPage] 🎤 Memeriksa microphone permission...
[LatihanKataPage] 📊 Status permission: PermissionStatus.granted
[LatihanKataPage] ✅ Microphone permission granted
[LatihanKataPage] 📡 Stream listener terpasang
```

### B. Mulai Recording (tombol ditekan)
```
[LatihanService] 🎙️  Mulai listening...
[QuranSTT] 🎙️  Memulai listening...
[QuranSTT] ✅ Status set ke listening
[QuranSTT] 📡 Broadcasting status: listening=true, processing=false, arabicText=kosong
[QuranSTT] 🌍 Menggunakan locale: ar-SA (Arabic Saudi Arabia)
[QuranSTT] 🎧 Speech listener aktif (max 15s, pause 5s)
[LatihanService] ✅ Listening dimulai
[LatihanKataPage] 📨 Status update diterima:
  - isListening: true
  - isProcessing: false
  - arabicText: kosong
  - status: Mendengarkan... Bacalah ayat Al-Quran
[LatihanKataPage] 🎙️  Mulai animasi pulse
```

### C. Partial Results (saat mendengar)
```
[QuranSTT] 🎯 Hasil parsial: "bismillah" (final: false)
[QuranSTT] 📡 Broadcasting status: listening=true, processing=false, arabicText=kosong
[LatihanKataPage] 📨 Status update diterima:
  - isListening: true
  - isProcessing: false
  - arabicText: kosong
  - status: Mendengarkan: bismillah
```

### D. Stop Recording & Processing (tombol dilepas atau auto stop)
```
[QuranSTT] 📊 Status berubah: done
[QuranSTT] ⏹️  Berhenti mendengarkan
[QuranSTT] 📡 Broadcasting status: listening=false, processing=false, arabicText=kosong
[QuranSTT] 🔄 Memulai pemrosesan teks: "bismillah ar rahman ar rahim"
[QuranSTT] 🔍 Memproses teks yang dikenali...
[QuranSTT] 📡 Broadcasting status: listening=false, processing=true, arabicText=kosong
[QuranSTT] 📝 Teks yang akan dicari: "bismillah ar rahman ar rahim"
[QuranSTT] 🔎 Mencari ayat dengan fuzzy matching...
[QuranSTT] 🧹 Membersihkan teks input...
[QuranSTT] ✂️  Teks bersih: "bismillah ar rahman ar rahim"
[QuranSTT] 🎯 Mencoba exact match...
[QuranSTT] ❌ Exact match tidak ditemukan
[QuranSTT] 🔍 Mencoba fuzzy matching dengan kata kunci...
[QuranSTT] ✅ Fuzzy match ditemukan! Key: "al-fatihah", Match: 3/2 (150%)
[QuranSTT] ✅ Ayat ditemukan: Al-Fatihah ayat 1
[QuranSTT] 📖 Arab: بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ
[QuranSTT] 📡 Broadcasting status: listening=false, processing=false, arabicText=ada
[LatihanService] 📨 Menerima status dari QuranSTT: Al-Fatihah ayat 1 ditemukan!
[LatihanKataPage] 📨 Status update diterima:
  - isListening: false
  - isProcessing: false
  - arabicText: ada (42 karakter)
  - status: Al-Fatihah ayat 1 ditemukan!
[LatihanKataPage] ⏹️  Stop animasi pulse
```

### E. Tidak Ditemukan
```
[QuranSTT] 📝 Teks yang akan dicari: "xyz abc"
[QuranSTT] 🔎 Mencari ayat dengan fuzzy matching...
[QuranSTT] 🧹 Membersihkan teks input...
[QuranSTT] ✂️  Teks bersih: "xyz abc"
[QuranSTT] 🎯 Mencoba exact match...
[QuranSTT] ❌ Exact match tidak ditemukan
[QuranSTT] 🔍 Mencoba fuzzy matching dengan kata kunci...
[QuranSTT] ❌ Fuzzy matching dengan kata kunci tidak ditemukan
[QuranSTT] 🔍 Mencoba partial matching...
[QuranSTT] ❌ Partial matching tidak ditemukan
[QuranSTT] 💔 Tidak ada ayat yang cocok dengan: "xyz abc"
[QuranSTT] ❌ Ayat tidak ditemukan dalam database lokal
[QuranSTT] 📡 Broadcasting status: listening=false, processing=false, arabicText=kosong
```

## 🐛 Debugging Tips

### 1. **Loading Lama Setelah Recording**
Perhatikan log antara:
- `[QuranSTT] ⏹️  Berhenti mendengarkan` → Kapan stop dipanggil
- `[QuranSTT] 🔄 Memulai pemrosesan teks` → Kapan processing dimulai
- `[QuranSTT] ✅ Ayat ditemukan` → Kapan selesai

**Jika delay terjadi:**
- Antara "Berhenti mendengarkan" dan "Memulai pemrosesan" → Issue di Speech-to-Text engine
- Antara "Memulai pemrosesan" dan "Ayat ditemukan" → Issue di fuzzy matching algorithm

### 2. **Audio Tidak Terdeteksi**
Cek log:
```
[QuranSTT] ⚠️  Teks kosong, tidak ada yang diproses
```
- Pastikan microphone permission granted
- Pastikan locale ar-SA supported
- Cek noise/volume saat recording

### 3. **Ayat Tidak Ditemukan**
Lihat detail matching:
```
[QuranSTT] ✂️  Teks bersih: "..."
[QuranSTT] ❌ Exact match tidak ditemukan
[QuranSTT] ❌ Fuzzy matching tidak ditemukan
[QuranSTT] 💔 Tidak ada ayat yang cocok
```
- Teks recognition mungkin salah (ar-SA locale issue)
- Database lokal terbatas (perlu integrasi Supabase)

## 🔧 Cara Melihat Log

### Android Studio / VS Code:
1. Buka **Run** tab atau terminal
2. Gunakan filter: `[QuranSTT]`, `[LatihanService]`, atau `[LatihanKataPage]`
3. Untuk melihat semua log latihan kata, filter: `Latihan`

### Flutter DevTools:
1. Buka DevTools
2. Masuk ke **Logging** tab
3. Filter by tag

### Command Line:
```bash
flutter run | grep -E "\[QuranSTT\]|\[LatihanService\]|\[LatihanKataPage\]"
```

## 📈 Performance Metrics

Waktu normal setiap tahap:
- **Inisialisasi**: < 500ms
- **Start Listening**: < 100ms
- **Audio Recognition**: 0-15s (tergantung panjang audio)
- **Text Processing**: < 50ms
- **Fuzzy Matching**: < 10ms per verse (11 verses = ~110ms)
- **Total Processing**: < 200ms setelah audio selesai

Jika melebihi waktu normal, ada performance issue.

## 🎯 Next Steps

Untuk production:
1. Ganti `print()` dengan proper logging library (e.g., `logger` package)
2. Tambahkan log level (DEBUG, INFO, WARNING, ERROR)
3. Log ke file untuk analisis offline
4. Integrasikan dengan crash reporting (Firebase Crashlytics)
5. Tambahkan performance monitoring

## 📝 Notes

- Log ini untuk **development only**
- Hapus atau disable untuk production build
- Sensitive data tidak di-log (hanya metadata)
- Arabic text di-log untuk debugging recognition accuracy
