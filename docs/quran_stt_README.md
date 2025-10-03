# Quran Speech-to-Text Implementation

## 🎯 Quick Summary

**PENTING**: Model `gnb_model.tflite` yang Anda miliki adalah untuk **Voice Classification** (mengenali pembaca), BUKAN Speech-to-Text (konversi suara → teks).

### What Your Model Does
✅ Input: Audio → Output: "Ini suara Abdulbasit" (26 pembaca)

### What You Need for STT
❌ Input: Audio → Output: "بِسْمِ اللَّهِ" (text yang diucapkan)

## 📁 Files Modified/Created

### 1. `lib/services/quran_stt_service.dart` (NEW)
- Implementasi STT menggunakan Google Speech Recognition
- Locale Arab (ar-SA) untuk akurasi lebih baik
- Database ayat umum (11 ayat populer)
- Fuzzy matching algorithm
- Ready untuk integrasi Supabase

### 2. `lib/services/latihan_service.dart` (UPDATED)
- Sekarang delegate ke `QuranSTTService`
- Backward compatible dengan UI yang ada
- Simplified code

### 3. `docs/quran_stt_implementation.md` (NEW)
- Dokumentasi lengkap (baca ini!)
- Penjelasan konsep
- Cara implementasi
- Improvement suggestions

## 🚀 How It Works Now

```
User records → Google STT (ar-SA) → Fuzzy matching → Display Arabic text
```

**Features:**
- ✅ Recognizes 11 common Quran verses (Al-Fatihah, Al-Ikhlas, etc.)
- ✅ Arabic locale for better accuracy
- ✅ Fuzzy keyword matching
- ⚠️ TODO: Integrate with Supabase for full 6,236 verses

## 📝 Usage (Same as Before)

```dart
// No changes needed in UI!
final service = LatihanService();
await service.initialize();
await service.startListening(); // User speaks
await service.stopListening(); // Get result
```

## 🎓 Recognized Verses (Current)

1. Al-Fatihah (1-6)
2. Al-Ikhlas (1-3)
3. Al-Falaq (1)
4. An-Nas (1)

## 🔧 Next Steps

### Phase 1: Expand Database (Easy)
```dart
// Add more verses to _commonVerses in quran_stt_service.dart
```

### Phase 2: Supabase Integration (Medium)
```dart
// Connect to Supabase table with all verses
// Use full-text search
```

### Phase 3: Better STT Model (Hard)
```dart
// Use Whisper API or train custom model
// Requires GPU resources & dataset
```

## 💡 Using Your TFLite Model

Your model CAN be used for a **different feature**:

```dart
// "Identify which Qari (reciter) you sound like!"
class ReaderIdentifier {
  Future<String> identifyReader(audio) {
    // Extract MFCC → Run gnb_model.tflite → Return reader name
    return "You sound like Syekh Abdulbasit!";
  }
}
```

## 📚 Read Full Documentation

See `docs/quran_stt_implementation.md` for:
- Detailed explanation of Voice Classification vs STT
- Architecture diagrams
- Supabase schema
- Training custom STT model guide
- References & resources

## ✅ Testing

Test dengan ayat-ayat yang ada di database:
1. Baca "Bismillah" → Harus muncul: بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ
2. Baca "Alhamdulillah" → Harus muncul: الْحَمْدُ لِلَّهِ رَبِّ الْعَالَمِينَ
3. Baca "Qul Huwa" → Harus muncul: قُلْ هُوَ اللَّهُ أَحَدٌ

## 🐛 Known Issues

1. Akurasi tergantung Google STT (tidak spesifik Quran)
2. Hanya 11 ayat yang dikenali
3. Fuzzy matching bisa false positive
4. Perlu koneksi internet

## 🎯 Recommendation

Untuk production-ready:
1. Gunakan API seperti **Tarteel.ai** (spesialis Quran STT)
2. Atau fine-tune **Whisper model** untuk Arab
3. Atau kumpulkan dataset sendiri & train model

---

**Questions?** Baca dokumentasi lengkap di `docs/quran_stt_implementation.md`
