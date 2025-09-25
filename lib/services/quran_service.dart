import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class QuranService {
  static const String _baseUrl = 'https://api.alquran.cloud/v1';

  // Fetch bookmarks from SharedPreferences
  Future<List<Map<String, dynamic>>> fetchLocalBookmarks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final bookmarkJson = prefs.getString('bookmarks') ?? '[]';
      final bookmarkList = json.decode(bookmarkJson) as List;
      return bookmarkList.cast<Map<String, dynamic>>();
    } catch (e) {
      print('Error fetching local bookmarks: $e');
      return [];
    }
  }

  // Add a bookmark to SharedPreferences
  Future<bool> addLocalBookmark(int surahNumber, int ayahNumber) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final bookmarks = await fetchLocalBookmarks();
      if (bookmarks.any((b) => b['surah_number'] == surahNumber && b['ayah_number'] == ayahNumber)) {
        return false; // Bookmark already exists
      }
      bookmarks.add({
        'id': 'local_${surahNumber}_${ayahNumber}_${DateTime.now().millisecondsSinceEpoch}',
        'surah_number': surahNumber,
        'ayah_number': ayahNumber,
      });
      await prefs.setString('bookmarks', json.encode(bookmarks));
      print('Bookmark added: Surah $surahNumber, Ayah $ayahNumber');
      return true;
    } catch (e) {
      print('Error adding local bookmark: $e');
      return false;
    }
  }

  // Delete a bookmark from SharedPreferences
  Future<bool> deleteLocalBookmark(String bookmarkId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final bookmarks = await fetchLocalBookmarks();
      bookmarks.removeWhere((b) => b['id'] == bookmarkId);
      await prefs.setString('bookmarks', json.encode(bookmarks));
      print('Bookmark deleted: ID $bookmarkId');
      return true;
    } catch (e) {
      print('Error deleting local bookmark: $e');
      return false;
    }
  }

  // Save last read to SharedPreferences
  Future<bool> saveLastRead(int surahNumber, int ayahNumber, String surahName) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastReadData = {
        'surah_number': surahNumber,
        'ayah_number': ayahNumber,
        'surah_name': surahName,
        'timestamp': DateTime.now().toIso8601String(),
      };
      final result = await prefs.setString('last_read', json.encode(lastReadData));
      print('Saved last read: $lastReadData');
      return result;
    } catch (e) {
      print('Error saving last read: $e');
      return false;
    }
  }

  // Fetch last read from SharedPreferences
  Future<Map<String, dynamic>> fetchLastRead() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastReadJson = prefs.getString('last_read');
      print('Raw SharedPreferences last_read: $lastReadJson');
      if (lastReadJson != null) {
        final data = json.decode(lastReadJson) as Map<String, dynamic>;
        print('Fetched last read: $data');
        return data;
      }
      print('No last read data found');
      return {}; // Return empty map if no last read data
    } catch (e) {
      print('Error fetching last read: $e');
      return {};
    }
  }

  // Fetch surah name by number for consistency
  Future<String> getSurahName(int surahNumber) async {
    try {
      final surahs = await fetchSurahs();
      final surah = surahs.firstWhere(
        (s) => s['number'] == surahNumber,
        orElse: () => {'englishName': 'Unknown', 'name': 'غير معروف'},
      );
      final name = surah['englishName'] as String;
      print('Fetched surah name for number $surahNumber: $name');
      return name;
    } catch (e) {
      print('Error fetching surah name: $e');
      return _getStaticSurahs().firstWhere(
        (s) => s['number'] == surahNumber,
        orElse: () => {'englishName': 'Unknown'},
      )['englishName'] as String;
    }
  }

  Future<List<Map<String, dynamic>>> fetchSurahs() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/surah'),
        headers: {'Content-Type': 'application/json'},
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data != null && data['data'] != null) {
          return List<Map<String, dynamic>>.from(data['data']);
        }
      }
    } catch (e) {
      print('Error fetching surahs: $e');
    }
    return _getStaticSurahs();
  }

  Future<List<Map<String, dynamic>>> fetchAyahs(String type, int number) async {
    try {
      final arabicResponse = await http.get(
        Uri.parse('$_baseUrl/$type/$number/ar.alafasy'),
        headers: {'Content-Type': 'application/json'},
      );
      final translationResponse = await http.get(
        Uri.parse('$_baseUrl/$type/$number/id.indonesian'),
        headers: {'Content-Type': 'application/json'},
      );
      if (arabicResponse.statusCode == 200 && translationResponse.statusCode == 200) {
        final arabicData = json.decode(arabicResponse.body);
        final translationData = json.decode(translationResponse.body);
        if (arabicData != null &&
            arabicData['data'] != null &&
            arabicData['data']['ayahs'] != null &&
            translationData != null &&
            translationData['data'] != null &&
            translationData['data']['ayahs'] != null) {
          List<Map<String, dynamic>> arabicAyahs =
              List<Map<String, dynamic>>.from(arabicData['data']['ayahs']);
          List<Map<String, dynamic>> translationAyahs =
              List<Map<String, dynamic>>.from(translationData['data']['ayahs']);
          List<Map<String, dynamic>> combinedAyahs = [];
          for (int i = 0; i < arabicAyahs.length; i++) {
            final arabicAyah = arabicAyahs[i];
            final translationAyah = translationAyahs[i];
            List<Map<String, dynamic>> words = [];
            if (arabicAyah['words'] != null) {
              List<dynamic> arabicWords = arabicAyah['words'];
              for (int j = 0; j < arabicWords.length; j++) {
                words.add({
                  'text': arabicWords[j]['text'] ?? '',
                  'translation': arabicWords[j]['translation'] ?? translationAyah['text'] ?? '',
                });
              }
            }
            combinedAyahs.add({
              'number': arabicAyah['number'] ?? i + 1,
              'numberInSurah': arabicAyah['numberInSurah'] ?? i + 1,
              'text': arabicAyah['text'] ?? '',
              'surah': arabicAyah['surah'] ?? {'number': number},
              'words': words,
              'translation': translationAyah['text'] ?? '',
              'audio': arabicAyah['audio'] ?? '',
            });
          }
          return combinedAyahs;
        }
      }
    } catch (e) {
      print('Error fetching ayahs: $e');
    }
    return [];
  }

  Future<List<Map<String, dynamic>>> fetchTimings() async {
    try {
      final response = await http.get(
        Uri.parse('https://raw.githubusercontent.com/cpfair/quran-align/master/data/afasy.json'),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is List) {
          return List<Map<String, dynamic>>.from(data);
        }
      }
    } catch (e) {
      print('Error fetching timings: $e');
    }
    return [];
  }

  String getArabicNumber(int number) {
    const arabicNumbers = {
      1: '١', 2: '٢', 3: '٣', 4: '٤', 5: '٥',
      6: '٦', 7: '٧', 8: '٨', 9: '٩', 10: '١٠',
      11: '١١', 12: '١٢', 13: '١٣', 14: '١٤', 15: '١٥',
      16: '١٦', 17: '١٧', 18: '١٨', 19: '١٩', 20: '٢٠',
      21: '٢١', 22: '٢٢', 23: '٢٣', 24: '٢٤', 25: '٢٥',
      26: '٢٦', 27: '٢٧', 28: '٢٨', 29: '٢٩', 30: '٣٠',
      31: '٣١', 32: '٣٢', 33: '٣٣', 34: '٣٤', 35: '٣٥',
      36: '٣٦', 37: '٣٧', 38: '٣٨', 39: '٣٩', 40: '٤٠',
      41: '٤١', 42: '٤٢', 43: '٤٣', 44: '٤٤', 45: '٤٥',
      46: '٤٦', 47: '٤٧', 48: '٤٨', 49: '٤٩', 50: '٥٠',
      51: '٥١', 52: '٥٢', 53: '٥٣', 54: '٥٤', 55: '٥٥',
      56: '٥٦', 57: '٥٧', 58: '٥٨', 59: '٥٩', 60: '٦٠',
      61: '٦١', 62: '٦٢', 63: '٦٣', 64: '٦٤', 65: '٦٥',
      66: '٦٦', 67: '٦٧', 68: '٦٨', 69: '٦٩', 70: '٧٠',
      71: '٧١', 72: '٧٢', 73: '٧٣', 74: '٧٤', 75: '٧٥',
      76: '٧٦', 77: '٧٧', 78: '٧٨', 79: '٧٩', 80: '٨٠',
      81: '٨١', 82: '٨٢', 83: '٨٣', 84: '٨٤', 85: '٨٥',
      86: '٨٦', 87: '٨٧', 88: '٨٨', 89: '٨٩', 90: '٩٠',
      91: '٩١', 92: '٩٢', 93: '٩٣', 94: '٩٤', 95: '٩٥',
      96: '٩٦', 97: '٩٧', 98: '٩٨', 99: '٩٩', 100: '١٠٠',
      101: '١٠١', 102: '١٠٢', 103: '١٠٣', 104: '١٠٤', 105: '١٠٥',
      106: '١٠٦', 107: '١٠٧', 108: '١٠٨', 109: '١٠٩', 110: '١١٠',
      111: '١١١', 112: '١١٢', 113: '١١٣', 114: '١١٤',
    };
    return arabicNumbers[number] ?? number.toString();
  }

  List<Map<String, dynamic>> _getStaticSurahs() {
    return [
      {'number': 1, 'englishName': 'Al-Fatihah', 'name': 'الفاتحة'},
      {'number': 2, 'englishName': 'Al-Baqarah', 'name': 'البقرة'},
      {'number': 3, 'englishName': 'Ali \'Imran', 'name': 'آل عمران'},
      {'number': 4, 'englishName': 'An-Nisa', 'name': 'النساء'},
      {'number': 5, 'englishName': 'Al-Ma\'idah', 'name': 'المائدة'},
      {'number': 6, 'englishName': 'Al-An\'am', 'name': 'الأنعام'},
      {'number': 7, 'englishName': 'Al-A\'raf', 'name': 'الأعراف'},
      {'number': 8, 'englishName': 'Al-Anfal', 'name': 'الأنفال'},
      {'number': 9, 'englishName': 'At-Tawbah', 'name': 'التوبة'},
      {'number': 10, 'englishName': 'Yunus', 'name': 'يونس'},
    ];
  }

  List<Map<String, dynamic>> generateJuzList() {
    return List.generate(30, (index) => {
      'number': index + 1,
      'name': 'Juz ${index + 1}',
      'arabicName': 'الجزء ${getArabicNumber(index + 1)}',
    });
  }

  String _getArabicNumber(int number) {
    return getArabicNumber(number);
  }
}