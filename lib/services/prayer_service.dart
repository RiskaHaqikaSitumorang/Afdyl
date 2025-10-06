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

    print('[PrayerService] Fetching prayer times from: $url');

    try {
      final response = await http
          .get(
            Uri.parse(url),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 15));

      print('[PrayerService] Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('[PrayerService] Prayer times fetched successfully');
        return PrayerTimes.fromJson(data);
      } else {
        print('[PrayerService] Failed with status: ${response.statusCode}');
        throw Exception('Failed to load prayer times: ${response.statusCode}');
      }
    } catch (e) {
      print('[PrayerService] Error: $e');
      throw Exception('Error fetching prayer times: $e');
    }
  }
}
