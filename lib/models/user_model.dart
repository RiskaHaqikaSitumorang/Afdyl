class UserModel {
  final String id; // Changed from uid to id for Supabase
  final String email;
  final String fullName; // Changed from username to fullName
  final String? profileImageUrl; // URL gambar profil dari Supabase Storage
  final DateTime? createdAt;
  final DateTime? updatedAt;

  UserModel({
    required this.id,
    required this.email,
    required this.fullName,
    this.profileImageUrl,
    this.createdAt,
    this.updatedAt,
  });

  factory UserModel.fromMap(Map<String, dynamic> data) {
    return UserModel(
      id: data['id'] ?? '',
      email: data['email'] ?? '',
      fullName: data['full_name'] ?? '',
      profileImageUrl: data['profile_image_url'],
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
      'full_name': fullName,
      'profile_image_url': profileImageUrl,
      'updated_at': DateTime.now().toIso8601String(),
    };
  }

  // For Supabase insert (with id but without timestamps)
  Map<String, dynamic> toInsertMap() {
    return {
      'id': id,
      'email': email,
      'full_name': fullName,
      'profile_image_url': profileImageUrl,
    };
  }

  // Method untuk copy dengan perubahan
  UserModel copyWith({
    String? id,
    String? email,
    String? fullName,
    String? profileImageUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Getter untuk backward compatibility
  String get uid => id;
}
