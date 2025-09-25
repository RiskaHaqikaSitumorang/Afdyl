// lib/models/prayer_times_model.dart
class PrayerTimes {
  final String fajr;
  final String dhuhr;
  final String asr;
  final String maghrib;
  final String isha;

  PrayerTimes({
    required this.fajr,
    required this.dhuhr,
    required this.asr,
    required this.maghrib,
    required this.isha,
  });

  factory PrayerTimes.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>?;
    if (data == null) {
      throw Exception('Invalid response: missing data');
    }
    final timings = data['timings'] as Map<String, dynamic>?;
    if (timings == null) {
      throw Exception('Invalid response: missing timings');
    }
    return PrayerTimes(
      fajr: _formatTime(timings['Fajr']),
      dhuhr: _formatTime(timings['Dhuhr']),
      asr: _formatTime(timings['Asr']),
      maghrib: _formatTime(timings['Maghrib']),
      isha: _formatTime(timings['Isha']),
    );
  }

  static String _formatTime(String time) {
    // Remove timezone info if present (e.g., "05:30 (+07)" -> "05:30")
    return time.split(' ')[0];
  }

  List<PrayerTime> get allPrayers => [
    PrayerTime(name: 'Subuh', time: fajr),
    PrayerTime(name: 'Dzuhur', time: dhuhr),
    PrayerTime(name: 'Ashar', time: asr),
    PrayerTime(name: 'Maghrib', time: maghrib),
    PrayerTime(name: 'Isya', time: isha),
  ];
}

class PrayerTime {
  final String name;
  final String time;

  PrayerTime({required this.name, required this.time});
}
