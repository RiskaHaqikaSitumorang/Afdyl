import 'package:flutter/services.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'dart:async';

class LatihanService {
  final SpeechToText _speechToText = SpeechToText();
  bool _speechEnabled = false;
  bool _isListening = false;
  bool _isProcessing = false;
  String _lastWords = '';
  String _arabicText = '';
  String _currentStatus = 'Tekan tombol untuk mulai merekam';

  final Map<String, String> _arabicMapping = {
    'bismillah': 'بِسْمِ اللَّهِ',
    'bismi': 'بِسْمِ',
    'allah': 'اللَّهِ',
    'alhamdulillah': 'الْحَمْدُ لِلَّهِ',
    'subhanallah': 'سُبْحَانَ اللَّهِ',
    'allahuakbar': 'اللَّهُ أَكْبَرُ',
    'allahu akbar': 'اللَّهُ أَكْبَرُ',
    'assalamu alaikum': 'السَّلَامُ عَلَيْكُمْ',
    'assalamualaikum': 'السَّلَامُ عَلَيْكُمْ',
    'wa alaikum salam': 'وَعَلَيْكُمُ السَّلَامُ',
    'inshallah': 'إِنْ شَاءَ اللَّهُ',
    'mashallah': 'مَا شَاءَ اللَّهُ',
    'astaghfirullah': 'أَسْتَغْفِرُ اللَّهَ',
    'la ilaha illa allah': 'لَا إِلَهَ إِلَّا اللَّهُ',
    'muhammad': 'مُحَمَّدٌ',
    'quran': 'قُرْآن',
    'islam': 'إِسْلَام',
    'muslim': 'مُسْلِم',
    'salam': 'سَلَام',
    'barakallahu': 'بَارَكَ اللَّهُ',
    'jazakallahu': 'جَزَاكَ اللَّهُ',
    'ramadan': 'رَمَضَان',
    'masjid': 'مَسْجِد',
    'salat': 'صَلَاة',
    'zakat': 'زَكَاة',
    'hajj': 'حَجّ',
    'umrah': 'عُمْرَة',
    'fajr': 'فَجْر',
    'dhuhr': 'ظُهْر',
    'asr': 'عَصْر',
    'maghrib': 'مَغْرِب',
    'isha': 'عِشَاء',
  };

  final _statusController = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get statusStream => _statusController.stream;

  Future<void> initialize() async {
    try {
      _speechEnabled = await _speechToText.initialize(
        onError: (error) {
          _isListening = false;
          _isProcessing = false;
          _currentStatus = 'Error: ${error.toString()}';
          _statusController.add({
            'status': _currentStatus,
            'isListening': _isListening,
            'isProcessing': _isProcessing,
            'arabicText': _arabicText,
          });
        },
        onStatus: (status) {
          if (status == 'done' || status == 'notListening') {
            _isListening = false;
            _statusController.add({
              'status': _currentStatus,
              'isListening': _isListening,
              'isProcessing': _isProcessing,
              'arabicText': _arabicText,
            });
            if (_lastWords.isNotEmpty) {
              _processRecognizedText();
            }
          }
        },
      );
      _currentStatus =
          _speechEnabled
              ? 'Tekan tombol untuk mulai merekam'
              : 'Speech recognition not available';
      _statusController.add({
        'status': _currentStatus,
        'isListening': _isListening,
        'isProcessing': _isProcessing,
        'arabicText': _arabicText,
      });
    } catch (e) {
      _currentStatus = 'Error initializing speech: $e';
      _statusController.add({
        'status': _currentStatus,
        'isListening': _isListening,
        'isProcessing': _isProcessing,
        'arabicText': _arabicText,
      });
    }
  }

  Future<void> startListening() async {
    if (!_speechEnabled) return;

    _isListening = true;
    _isProcessing = false;
    _lastWords = '';
    _arabicText = ''; // Kosongkan teks Arab saat mulai merekam
    _currentStatus = 'Mendengarkan... Silakan bicara';
    _statusController.add({
      'status': _currentStatus,
      'isListening': _isListening,
      'isProcessing': _isProcessing,
      'arabicText': _arabicText,
    });

    await _speechToText.listen(
      onResult: (result) {
        _lastWords = result.recognizedWords.toLowerCase();
        _findArabicTranslation(_lastWords);
        _statusController.add({
          'status': _currentStatus,
          'isListening': _isListening,
          'isProcessing': _isProcessing,
          'arabicText': _arabicText,
        });
      },
      listenFor: Duration(seconds: 10),
      pauseFor: Duration(seconds: 3),
      localeId: 'id_ID',
      cancelOnError: true,
      partialResults: true,
    );
  }

  Future<void> stopListening() async {
    _isListening = false;
    _isProcessing = true;
    _currentStatus = 'Memproses...';
    _statusController.add({
      'status': _currentStatus,
      'isListening': _isListening,
      'isProcessing': _isProcessing,
      'arabicText': _arabicText,
    });

    await _speechToText.stop();
  }

  void _processRecognizedText() {
    _isProcessing = true;
    _currentStatus = 'Memproses teks...';
    _statusController.add({
      'status': _currentStatus,
      'isListening': _isListening,
      'isProcessing': _isProcessing,
      'arabicText': _arabicText,
    });

    if (_lastWords.isEmpty) {
      _isProcessing = false;
      _currentStatus = 'Tidak ada suara terdeteksi. Coba lagi!';
      _arabicText = '';
      _statusController.add({
        'status': _currentStatus,
        'isListening': _isListening,
        'isProcessing': _isProcessing,
        'arabicText': _arabicText,
      });
      return;
    }

    _findArabicTranslation(_lastWords);
    HapticFeedback.mediumImpact();
    _isProcessing = false;
    _currentStatus =
        _arabicText.isNotEmpty
            ? 'Teks ditemukan! Tekan tombol untuk merekam lagi'
            : 'Teks tidak dikenali. Coba kata lain!';
    _statusController.add({
      'status': _currentStatus,
      'isListening': _isListening,
      'isProcessing': _isProcessing,
      'arabicText': _arabicText,
    });
  }

  void _findArabicTranslation(String text) {
    String cleanText = text.trim().toLowerCase();
    String foundArabic = '';

    if (_arabicMapping.containsKey(cleanText)) {
      foundArabic = _arabicMapping[cleanText]!;
    } else {
      for (String key in _arabicMapping.keys) {
        if (cleanText.contains(key) || key.contains(cleanText)) {
          foundArabic = _arabicMapping[key]!;
          break;
        }
      }
    }

    _arabicText = foundArabic;
  }

  void dispose() {
    _speechToText.stop();
    _statusController.close();
  }
}
