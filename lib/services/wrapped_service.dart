import 'package:supabase_flutter/supabase_flutter.dart';

class WrappedService {
  static final _supabase = Supabase.instance.client;

  /// Format DateTime to ISO date string (yyyy-MM-dd)
  static String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// Get dummy wrapped data for demo/competition purposes
  static Future<Map<String, dynamic>> getDummyWrapped() async {
    // Simulate loading delay
    await Future.delayed(const Duration(milliseconds: 500));

    return {
      'totalSurahsRead': 15,
      'totalReadingSessions': 89,
      'totalDaysActive': 247,
      'topSurahs': [
        {'surat_number': 112, 'count': 45, 'timestamp': '2025-10-05'}, // Al-Ikhlas
        {'surat_number': 114, 'count': 38, 'timestamp': '2025-10-04'}, // An-Nas
        {'surat_number': 113, 'count': 32, 'timestamp': '2025-10-03'}, // Al-Falaq
        {'surat_number': 107, 'count': 28, 'timestamp': '2025-10-02'}, // Al-Ma'un
        {'surat_number': 1, 'count': 24, 'timestamp': '2025-10-01'},   // Al-Fatihah
      ],
    };
  }

  /// Get the wrapped period dates for current year (PRODUCTION: Full year)
  static Map<String, DateTime> getCurrentYearPeriod() {
    final now = DateTime.now();
    final currentYear = now.year;

    // PRODUCTION: Full year period (Jan 1 to Dec 31)
    final startDate = DateTime(currentYear, 1, 1);
    final endDate = DateTime(currentYear, 12, 31);

    return {'start': startDate, 'end': endDate};
  }

  /// Get the wrapped period dates for last year
  static Map<String, DateTime> getLastYearPeriod() {
    final now = DateTime.now();
    final lastYear = now.year - 1;

    // Last year period (Jan 1 to Dec 31 of last year)
    final startDate = DateTime(lastYear, 1, 1);
    final endDate = DateTime(lastYear, 12, 31);

    return {'start': startDate, 'end': endDate};
  }

  /// Check if wrapped is available (after Dec 31)
  static bool isWrappedAvailable() {
    final now = DateTime.now();
    final yearEnd = DateTime(now.year, 12, 31, 23, 59, 59);
    return now.isAfter(yearEnd);
  }

  /// Get days until wrapped is available
  static int getDaysUntilWrapped() {
    final now = DateTime.now();
    final yearEnd = DateTime(now.year, 12, 31, 23, 59, 59);
    if (now.isAfter(yearEnd)) return 0;
    return yearEnd.difference(now).inDays + 1;
  }

  /// Get top 5 most read surahs for a given period
  static Future<List<Map<String, dynamic>>> getTopSurahs({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        print('[WrappedService] ❌ User not authenticated');
        return [];
      }

      print(
        '[WrappedService] 📊 Fetching top surahs for period: ${_formatDate(startDate)} to ${_formatDate(endDate)}',
      );

      // Query surat_activity for the period, ordered by count descending
      final response = await _supabase
          .from('surat_activity')
          .select('surat_number, count, timestamp')
          .eq('user_id', userId)
          .gte('timestamp', _formatDate(startDate))
          .lte('timestamp', _formatDate(endDate))
          .order('count', ascending: false)
          .limit(5);

      final data = response as List<dynamic>;

      if (data.isEmpty) {
        print('[WrappedService] ℹ️ No reading activity found for this period');
        return [];
      }

      // Transform data
      final topSurahs =
          data.map((item) {
            return {
              'surat_number': item['surat_number'] as int,
              'count': item['count'] as int? ?? 1,
              'timestamp': item['timestamp'] as String,
            };
          }).toList();

      print('[WrappedService] ✅ Found ${topSurahs.length} top surahs');
      return topSurahs;
    } catch (e) {
      print('[WrappedService] ❌ Error fetching top surahs: $e');
      return [];
    }
  }

  /// Get wrapped statistics for a period
  static Future<Map<String, dynamic>> getWrappedStats({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        return {
          'totalSurahsRead': 0,
          'totalReadingSessions': 0,
          'totalDaysActive': 0,
          'topSurahs': <Map<String, dynamic>>[],
        };
      }

      // Get all activities in period
      final response = await _supabase
          .from('surat_activity')
          .select('surat_number, count, timestamp')
          .eq('user_id', userId)
          .gte('timestamp', _formatDate(startDate))
          .lte('timestamp', _formatDate(endDate));

      final data = response as List<dynamic>;

      if (data.isEmpty) {
        return {
          'totalSurahsRead': 0,
          'totalReadingSessions': 0,
          'totalDaysActive': 0,
          'topSurahs': <Map<String, dynamic>>[],
        };
      }

      // Calculate stats
      final uniqueSurahs = data.map((e) => e['surat_number']).toSet().length;
      final totalSessions = data.fold<int>(
        0,
        (sum, item) => sum + ((item['count'] as int?) ?? 1),
      );

      // Count unique days (timestamp is already in yyyy-MM-dd format)
      final uniqueDays =
          data.map((e) => e['timestamp'] as String).toSet().length;

      // Get top surahs
      final topSurahs = await getTopSurahs(
        startDate: startDate,
        endDate: endDate,
      );

      return {
        'totalSurahsRead': uniqueSurahs,
        'totalReadingSessions': totalSessions,
        'totalDaysActive': uniqueDays,
        'topSurahs': topSurahs,
      };
    } catch (e) {
      print('[WrappedService] ❌ Error fetching wrapped stats: $e');
      return {
        'totalSurahsRead': 0,
        'totalReadingSessions': 0,
        'totalDaysActive': 0,
        'topSurahs': <Map<String, dynamic>>[],
      };
    }
  }

  /// Get current year wrapped (available after Dec 31)
  static Future<Map<String, dynamic>> getCurrentYearWrapped() async {
    final period = getCurrentYearPeriod();
    return await getWrappedStats(
      startDate: period['start']!,
      endDate: period['end']!,
    );
  }

  /// Get last year wrapped (always available)
  static Future<Map<String, dynamic>> getLastYearWrapped() async {
    final period = getLastYearPeriod();
    return await getWrappedStats(
      startDate: period['start']!,
      endDate: period['end']!,
    );
  }
}
