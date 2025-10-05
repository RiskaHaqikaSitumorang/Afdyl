import 'package:supabase_flutter/supabase_flutter.dart';

class WrappedService {
  static final _supabase = Supabase.instance.client;

  /// Format DateTime to ISO date string (yyyy-MM-dd)
  static String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// Get the wrapped period dates for current year (TESTING: Last 7 days)
  static Map<String, DateTime> getCurrentYearPeriod() {
    final now = DateTime.now();

    // TESTING MODE: Period is last 7 days (1 week ago to now)
    final startDate = now.subtract(const Duration(days: 7));
    final endDate = now;

    return {'start': startDate, 'end': endDate};
  }

  /// Get the wrapped period dates for last year (TESTING: 14-7 days ago)
  static Map<String, DateTime> getLastYearPeriod() {
    final now = DateTime.now();

    // TESTING MODE: Period is 14-7 days ago (previous week)
    final startDate = now.subtract(const Duration(days: 14));
    final endDate = now.subtract(const Duration(days: 7));

    return {'start': startDate, 'end': endDate};
  }

  /// Check if wrapped is available (TESTING: Always available)
  static bool isWrappedAvailable() {
    // TESTING MODE: Always available
    return true;
  }

  /// Get days until wrapped is available (TESTING: Always 0)
  static int getDaysUntilWrapped() {
    // TESTING MODE: Always available (0 days)
    return 0;
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
