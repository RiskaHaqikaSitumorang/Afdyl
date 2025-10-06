// lib/services/last_read_service.dart
import 'package:shared_preferences/shared_preferences.dart';

class LastReadService {
  static const String _keyType = 'last_read_type';
  static const String _keySurahNumber = 'last_read_surah_number';
  static const String _keySurahName = 'last_read_surah_name';
  static const String _keyAyahNumber = 'last_read_ayah_number';
  static const String _keyWordNumber = 'last_read_word_number';

  // Simpan progress terakhir dibaca
  static Future<void> saveLastRead({
    required String type, // 'surah' atau 'juz'
    required int surahNumber,
    required String surahName,
    required int ayahNumber,
    required int wordNumber,
  }) async {
    print(
      'LastReadService: Saving data - type: $type, surah: $surahNumber, name: $surahName, ayah: $ayahNumber, word: $wordNumber',
    );
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyType, type);
    await prefs.setInt(_keySurahNumber, surahNumber);
    await prefs.setString(_keySurahName, surahName);
    await prefs.setInt(_keyAyahNumber, ayahNumber);
    await prefs.setInt(_keyWordNumber, wordNumber);
    print('LastReadService: Data saved to SharedPreferences');
  }

  // Ambil data terakhir dibaca
  static Future<Map<String, dynamic>?> getLastRead() async {
    final prefs = await SharedPreferences.getInstance();

    final type = prefs.getString(_keyType);
    final surahNumber = prefs.getInt(_keySurahNumber);
    final surahName = prefs.getString(_keySurahName);
    final ayahNumber = prefs.getInt(_keyAyahNumber);
    final wordNumber = prefs.getInt(_keyWordNumber);

    print(
      'LastReadService: Reading from SharedPreferences - type: $type, surah: $surahNumber, name: $surahName, ayah: $ayahNumber, word: $wordNumber',
    );

    if (type != null &&
        surahNumber != null &&
        surahName != null &&
        ayahNumber != null &&
        wordNumber != null) {
      final result = {
        'type': type,
        'surahNumber': surahNumber,
        'surahName': surahName,
        'ayahNumber': ayahNumber,
        'wordNumber': wordNumber,
      };
      print('LastReadService: Returning data - $result');
      return result;
    }

    print('LastReadService: No complete data found, returning null');
    return null;
  }

  // Hapus data terakhir dibaca
  static Future<void> clearLastRead() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyType);
    await prefs.remove(_keySurahNumber);
    await prefs.remove(_keySurahName);
    await prefs.remove(_keyAyahNumber);
    await prefs.remove(_keyWordNumber);
  }

  // Format teks untuk tampilan
  static String formatLastReadText(Map<String, dynamic> lastRead) {
    final surahName = lastRead['surahName'] as String;
    final ayahNumber = lastRead['ayahNumber'] as int;
    return '$surahName, Ayat $ayahNumber';
  }
}
