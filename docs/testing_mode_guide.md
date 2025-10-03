# 🧪 Testing Mode - Speech Recognition

## 🎯 Apa yang Berubah?

Fitur pencarian ayat **DINONAKTIFKAN SEMENTARA** untuk testing. Sekarang aplikasi akan:

✅ **Langsung menampilkan teks yang didengar** oleh microphone
✅ **Tidak mencari di database ayat** (lebih cepat untuk testing)
✅ **Menampilkan label "MODE TESTING"** di UI

## 📋 Cara Testing:

### 1. Jalankan Aplikasi
```bash
flutter run
```

### 2. Buka Terminal Baru untuk Monitoring Log
```bash
adb logcat | grep -i "flutter\|QuranSTT\|LatihanKataPage"
```

### 3. Navigasi ke Halaman Latihan Kata

Di app, masuk ke menu **Latihan Kata**

### 4. Test Recording

1. **Tekan tombol microphone** (bulat kuning)
2. **Ucapkan sesuatu** (bisa bahasa apapun untuk testing)
   - Contoh: "Hello world"
   - Contoh: "Bismillah"
   - Contoh: "Testing satu dua tiga"
3. **Tekan tombol stop** (kotak putih)
4. **Tunggu processing**
5. **Lihat hasil** - Akan muncul teks yang terdeteksi

## 📊 Yang Akan Muncul:

### Di UI:
```
┌─────────────────────────┐
│ 🔬 MODE TESTING         │
├─────────────────────────┤
│ Audio Terdeteksi:       │
│                         │
│  [TEKS YANG DIUCAPKAN]  │
│                         │
└─────────────────────────┘
```

### Di Log (Terminal):
```
[QuranSTT] 🎙️  Memulai listening...
[QuranSTT] 🎯 Hasil parsial: "hello" (final: false)
[QuranSTT] 🎯 Hasil parsial: "hello world" (final: false)
[QuranSTT] 📊 Status berubah: done
[QuranSTT] 🔍 Memproses teks yang dikenali...
[QuranSTT] 📝 Teks yang didengar: "hello world"
[QuranSTT] 🎯 Mode Testing: Menampilkan teks yang didengar
[QuranSTT] ✅ Selesai memproses
[QuranSTT] 📡 Broadcasting status: listening=false, processing=false, arabicText=ada
```

## 🔍 Apa yang Bisa Dites?

### ✅ Test Basic:
1. **Microphone berfungsi?** - Lihat apakah tombol berubah warna saat ditekan
2. **Audio terdeteksi?** - Lihat apakah ada hasil parsial di log
3. **Teks muncul?** - Lihat apakah teks yang diucapkan muncul di UI

### ✅ Test Bahasa:
1. **Bahasa Indonesia** - Ucapkan kata bahasa Indonesia
2. **Bahasa Inggris** - Ucapkan kata bahasa Inggris
3. **Bahasa Arab** - Ucapkan kata bahasa Arab (jika locale support)

### ✅ Test Kecepatan:
1. **Berapa lama dari tap stop sampai muncul hasil?**
   - Lihat timestamp di log
   - Normal: < 1 detik

### ✅ Test Edge Cases:
1. **Tidak ada suara** - Apa yang terjadi jika diam saja?
2. **Suara sangat pelan** - Apakah tetap terdeteksi?
3. **Suara sangat keras** - Apakah tetap jelas?
4. **Background noise** - Apakah mengganggu?

## 🐛 Troubleshooting:

### Tidak Ada Log yang Muncul?
```bash
# Cek apakah device terhubung
adb devices

# Clear logcat dan coba lagi
adb logcat -c
adb logcat | grep -i "flutter"
```

### Audio Tidak Terdeteksi?
1. **Cek permission** - Pastikan microphone permission granted
2. **Cek locale** - App menggunakan `ar-SA` (Arabic), mungkin tidak support semua device
3. **Coba locale lain** - Edit `quran_stt_service.dart`, ganti `ar-SA` dengan:
   - `id-ID` untuk Bahasa Indonesia
   - `en-US` untuk English
   - `ar-SA` untuk Arabic

### Hasil Tidak Akurat?
**NORMAL!** Ini hanya testing. Akurasi akan lebih baik jika:
- Locale sesuai dengan bahasa yang diucapkan
- Tidak ada background noise
- Suara jelas dan tidak terlalu cepat

## 🔄 Cara Mengembalikan Mode Normal (Dengan Pencarian Ayat):

Edit file `lib/services/quran_stt_service.dart`:

1. **Uncomment** bagian pencarian ayat (ada comment `/* ... */`)
2. **Comment** atau **hapus** bagian testing:
   ```dart
   // _arabicText = _recognizedText; // Hapus ini
   // _currentStatus = 'Audio terdeteksi: $_recognizedText'; // Hapus ini
   ```

## 📝 Expected Behavior:

### ✅ Flow Normal:
```
1. Tap button → Mulai recording (button jadi merah)
2. Ucapkan sesuatu → Muncul partial result di log
3. Tap stop → Processing (muncul loading)
4. Hasil muncul → Teks terdeteksi ditampilkan
```

### ⏱️ Timing:
- **Start recording**: Instant (< 100ms)
- **Partial results**: Real-time saat bicara
- **Stop → Processing**: < 500ms
- **Total**: < 1 detik dari stop sampai hasil muncul

### 📊 Status Changes:
```
isListening=false, isProcessing=false → Idle
isListening=true, isProcessing=false → Recording
isListening=false, isProcessing=true → Processing
isListening=false, isProcessing=false → Result shown
```

## 🎓 Tips Testing:

1. **Ucapkan dengan jelas** - Artikulasi yang baik
2. **Tidak terlalu cepat** - Beri jeda antar kata
3. **Hindari noise** - Testing di tempat yang tenang
4. **Test berbagai kata** - Panjang pendek, mudah sulit
5. **Lihat log** - Log sangat membantu untuk debugging

## 📸 Screenshot Expected:

Saat hasil muncul, Anda akan lihat:
- Badge orange "🔬 MODE TESTING" di atas
- Box putih dengan teks "Audio Terdeteksi:"
- Teks yang Anda ucapkan ditampilkan dengan font besar dan bold

## ✅ Checklist Testing:

- [ ] App berhasil compile dan run
- [ ] Bisa masuk ke halaman Latihan Kata
- [ ] Tombol microphone bisa di-tap
- [ ] Warna button berubah saat recording
- [ ] Ada log di terminal/logcat
- [ ] Hasil muncul di UI setelah stop
- [ ] Badge "MODE TESTING" terlihat
- [ ] Teks yang diucapkan sesuai dengan yang ditampilkan

## 🚀 Next Steps:

Setelah testing berhasil:
1. ✅ Confirm audio recording works
2. ✅ Confirm speech recognition works
3. ✅ Adjust locale if needed (ar-SA, id-ID, or en-US)
4. ✅ Enable ayat matching feature
5. ✅ Test dengan ayat Quran sesungguhnya
6. ✅ Integration dengan Supabase database

---

**Note:** File yang diubah:
- `lib/services/quran_stt_service.dart` - Logic diubah ke testing mode
- `lib/screens/latihan_kata_page.dart` - UI ditambah badge testing
