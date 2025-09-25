class UserModel {
  final String id; // Changed from uid to id for Supabase
  final String email;
  final String username;
  final Map<String, dynamic> preferences;
  final Map<String, dynamic> progress;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  UserModel({
    required this.id,
    required this.email,
    required this.username,
    this.preferences = const {
      'fontSize': 16,
      'dyslexiaMode': true,
      'arabicFont': 'uthmanic',
      'translationLanguage': 'id',
    },
    this.progress = const {
      'currentSurah': 1,
      'currentAyah': 1,
      'completedSurahs': [],
      'bookmarks': [],
      'readingTime': 0,
    },
    this.createdAt,
    this.updatedAt,
  });

  factory UserModel.fromMap(Map<String, dynamic> data) {
    return UserModel(
      id: data['id'] ?? '',
      email: data['email'] ?? '',
      username: data['username'] ?? '',
      preferences: data['preferences'] ?? {},
      progress: data['progress'] ?? {},
      createdAt:
          data['created_at'] != null
              ? DateTime.parse(data['created_at'])
              : null,
      updatedAt:
          data['updated_at'] != null
              ? DateTime.parse(data['updated_at'])
              : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'username': username,
      'preferences': preferences,
      'progress': progress,
      'updated_at': DateTime.now().toIso8601String(),
    };
  }

  // For Supabase insert (with id but without timestamps)
  Map<String, dynamic> toInsertMap() {
    return {
      'id': id,
      'email': email,
      'username': username,
      'preferences': preferences,
      'progress': progress,
    };
  }

  // Method untuk copy dengan perubahan
  UserModel copyWith({
    String? id,
    String? email,
    String? username,
    Map<String, dynamic>? preferences,
    Map<String, dynamic>? progress,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      username: username ?? this.username,
      preferences: preferences ?? this.preferences,
      progress: progress ?? this.progress,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Getter untuk backward compatibility
  String get uid => id;
}
