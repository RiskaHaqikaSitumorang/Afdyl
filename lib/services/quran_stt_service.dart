import 'package:flutter/services.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

/// Service untuk mengenali bacaan Al-Quran dari rekaman suara
///
/// CATATAN IMPLEMENTASI:
/// Model gnb_model.tflite yang ada adalah untuk KLASIFIKASI PEMBACA (voice classification),
/// bukan Speech-to-Text. Model tersebut mengidentifikasi SIAPA yang membaca (26 pembaca Quran),
/// bukan APA yang dibaca.
///
/// Untuk implementasi STT Quran yang sesungguhnya, ada beberapa pendekatan:
/// 1. Gunakan Google Cloud Speech-to-Text API dengan bahasa Arab
/// 2. Gunakan model Wav2Vec2 atau Whisper fine-tuned untuk Quran
/// 3. Gunakan layanan seperti Tarteel.ai yang khusus untuk Quran
///
/// Implementasi ini menggunakan pendekatan hybrid:
/// - Speech-to-Text untuk mengenali kata-kata Arab
/// - Fuzzy matching dengan database ayat Quran untuk menemukan ayat yang sesuai
class QuranSTTService {
  final SpeechToText _speechToText = SpeechToText();
  bool _speechEnabled = false;
  bool _isListening = false;
  bool _isProcessing = false;
  String _recognizedText = '';
  String _arabicText = '';
  String _currentStatus = 'Tekan tombol untuk mulai merekam';

  // Database ayat Quran yang sering dibaca (untuk demo)
  // TODO: Integrasikan dengan Supabase untuk database lengkap
  final Map<String, Map<String, dynamic>> _commonVerses = {
    'al-fatihah': {
      'arabic': 'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
      'translation': 'Dengan nama Allah Yang Maha Pengasih, Maha Penyayang',
      'surah': 'Al-Fatihah',
      'ayah': 1,
    },
    'alhamdulillah': {
      'arabic': 'الْحَمْدُ لِلَّهِ رَبِّ الْعَالَمِينَ',
      'translation': 'Segala puji bagi Allah, Tuhan seluruh alam',
      'surah': 'Al-Fatihah',
      'ayah': 2,
    },
    'rahman rahim': {
      'arabic': 'الرَّحْمَٰنِ الرَّحِيمِ',
      'translation': 'Yang Maha Pengasih, Maha Penyayang',
      'surah': 'Al-Fatihah',
      'ayah': 3,
    },
    'malik yaumiddin': {
      'arabic': 'مَالِكِ يَوْمِ الدِّينِ',
      'translation': 'Pemilik hari pembalasan',
      'surah': 'Al-Fatihah',
      'ayah': 4,
    },
    'iyyaka nabudu': {
      'arabic': 'إِيَّاكَ نَعْبُدُ وَإِيَّاكَ نَسْتَعِينُ',
      'translation':
          'Hanya kepada-Mu kami menyembah dan hanya kepada-Mu kami memohon pertolongan',
      'surah': 'Al-Fatihah',
      'ayah': 5,
    },
    'ihdina': {
      'arabic': 'اهْدِنَا الصِّرَاطَ الْمُسْتَقِيمَ',
      'translation': 'Tunjukilah kami jalan yang lurus',
      'surah': 'Al-Fatihah',
      'ayah': 6,
    },
    'qul huwa': {
      'arabic': 'قُلْ هُوَ اللَّهُ أَحَدٌ',
      'translation': 'Katakanlah (Muhammad), "Dialah Allah Yang Maha Esa',
      'surah': 'Al-Ikhlas',
      'ayah': 1,
    },
    'allahu samad': {
      'arabic': 'اللَّهُ الصَّمَدُ',
      'translation': 'Allah tempat meminta segala sesuatu',
      'surah': 'Al-Ikhlas',
      'ayah': 2,
    },
    'lam yalid': {
      'arabic': 'لَمْ يَلِدْ وَلَمْ يُولَدْ',
      'translation': 'Dia tidak beranak dan tidak pula diperanakkan',
      'surah': 'Al-Ikhlas',
      'ayah': 3,
    },
    'qul auzu': {
      'arabic': 'قُلْ أَعُوذُ بِرَبِّ الْفَلَقِ',
      'translation':
          'Katakanlah, "Aku berlindung kepada Tuhan yang menguasai subuh',
      'surah': 'Al-Falaq',
      'ayah': 1,
    },
    'rabbi nas': {
      'arabic': 'قُلْ أَعُوذُ بِرَبِّ النَّاسِ',
      'translation': 'Katakanlah, "Aku berlindung kepada Tuhan manusia',
      'surah': 'An-Nas',
      'ayah': 1,
    },
  };

  final _statusController = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get statusStream => _statusController.stream;

  Future<void> initialize() async {
    print('[QuranSTT] 🚀 Memulai inisialisasi...');
    try {
      print('[QuranSTT] 🎤 Menginisialisasi Speech-to-Text...');
      _speechEnabled = await _speechToText.initialize(
        onError: (error) {
          print('[QuranSTT] ❌ Error: ${error.toString()}');

          // Handle specific errors dengan pesan yang lebih jelas
          if (error.errorMsg.contains('timeout') ||
              error.errorMsg.contains('speech_timeout')) {
            print('[QuranSTT] ⏱️  TIMEOUT: Tidak ada suara terdeteksi');
            _currentStatus = 'Timeout: Tidak ada suara terdeteksi. Coba lagi!';
          } else if (error.errorMsg.contains('no-speech') ||
              error.errorMsg.contains('no_speech')) {
            print('[QuranSTT] 🔇 NO SPEECH: Tidak ada suara terdeteksi');
            _currentStatus =
                'Tidak ada suara terdeteksi. Pastikan microphone aktif!';
          } else {
            _currentStatus = 'Error: ${error.errorMsg}';
          }

          _isListening = false;
          _isProcessing = false;
          _broadcastStatus();
        },
        onStatus: (status) {
          print('[QuranSTT] 📊 Status berubah: $status');
          if (status == 'done' || status == 'notListening') {
            print('[QuranSTT] ⏹️  Berhenti mendengarkan');
            _isListening = false;
            _broadcastStatus();
            if (_recognizedText.isNotEmpty) {
              print(
                '[QuranSTT] 🔄 Memulai pemrosesan teks: "$_recognizedText"',
              );
              _processRecognizedText();
            } else {
              print('[QuranSTT] ⚠️  Tidak ada teks yang dikenali');
              _currentStatus = 'Tidak ada suara terdeteksi';
              _broadcastStatus();
            }
          }
        },
      );
      _currentStatus =
          _speechEnabled
              ? 'Tekan tombol untuk mulai merekam'
              : 'Speech recognition tidak tersedia';
      print(
        '[QuranSTT] ✅ Inisialisasi selesai. Speech enabled: $_speechEnabled',
      );
      _broadcastStatus();
    } catch (e) {
      print('[QuranSTT] ❌ Error saat inisialisasi: $e');
      _currentStatus = 'Error initializing speech: $e';
      _broadcastStatus();
    }
  }

  Future<void> startListening() async {
    print('[QuranSTT] 🎙️  Memulai listening...');
    if (!_speechEnabled) {
      print('[QuranSTT] ⚠️  Speech tidak diaktifkan, batalkan listening');
      return;
    }

    _isListening = true;
    _isProcessing = false;
    _recognizedText = '';
    _arabicText = '';
    _currentStatus = 'Mendengarkan... Bacalah ayat Al-Quran';
    print('[QuranSTT] ✅ Status set ke listening');
    _broadcastStatus();

    // Gunakan locale Arab untuk pengenalan yang lebih baik
    print('[QuranSTT] 🌍 Menggunakan locale: ar-SA (Arabic Saudi Arabia)');
    await _speechToText.listen(
      onResult: (result) {
        // IMPORTANT: Hanya update jika masih listening
        // Hindari race condition dimana partial result datang setelah processing selesai
        if (!_isListening) {
          print(
            '[QuranSTT] ⚠️  Hasil parsial diabaikan (sudah tidak listening)',
          );
          return;
        }

        _recognizedText = result.recognizedWords.toLowerCase();
        print(
          '[QuranSTT] 🎯 Hasil parsial: "$_recognizedText" (final: ${result.finalResult})',
        );
        _currentStatus = 'Mendengarkan: $_recognizedText';
        _broadcastStatus();
      },
      listenFor: Duration(seconds: 30), // Increased: Beri waktu lebih lama
      pauseFor: Duration(
        seconds: 10,
      ), // Increased: Tunggu lebih lama sebelum stop
      // Gunakan locale Arab jika tersedia, fallback ke Indonesia
      localeId: 'ar-SA', // Arabic (Saudi Arabia) untuk Quran
      onSoundLevelChange: (level) {
        // Log sound level untuk debugging
        if (level > 0) {
          print('[QuranSTT] 🔊 Sound level: ${level.toStringAsFixed(1)}');
        }
      },
      cancelOnError: false, // Jangan langsung cancel saat error
      partialResults: true,
      listenMode: ListenMode.confirmation, // Lebih baik untuk frase pendek
    );
    print('[QuranSTT] 🎧 Speech listener aktif (max 30s, pause 10s)');
  }

  Future<void> stopListening() async {
    print('[QuranSTT] 🛑 Menghentikan listening...');
    _isListening = false;
    _isProcessing = true;
    _currentStatus = 'Memproses ayat...';
    print('[QuranSTT] ⏳ Set status ke processing');
    _broadcastStatus();

    await _speechToText.stop();
    print('[QuranSTT] ⏹️  Berhenti mendengarkan');

    // Process recognized text setelah listening dihentikan
    print('[QuranSTT] ➡️  Memanggil _processRecognizedText()...');
    _processRecognizedText();
  }

  void _processRecognizedText() async {
    print('[QuranSTT] 🔍 Memproses teks yang dikenali...');
    _isProcessing = true;
    _currentStatus = 'Memproses hasil recording...';
    _broadcastStatus();

    if (_recognizedText.isEmpty) {
      print('[QuranSTT] ⚠️  Teks kosong, tidak ada yang diproses');
      _isProcessing = false;
      _currentStatus = 'Tidak ada suara terdeteksi. Coba lagi!';
      _arabicText = '';
      _broadcastStatus();
      return;
    }

    print('[QuranSTT] 📝 Teks yang didengar: "$_recognizedText"');

    // TESTING MODE: Langsung tampilkan apa yang didengar
    // Tanpa pencarian ayat
    print('[QuranSTT] 🎯 Mode Testing: Menampilkan teks yang didengar');

    // Konversi teks ke Arab dengan harakat menggunakan API
    print('[QuranSTT] 🔄 Memanggil API Tashkeel untuk menambahkan harakat...');
    final arabicWithHarakat = await _convertToArabicWithHarakat(
      _recognizedText,
    );
    _arabicText = arabicWithHarakat;
    _currentStatus = 'Audio terdeteksi: $_recognizedText';
    print('[QuranSTT] ✏️  _arabicText di-set ke: "$_arabicText"');
    print('[QuranSTT] ✏️  _currentStatus di-set ke: "$_currentStatus"');
    HapticFeedback.lightImpact();

    print('[QuranSTT] ✅ Selesai memproses');

    // COMMENTED OUT: Pencarian ayat (untuk testing nanti)
    /*
    // Cari ayat yang cocok menggunakan fuzzy matching
    print('[QuranSTT] 🔎 Mencari ayat dengan fuzzy matching...');
    final matchedVerse = _findMatchingVerse(_recognizedText);

    if (matchedVerse != null) {
      print(
        '[QuranSTT] ✅ Ayat ditemukan: ${matchedVerse['surah']} ayat ${matchedVerse['ayah']}',
      );
      print('[QuranSTT] 📖 Arab: ${matchedVerse['arabic']}');
      _arabicText = matchedVerse['arabic'];
      _currentStatus =
          '${matchedVerse['surah']} ayat ${matchedVerse['ayah']} ditemukan!';
      HapticFeedback.mediumImpact();
    } else {
      // Jika tidak ditemukan di common verses, coba query ke Supabase
      // TODO: Implementasi pencarian ke Supabase
      print('[QuranSTT] ❌ Ayat tidak ditemukan dalam database lokal');
      _arabicText = '';
      _currentStatus =
          'Ayat tidak dikenali. Coba bacaan yang lebih jelas atau ayat lain.';
    }
    */

    _isProcessing = false;
    print(
      '[QuranSTT] 🏁 Set isProcessing = false, akan broadcast status final...',
    );
    _broadcastStatus();
    print('[QuranSTT] 📤 Status final telah di-broadcast!');
  }

  /// Konversi teks ke Arab dengan harakat menggunakan Tashkeel API
  Future<String> _convertToArabicWithHarakat(String text) async {
    print('[QuranSTT] 🔤 Mengkonversi ke Arab dengan harakat: "$text"');
    print('[QuranSTT] 🌐 Memanggil Tashkeel API...');

    try {
      final url = Uri.parse('https://afdyl-api.vercel.app/api/tashkeel');

      print('[QuranSTT] 📤 Mengirim request ke: $url');
      print('[QuranSTT] 📝 Body: {"text": "$text"}');

      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: json.encode({'text': text}),
          )
          .timeout(
            Duration(seconds: 10),
            onTimeout: () {
              print('[QuranSTT] ⏱️  Request timeout setelah 10 detik');
              throw TimeoutException('API request timeout');
            },
          );

      print('[QuranSTT] 📥 Response status: ${response.statusCode}');
      print('[QuranSTT] 📥 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['success'] == true && data['vocalized_text'] != null) {
          final vocalizedText = data['vocalized_text'] as String;
          print('[QuranSTT] ✅ Berhasil! Vocalized text: "$vocalizedText"');
          print('[QuranSTT] 📊 Length: ${data['length']} characters');
          return vocalizedText;
        } else {
          print('[QuranSTT] ⚠️  API response success=false');
          return '($text)'; // Fallback: tampilkan teks asli dalam kurung
        }
      } else {
        print('[QuranSTT] ❌ API error: Status ${response.statusCode}');
        return '($text)'; // Fallback: tampilkan teks asli dalam kurung
      }
    } catch (e) {
      print('[QuranSTT] ❌ Error saat memanggil Tashkeel API: $e');
      return '($text)'; // Fallback: tampilkan teks asli dalam kurung
    }
  }

  Map<String, dynamic>? _findMatchingVerse(String text) {
    print('[QuranSTT] 🧹 Membersihkan teks input...');
    String cleanText = text.trim().toLowerCase();
    print('[QuranSTT] ✂️  Teks bersih: "$cleanText"');

    // Exact match
    print('[QuranSTT] 🎯 Mencoba exact match...');
    if (_commonVerses.containsKey(cleanText)) {
      print('[QuranSTT] ✅ Exact match ditemukan!');
      return _commonVerses[cleanText]!;
    }
    print('[QuranSTT] ❌ Exact match tidak ditemukan');

    // Fuzzy matching - cari kata kunci
    print('[QuranSTT] 🔍 Mencoba fuzzy matching dengan kata kunci...');
    for (String key in _commonVerses.keys) {
      // Split dan cek setiap kata
      List<String> keywords = key.split(' ');
      int matchCount = 0;

      for (String keyword in keywords) {
        if (cleanText.contains(keyword) || keyword.contains(cleanText)) {
          matchCount++;
        }
      }

      // Jika > 50% kata cocok, anggap sebagai match
      double matchPercentage = matchCount / keywords.length;
      if (matchCount > keywords.length / 2) {
        print(
          '[QuranSTT] ✅ Fuzzy match ditemukan! Key: "$key", Match: $matchCount/${keywords.length} (${(matchPercentage * 100).toStringAsFixed(0)}%)',
        );
        return _commonVerses[key]!;
      }
    }
    print('[QuranSTT] ❌ Fuzzy matching dengan kata kunci tidak ditemukan');

    // Coba matching parsial
    print('[QuranSTT] 🔍 Mencoba partial matching...');
    for (String key in _commonVerses.keys) {
      if (cleanText.contains(key) || key.contains(cleanText)) {
        print('[QuranSTT] ✅ Partial match ditemukan! Key: "$key"');
        return _commonVerses[key]!;
      }
    }
    print('[QuranSTT] ❌ Partial matching tidak ditemukan');

    print('[QuranSTT] 💔 Tidak ada ayat yang cocok dengan: "$cleanText"');
    return null;
  }

  /// Query ke Supabase untuk mencari ayat berdasarkan teks yang dikenali
  /// TODO: Implementasi ini ketika database Supabase sudah siap
  ///
  /// Uncomment kode di bawah ketika siap digunakan:
  ///
  /// ```dart
  /// Future<Map<String, dynamic>?> _querySupabaseForVerse(String text) async {
  ///   // Implementasi pencarian ke Supabase
  ///   // Bisa menggunakan full-text search atau similarity search
  ///   final response = await supabase
  ///     .from('quran_verses')
  ///     .select()
  ///     .textSearch('transliteration', text)
  ///     .limit(1)
  ///     .single();
  ///   return response;
  /// }
  /// ```

  void _broadcastStatus() {
    final status = {
      'status': _currentStatus,
      'isListening': _isListening,
      'isProcessing': _isProcessing,
      'arabicText': _arabicText,
      'recognizedText': _recognizedText,
    };
    print(
      '[QuranSTT] 📡 Broadcasting status: listening=$_isListening, processing=$_isProcessing, arabicText=${_arabicText.isEmpty ? "kosong" : "ada"}',
    );
    _statusController.add(status);
  }

  void dispose() {
    print('[QuranSTT] 🔚 Disposing service...');
    _speechToText.stop();
    _statusController.close();
    print('[QuranSTT] ✅ Service disposed');
  }
}
