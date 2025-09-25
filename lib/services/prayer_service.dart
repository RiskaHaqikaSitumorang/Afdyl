// lib/services/prayer_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/prayer_times_model.dart';

class PrayerService {
  static const String baseUrl = 'https://api.aladhan.com/v1/timings';

  Future<PrayerTimes> fetchPrayerTimes(
    double latitude,
    double longitude,
  ) async {
    final now = DateTime.now();
    final dateString =
        '${now.day.toString().padLeft(2, '0')}-${now.month.toString().padLeft(2, '0')}-${now.year}';

    final url =
        '$baseUrl/$dateString?latitude=$latitude&longitude=$longitude&method=2';

    try {
      final response = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return PrayerTimes.fromJson(data);
      } else {
        throw Exception('Failed to load prayer times: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching prayer times: $e');
    }
  }
}
