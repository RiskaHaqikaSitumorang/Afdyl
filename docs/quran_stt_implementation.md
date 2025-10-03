# Implementasi Speech-to-Text untuk Al-Quran

## Penjelasan Konsep & Implementasi

### 1. Tentang Model TFLite (`gnb_model.tflite`)

**Model Anda adalah untuk KLASIFIKASI PEMBACA, bukan Speech-to-Text!**

Model yang Anda latih di notebook `holy-quran-reader-classification-92-using-ml.ipynb` adalah:
- **Tujuan**: Mengklasifikasikan 26 pembaca Quran yang berbeda
- **Input**: MFCC features dari audio
- **Output**: Prediksi SIAPA yang membaca (Abdulsamad, Husary, Sudais, dll)
- **BUKAN**: Konversi audio → teks Arab (Speech-to-Text)

Analogi:
- Model Anda: "Ini suara Abdulbasit" ✅
- Model STT: "Yang dibaca adalah: بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ" ❌ (tidak bisa)

### 2. Perbedaan Voice Classification vs Speech-to-Text

| Aspek | Voice Classification (Model Anda) | Speech-to-Text (Dibutuhkan) |
|-------|-----------------------------------|----------------------------|
| **Input** | Audio file | Audio file |
| **Features** | MFCC (voice characteristics) | MFCC + Spectogram + LM |
| **Output** | Label pembaca (26 classes) | Teks yang diucapkan |
| **Model** | Gaussian Naive Bayes | Wav2Vec2, Whisper, RNN-T |
| **Training Data** | 26 pembaca × audio samples | Ribuan jam audio + transcript |
| **Kompleksitas** | Relatif sederhana | Sangat kompleks |

### 3. Solusi yang Diimplementasikan

Karena membuat model STT Quran dari nol sangat kompleks, saya implementasikan **Hybrid Approach**:

#### a. **Speech Recognition dengan Google STT**
- Gunakan `speech_to_text` package (sudah ada)
- Set locale ke Arab: `ar-SA` (Saudi Arabia)
- Kenali kata-kata yang diucapkan

#### b. **Fuzzy Matching dengan Database Ayat**
- Simpan ayat-ayat umum dalam memory (Al-Fatihah, Al-Ikhlas, dll)
- Cocokkan hasil STT dengan database ayat menggunakan keyword matching
- Return ayat Arab yang sesuai

#### c. **Integrasi Supabase (TODO)**
- Query database Quran di Supabase
- Gunakan full-text search atau similarity search
- Skalabel untuk 6,236 ayat

### 4. Arsitektur Sistem

```
┌─────────────────┐
│  User Records   │
│  Quran Recit.   │
└────────┬────────┘
         │
         ▼
┌─────────────────────────────┐
│  Google Speech-to-Text      │
│  (locale: ar-SA)            │
└────────┬────────────────────┘
         │
         ▼ (recognized keywords)
┌─────────────────────────────┐
│  Fuzzy Matching Engine      │
│  - Common verses (in-memory)│
│  - Supabase full-text search│
└────────┬────────────────────┘
         │
         ▼ (matched verse)
┌─────────────────────────────┐
│  Display Arabic Text        │
│  + Translation + Reference  │
└─────────────────────────────┘
```

### 5. File yang Dibuat/Dimodifikasi

#### a. `lib/services/quran_stt_service.dart` (BARU)
Service baru dengan implementasi lengkap:
- Speech recognition dengan locale Arab
- Database ayat umum (in-memory)
- Fuzzy matching algorithm
- TODO: Integrasi Supabase

#### b. `lib/services/latihan_service.dart` (DIUPDATE)
Diubah menjadi wrapper/delegate ke `QuranSTTService`:
- Backward compatibility
- Forward stream events
- Simplified interface

### 6. Cara Kerja Implementasi

```dart
// 1. User mulai rekam
await quranSTT.startListening();

// 2. Google STT mendengarkan dengan locale Arab
_speechToText.listen(
  localeId: 'ar-SA', // Arabic (Saudi Arabia)
  listenFor: Duration(seconds: 15), // Ayat bisa panjang
);

// 3. Hasil speech dicocokkan dengan database
_findMatchingVerse(recognizedText);

// 4. Fuzzy matching dengan keyword scoring
for (verse in commonVerses) {
  if (matchScore > threshold) {
    return verse; // Return ayat yang cocok
  }
}

// 5. Tampilkan hasil ke UI
setState(() {
  _arabicText = matchedVerse['arabic'];
});
```

### 7. Limitasi & Improvement

#### Limitasi Saat Ini:
1. **Hanya 11 ayat umum** di database in-memory
2. **Akurasi tergantung Google STT** - tidak spesifik untuk Quran
3. **Fuzzy matching sederhana** - bisa false positive/negative
4. **Belum terintegrasi dengan Supabase** - perlu database lengkap

#### Improvement yang Bisa Dilakukan:

##### A. **Jangka Pendek** (Tanpa ML Training)
```dart
// 1. Tambah lebih banyak ayat ke database
// 2. Gunakan Levenshtein distance untuk fuzzy matching
import 'package:string_similarity/string_similarity.dart';

double similarity = recognizedText.similarityTo(verseKeywords);

// 3. Integrasikan dengan Supabase
final response = await supabase
  .from('quran_verses')
  .select()
  .textSearch('transliteration', recognizedText);
```

##### B. **Jangka Menengah** (Pakai Model Pre-trained)
```dart
// Gunakan Whisper model (OpenAI) yang sudah fine-tuned untuk Arab
import 'package:whisper_flutter/whisper_flutter.dart';

final whisper = Whisper();
await whisper.loadModel('whisper-large-v2-arabic');
final result = await whisper.transcribe(audioPath);
```

##### C. **Jangka Panjang** (Training Model Sendiri)
- Kumpulkan dataset: Audio + Transcript ayat Quran
- Fine-tune Wav2Vec2 atau Whisper untuk bahasa Arab Quran
- Deploy sebagai API atau edge model (TFLite)
- Estimasi: 3-6 bulan + GPU resources

### 8. Penggunaan Model `gnb_model.tflite` yang Ada

Jika tetap ingin pakai model Anda, bisa untuk **fitur tambahan**:

```dart
// Contoh: Identifikasi pembaca saat user merekam
class QuranReaderClassifier {
  Future<String> identifyReader(String audioPath) async {
    // 1. Extract MFCC features
    final mfcc = await extractMFCC(audioPath);
    
    // 2. Load TFLite model
    final interpreter = await Interpreter.fromAsset('assets/models/gnb_model.tflite');
    
    // 3. Run inference
    final output = interpreter.run(mfcc);
    
    // 4. Decode hasil
    final readerName = decodeReader(output); // e.g., "Abdulbasit"
    
    return readerName;
  }
}
```

**Use Case:**
- "Anda membaca seperti Syekh Abdulbasit!" (gamifikasi)
- Analisis similarity voice (untuk evaluasi tajwid)
- Rekomendasi pembaca berdasarkan preferensi user

### 9. Integrasi dengan Supabase (TODO)

```sql
-- Schema untuk full-text search
CREATE TABLE quran_verses (
  id SERIAL PRIMARY KEY,
  surah_number INT,
  ayah_number INT,
  arabic_text TEXT,
  transliteration TEXT,
  translation TEXT,
  keywords TEXT[], -- Array of keywords
  search_vector tsvector -- For full-text search
);

-- Create index untuk performance
CREATE INDEX quran_search_idx ON quran_verses USING GIN(search_vector);

-- Function untuk search
CREATE FUNCTION search_quran_verse(query TEXT)
RETURNS TABLE(...) AS $$
  SELECT *
  FROM quran_verses
  WHERE search_vector @@ to_tsquery('arabic', query)
  ORDER BY ts_rank(search_vector, to_tsquery('arabic', query)) DESC
  LIMIT 5;
$$ LANGUAGE sql;
```

```dart
// Di Flutter
class SupabaseQuranSearch {
  Future<List<Verse>> searchVerse(String query) async {
    final response = await supabase
      .rpc('search_quran_verse', params: {'query': query});
    
    return (response as List)
      .map((json) => Verse.fromJson(json))
      .toList();
  }
}
```

### 10. Testing & Validation

```dart
// Test cases
void testQuranSTT() {
  test('Should recognize Al-Fatihah verse 1', () async {
    // Simulate recognized text
    final result = service.findMatchingVerse('bismillah rahman rahim');
    
    expect(result['surah'], 'Al-Fatihah');
    expect(result['ayah'], 1);
  });
  
  test('Should handle unrecognized verse', () async {
    final result = service.findMatchingVerse('unknown text');
    
    expect(result, null);
  });
}
```

### 11. Kesimpulan

**Model TFLite Anda:**
- ✅ Bagus untuk voice classification
- ❌ Tidak bisa untuk Speech-to-Text
- ✅ Bisa dipakai untuk fitur tambahan (identifikasi pembaca)

**Implementasi Saat Ini:**
- ✅ Menggunakan Google STT (locale Arab)
- ✅ Fuzzy matching dengan database in-memory
- ⚠️ Perlu integrasi Supabase untuk skalabilitas
- ⚠️ Perlu fine-tuning untuk akurasi lebih baik

**Rekomendasi:**
1. **Gunakan implementasi hybrid ini** untuk MVP/demo
2. **Kumpulkan feedback user** tentang akurasi
3. **Integrasikan dengan Supabase** untuk database lengkap
4. **Pertimbangkan Whisper API** untuk akurasi lebih baik
5. **Training model sendiri** jika punya resources & dataset

---

## Resources & References

- [Whisper by OpenAI](https://github.com/openai/whisper) - State-of-the-art STT
- [Wav2Vec2 Arabic](https://huggingface.co/models?search=wav2vec2-arabic) - Pre-trained Arab models
- [Tarteel.ai](https://tarteel.ai/) - Quran STT specialized
- [Mozilla Common Voice Arabic](https://commonvoice.mozilla.org/ar) - Open dataset
- [Google Cloud Speech-to-Text](https://cloud.google.com/speech-to-text/docs/languages) - Arabic support

**Contact**: Jika perlu bantuan training model STT custom, silakan hubungi!
