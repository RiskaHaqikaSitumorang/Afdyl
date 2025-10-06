// lib/services/quran_service.dart
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../utils/surah_names.dart';

class QuranService {
  static const String _baseUrl = 'https://api.alquran.cloud/v1';

  Future<List<Map<String, dynamic>>> fetchSurahs() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/surah'),
        headers: {'Content-Type': 'application/json'},
      );

      print('Response status: ${response.statusCode}'); // Debug print

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('Fetched surahs data: $data'); // Debug print
        if (data != null && data['data'] != null) {
          // Replace English names with Indonesian names
          List<Map<String, dynamic>> surahs = List<Map<String, dynamic>>.from(
            data['data'],
          );
          for (var surah in surahs) {
            final number = surah['number'] as int;
            surah['englishName'] = SurahNames.getName(number);
          }
          return surahs;
        } else {
          print('Invalid data structure from API');
          throw Exception('Invalid data structure from API');
        }
      } else {
        print('HTTP Error: ${response.statusCode} - ${response.body}');
        throw Exception('HTTP ${response.statusCode}: Failed to fetch surahs');
      }
    } catch (e) {
      print('Error fetching surahss: $e');
      throw Exception('Failed to load surahs: $e');
    }
  }

  // Method untuk mendapatkan data static ketika mode offline
  List<Map<String, dynamic>> getStaticSurahs() {
    return _getStaticSurahs();
  }

  Future<List<Map<String, dynamic>>> fetchAyahs(String type, int number) async {
    try {
      // Fetch Arabic text and audio (ar.alafasy for word-by-word and audio support)
      final arabicResponse = await http.get(
        Uri.parse('$_baseUrl/$type/$number/ar.alafasy'),
        headers: {'Content-Type': 'application/json'},
      );

      // Fetch Indonesian translation (id.indonesian for Kemenag translation)
      final translationResponse = await http.get(
        Uri.parse('$_baseUrl/$type/$number/id.indonesian'),
        headers: {'Content-Type': 'application/json'},
      );

      if (arabicResponse.statusCode == 200 &&
          translationResponse.statusCode == 200) {
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

          // Combine Arabic, audio, and translation data
          List<Map<String, dynamic>> combinedAyahs = [];
          for (int i = 0; i < arabicAyahs.length; i++) {
            final arabicAyah = arabicAyahs[i];
            final translationAyah = translationAyahs[i];

            // Process the text - remove Bismillah from first ayah if present
            String processedText = arabicAyah['text'] ?? '';
            List<Map<String, dynamic>> words = [];

            if (arabicAyah['words'] != null) {
              List<dynamic> arabicWords = List.from(arabicAyah['words']);

              // If this is the first ayah (i == 0), remove first 4 words (except for surah 1 and 9)
              if (i == 0 && number != 1 && number != 9) {
                print('Processing first ayah (index $i) for surah $number');
                print('Original ayah text: $processedText');
                print('Original words count: ${arabicWords.length}');

                // Simply remove first 4 words
                if (arabicWords.length >= 4) {
                  arabicWords = arabicWords.sublist(4);
                  print('Removed first 4 words');
                }

                // Remove first 4 words from text as well
                processedText = _removeFirst4Words(processedText);

                print('After processing text: $processedText');
                print('After processing words count: ${arabicWords.length}');
              }

              // Combine words with translations
              for (int j = 0; j < arabicWords.length; j++) {
                words.add({
                  'text': arabicWords[j]['text'] ?? '',
                  'translation':
                      arabicWords[j]['translation'] ??
                      translationAyah['text'] ??
                      '',
                });
              }
            } else if (i == 0 && number != 1 && number != 9) {
              // If there are no words array but this is first ayah, remove first 4 words from text
              print(
                'Processing first ayah without words array for surah $number',
              );
              processedText = _removeFirst4Words(processedText);
            }

            combinedAyahs.add({
              'number': arabicAyah['numberInSurah'] ?? i + 1,
              'text': processedText,
              'surah': arabicAyah['surah'] ?? {'number': number},
              'words': words,
              'translation': translationAyah['text'] ?? '',
              'audio': arabicAyah['audio'] ?? '', // Audio URL for the ayah
            });
          }
          return combinedAyahs;
        }
      }
    } catch (e) {
      print('Error fetching ayahs: $e');
    }

    // No static fallback for ayahs, return empty list to trigger error message
    return [];
  }

  // New method to fetch word timings for Mishary Rashid Alafasy from quran-align repo
  Future<List<Map<String, dynamic>>> fetchTimings() async {
    try {
      final response = await http.get(
        Uri.parse(
          'https://raw.githubusercontent.com/cpfair/quran-align/master/data/afasy.json',
        ),
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

  // Method untuk mendapatkan nomor dalam huruf Arab
  String getArabicNumber(int number) {
    const arabicNumbers = {
      1: '١',
      2: '٢',
      3: '٣',
      4: '٤',
      5: '٥',
      6: '٦',
      7: '٧',
      8: '٨',
      9: '٩',
      10: '١٠',
      11: '١١',
      12: '١٢',
      13: '١٣',
      14: '١٤',
      15: '١٥',
      16: '١٦',
      17: '١٧',
      18: '١٨',
      19: '١٩',
      20: '٢٠',
      21: '٢١',
      22: '٢٢',
      23: '٢٣',
      24: '٢٤',
      25: '٢٥',
      26: '٢٦',
      27: '٢٧',
      28: '٢٨',
      29: '٢٩',
      30: '٣٠',
      31: '٣١',
      32: '٣٢',
      33: '٣٣',
      34: '٣٤',
      35: '٣٥',
      36: '٣٦',
      37: '٣٧',
      38: '٣٨',
      39: '٣٩',
      40: '٤٠',
      41: '٤١',
      42: '٤٢',
      43: '٤٣',
      44: '٤٤',
      45: '٤٥',
      46: '٤٦',
      47: '٤٧',
      48: '٤٨',
      49: '٤٩',
      50: '٥٠',
      51: '٥١',
      52: '٥٢',
      53: '٥٣',
      54: '٥٤',
      55: '٥٥',
      56: '٥٦',
      57: '٥٧',
      58: '٥٨',
      59: '٥٩',
      60: '٦٠',
      61: '٦١',
      62: '٦٢',
      63: '٦٣',
      64: '٦٤',
      65: '٦٥',
      66: '٦٦',
      67: '٦٧',
      68: '٦٨',
      69: '٦٩',
      70: '٧٠',
      71: '٧١',
      72: '٧٢',
      73: '٧٣',
      74: '٧٤',
      75: '٧٥',
      76: '٧٦',
      77: '٧٧',
      78: '٧٨',
      79: '٧٩',
      80: '٨٠',
      81: '٨١',
      82: '٨٢',
      83: '٨٣',
      84: '٨٤',
      85: '٨٥',
      86: '٨٦',
      87: '٨٧',
      88: '٨٨',
      89: '٨٩',
      90: '٩٠',
      91: '٩١',
      92: '٩٢',
      93: '٩٣',
      94: '٩٤',
      95: '٩٥',
      96: '٩٦',
      97: '٩٧',
      98: '٩٨',
      99: '٩٩',
      100: '١٠٠',
      101: '١٠١',
      102: '١٠٢',
      103: '١٠٣',
      104: '١٠٤',
      105: '١٠٥',
      106: '١٠٦',
      107: '١٠٧',
      108: '١٠٨',
      109: '١٠٩',
      110: '١١٠',
      111: '١١١',
      112: '١١٢',
      113: '١١٣',
      114: '١١٤',
    };
    return arabicNumbers[number] ?? number.toString();
  }

  List<Map<String, dynamic>> _getStaticSurahs() {
    // Generate static surahs with Indonesian names
    return List.generate(114, (index) {
      final number = index + 1;
      return {
        'number': number,
        'englishName': SurahNames.getName(number),
        'name': _getArabicSurahName(number),
      };
    });
  }

  // Helper method to get Arabic surah names
  String _getArabicSurahName(int number) {
    const arabicNames = {
      1: 'الفاتحة',
      2: 'البقرة',
      3: 'آل عمران',
      4: 'النساء',
      5: 'المائدة',
      6: 'الأنعام',
      7: 'الأعراف',
      8: 'الأنفال',
      9: 'التوبة',
      10: 'يونس',
      11: 'هود',
      12: 'يوسف',
      13: 'الرعد',
      14: 'ابراهيم',
      15: 'الحجر',
      16: 'النحل',
      17: 'الإسراء',
      18: 'الكهف',
      19: 'مريم',
      20: 'طه',
      21: 'الأنبياء',
      22: 'الحج',
      23: 'المؤمنون',
      24: 'النور',
      25: 'الفرقان',
      26: 'الشعراء',
      27: 'النمل',
      28: 'القصص',
      29: 'العنكبوت',
      30: 'الروم',
      31: 'لقمان',
      32: 'السجدة',
      33: 'الأحزاب',
      34: 'سبإ',
      35: 'فاطر',
      36: 'يس',
      37: 'الصافات',
      38: 'ص',
      39: 'الزمر',
      40: 'غافر',
      41: 'فصلت',
      42: 'الشورى',
      43: 'الزخرف',
      44: 'الدخان',
      45: 'الجاثية',
      46: 'الأحقاف',
      47: 'محمد',
      48: 'الفتح',
      49: 'الحجرات',
      50: 'ق',
      51: 'الذاريات',
      52: 'الطور',
      53: 'النجم',
      54: 'القمر',
      55: 'الرحمن',
      56: 'الواقعة',
      57: 'الحديد',
      58: 'المجادلة',
      59: 'الحشر',
      60: 'الممتحنة',
      61: 'الصف',
      62: 'الجمعة',
      63: 'المنافقون',
      64: 'التغابن',
      65: 'الطلاق',
      66: 'التحريم',
      67: 'الملك',
      68: 'القلم',
      69: 'الحاقة',
      70: 'المعارج',
      71: 'نوح',
      72: 'الجن',
      73: 'المزمل',
      74: 'المدثر',
      75: 'القيامة',
      76: 'الانسان',
      77: 'المرسلات',
      78: 'النبإ',
      79: 'النازعات',
      80: 'عبس',
      81: 'التكوير',
      82: 'الإنفطار',
      83: 'المطففين',
      84: 'الإنشقاق',
      85: 'البروج',
      86: 'الطارق',
      87: 'الأعلى',
      88: 'الغاشية',
      89: 'الفجر',
      90: 'البلد',
      91: 'الشمس',
      92: 'الليل',
      93: 'الضحى',
      94: 'الشرح',
      95: 'التين',
      96: 'العلق',
      97: 'القدر',
      98: 'البينة',
      99: 'الزلزلة',
      100: 'العاديات',
      101: 'القارعة',
      102: 'التكاثر',
      103: 'العصر',
      104: 'الهمزة',
      105: 'الفيل',
      106: 'قريش',
      107: 'الماعون',
      108: 'الكوثر',
      109: 'الكافرون',
      110: 'النصر',
      111: 'المسد',
      112: 'الإخلاص',
      113: 'الفلق',
      114: 'الناس',
    };
    return arabicNames[number] ?? '';
  }

  // Helper method to remove first 4 words from text
  String _removeFirst4Words(String text) {
    print('Original text for 4-word removal: $text'); // Debug print

    String cleanedText = text.trim();
    List<String> textWords = cleanedText.split(RegExp(r'\s+'));

    if (textWords.length >= 4) {
      String removedWords = textWords.take(4).join(' ');
      cleanedText = textWords.skip(4).join(' ').trim();
      print('Removed first 4 words: $removedWords');
      print('Result after removal: $cleanedText');
    } else {
      print('Not enough words to remove (${textWords.length} words found)');
    }

    return cleanedText;
  }

  List<Map<String, dynamic>> generateJuzList() {
    return List.generate(
      30,
      (index) => {
        'number': index + 1,
        'name': 'Juz ${index + 1}',
        'arabicName': 'الجزء ${getArabicNumber(index + 1)}',
      },
    );
  }
}
