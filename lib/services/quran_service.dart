// lib/services/quran_service.dart
import 'package:http/http.dart' as http;
import 'dart:convert';

class QuranService {
  static const String _baseUrl = 'https://api.alquran.cloud/v1';

  Future<List<dynamic>> fetchSurahs() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/surah'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['data'] ?? [];
      } else {
        throw Exception('Failed to load surahs');
      }
    } catch (e) {
      // Fallback to static data
      return _getStaticSurahs();
    }
  }

  List<dynamic> _getStaticSurahs() {
    return [
      {'number': 1, 'englishName': 'Al-Fatihah', 'name': 'الفاتحة'},
      {'number': 2, 'englishName': 'Al-Baqarah', 'name': 'البقرة'},
      {'number': 3, 'englishName': 'Ali \'Imran', 'name': 'آل عمران'},
      {'number': 4, 'englishName': 'An-Nisa', 'name': 'النساء'},
      {'number': 5, 'englishName': 'Al-Ma\'idah', 'name': 'المائدة'},
      {'number': 6, 'englishName': 'Al-An\'am', 'name': 'الأنعام'},
      {'number': 7, 'englishName': 'Al-A\'raf', 'name': 'الأعراف'},
    ];
  }

  List<dynamic> generateJuzList() {
    return List.generate(30, (index) => {
      'number': index + 1,
      'name': 'Juz ${index + 1}',
      'arabicName': 'الجزء ${_getArabicNumber(index + 1)}',
    });
  }

  String _getArabicNumber(int number) {
    const arabicNumbers = {
      1: '١', 2: '٢', 3: '٣', 4: '٤', 5: '٥',
      6: '٦', 7: '٧', 8: '٨', 9: '٩', 10: '١٠',
      11: '١١', 12: '١٢', 13: '١٣', 14: '١٤', 15: '١٥',
      16: '١٦', 17: '١٧', 18: '١٨', 19: '١٩', 20: '٢٠',
      21: '٢١', 22: '٢٢', 23: '٢٣', 24: '٢٤', 25: '٢٥',
      26: '٢٦', 27: '٢٧', 28: '٢٨', 29: '٢٩', 30: '٣٠',
    };
    return arabicNumbers[number] ?? number.toString();
  }
}