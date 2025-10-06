import 'package:flutter_tts/flutter_tts.dart';

/// Service untuk Text-to-Speech khusus teks Arab
class ArabicTTSService {
  final FlutterTts _flutterTts = FlutterTts();
  bool _isInitialized = false;
  bool _isSpeaking = false;

  bool get isSpeaking => _isSpeaking;

  /// Initialize TTS with Arabic language settings
  Future<void> initialize() async {
    try {
      print('[ArabicTTS] 🚀 Initializing Arabic TTS...');

      // Set language to Arabic
      await _flutterTts.setLanguage("ar-SA"); // Saudi Arabic

      // Set speech rate (0.0 to 1.0, default 0.5)
      await _flutterTts.setSpeechRate(0.4); // Slightly slower for clarity

      // Set volume (0.0 to 1.0)
      await _flutterTts.setVolume(1.0);

      // Set pitch (0.5 to 2.0, default 1.0)
      await _flutterTts.setPitch(1.0);

      // Setup handlers
      _flutterTts.setStartHandler(() {
        print('[ArabicTTS] ▶️ Speech started');
        _isSpeaking = true;
      });

      _flutterTts.setCompletionHandler(() {
        print('[ArabicTTS] ✅ Speech completed');
        _isSpeaking = false;
      });

      _flutterTts.setErrorHandler((msg) {
        print('[ArabicTTS] ❌ Error: $msg');
        _isSpeaking = false;
      });

      _flutterTts.setCancelHandler(() {
        print('[ArabicTTS] 🛑 Speech cancelled');
        _isSpeaking = false;
      });

      _isInitialized = true;
      print('[ArabicTTS] ✅ Arabic TTS initialized successfully');
    } catch (e) {
      print('[ArabicTTS] ❌ Initialization error: $e');
      _isInitialized = false;
    }
  }

  /// Speak Arabic text
  Future<void> speak(String arabicText) async {
    if (!_isInitialized) {
      print('[ArabicTTS] ⚠️ TTS not initialized, initializing now...');
      await initialize();
    }

    if (arabicText.isEmpty) {
      print('[ArabicTTS] ⚠️ Empty text, nothing to speak');
      return;
    }

    try {
      print('[ArabicTTS] 🔊 Speaking: $arabicText');
      await _flutterTts.speak(arabicText);
    } catch (e) {
      print('[ArabicTTS] ❌ Error speaking: $e');
    }
  }

  /// Stop speaking
  Future<void> stop() async {
    try {
      print('[ArabicTTS] 🛑 Stopping speech...');
      await _flutterTts.stop();
      _isSpeaking = false;
    } catch (e) {
      print('[ArabicTTS] ❌ Error stopping: $e');
    }
  }

  /// Pause speaking
  Future<void> pause() async {
    try {
      print('[ArabicTTS] ⏸️ Pausing speech...');
      await _flutterTts.pause();
    } catch (e) {
      print('[ArabicTTS] ❌ Error pausing: $e');
    }
  }

  /// Get available languages
  Future<List<dynamic>> getLanguages() async {
    try {
      var languages = await _flutterTts.getLanguages;
      print('[ArabicTTS] 📋 Available languages: $languages');
      return languages;
    } catch (e) {
      print('[ArabicTTS] ❌ Error getting languages: $e');
      return [];
    }
  }

  /// Get available voices for current language
  Future<List<dynamic>> getVoices() async {
    try {
      var voices = await _flutterTts.getVoices;
      print('[ArabicTTS] 🎤 Available voices: $voices');
      return voices;
    } catch (e) {
      print('[ArabicTTS] ❌ Error getting voices: $e');
      return [];
    }
  }

  /// Set speech rate (0.0 to 1.0)
  Future<void> setSpeechRate(double rate) async {
    try {
      await _flutterTts.setSpeechRate(rate);
      print('[ArabicTTS] ⚙️ Speech rate set to: $rate');
    } catch (e) {
      print('[ArabicTTS] ❌ Error setting speech rate: $e');
    }
  }

  /// Dispose resources
  void dispose() {
    print('[ArabicTTS] 🔚 Disposing Arabic TTS...');
    _flutterTts.stop();
  }
}
