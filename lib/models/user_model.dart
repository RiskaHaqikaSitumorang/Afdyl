class UserModel {
  final String uid;
  final String email;
  final String username;
  final Map<String, dynamic> preferences;
  final Map<String, dynamic> progress;

  UserModel({
    required this.uid,
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
  });

  factory UserModel.fromMap(Map<String, dynamic> data, String uid) {
    return UserModel(
      uid: uid,
      email: data['email'] ?? '',
      username: data['username'] ?? '',
      preferences: data['preferences'] ?? {},
      progress: data['progress'] ?? {},
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'username': username,
      'preferences': preferences,
      'progress': progress,
      'createdAt': DateTime.now().toIso8601String(),
    };
  }
}