// lib/models/surat_activity_model.dart

class SuratActivity {
  final String id;
  final String userId;
  final int suratNumber;
  final DateTime timestamp;
  final int? count; // Number of times read (null for first read)

  SuratActivity({
    required this.id,
    required this.userId,
    required this.suratNumber,
    required this.timestamp,
    this.count,
  });

  factory SuratActivity.fromJson(Map<String, dynamic> json) {
    return SuratActivity(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      suratNumber: json['surat_number'] as int,
      timestamp: DateTime.parse(json['timestamp'] as String),
      count: json['count'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'surat_number': suratNumber,
      'timestamp': timestamp.toIso8601String().split('T')[0], // Date only
      if (count != null) 'count': count,
    };
  }
}
