import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';
import '../services/storage_service.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final StorageService _storageService = StorageService();

  // Get current user
  User? get currentUser => _supabase.auth.currentUser;

  // Auth state stream
  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  Future<UserModel?> register(
    String email,
    String fullName,
    String password,
  ) async {
    try {
      // Create account with Supabase Auth
      final AuthResponse authResponse = await _supabase.auth.signUp(
        email: email,
        password: password,
      );

      if (authResponse.user == null) {
        throw Exception('Gagal membuat akun. Silakan coba lagi.');
      }

      // Debug: Print user ID to ensure it's not null
      print('User ID from auth: ${authResponse.user!.id}');

      // Create user profile in users table
      final UserModel user = UserModel(
        id: authResponse.user!.id,
        email: email,
        fullName: fullName,
      );

      // Debug: Print data yang akan diinsert
      print('Data to insert: ${user.toInsertMap()}');

      try {
        await _supabase.from('users').insert(user.toInsertMap());
        print('User profile created successfully');
      } catch (e) {
        print('Error inserting user profile: $e');

        // Check if error is because user already exists in users table
        if (e.toString().contains('duplicate key') ||
            e.toString().contains('already exists')) {
          // User already exists in users table, try to fetch existing user
          try {
            final existingUserQuery = await _supabase
                .from('users')
                .select()
                .eq('id', authResponse.user!.id)
                .limit(1);

            if (existingUserQuery.isNotEmpty) {
              print('User profile already exists, using existing profile');
              return UserModel.fromMap(existingUserQuery.first);
            }
          } catch (fetchError) {
            print('Error fetching existing user: $fetchError');
          }
        }

        // For other errors, rollback auth user creation
        try {
          await _supabase.auth.signOut();
        } catch (signOutError) {
          print('Error during signout: $signOutError');
        }

        throw Exception('Gagal membuat profil pengguna: $e');
      }

      return user;
    } on AuthException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<UserModel?> login(String email, String password) async {
    try {
      // Login with email + password
      final AuthResponse authResponse = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (authResponse.user == null) {
        throw Exception('Gagal login. Periksa email dan password Anda.');
      }

      // Get user profile from users table
      final userProfileQuery = await _supabase
          .from('users')
          .select()
          .eq('id', authResponse.user!.id)
          .limit(1);

      if (userProfileQuery.isEmpty) {
        throw Exception('Profil pengguna tidak ditemukan');
      }

      return UserModel.fromMap(userProfileQuery.first);
    } on AuthException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<void> forgotPassword(String email) async {
    try {
      // Deep link untuk redirect ke app setelah klik magic link
      const String redirectTo = 'afdylquran://reset-password';

      await _supabase.auth.resetPasswordForEmail(email, redirectTo: redirectTo);
    } on AuthException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      throw Exception('Gagal mengirim email reset: $e');
    }
  }

  // Reset password setelah klik magic link dari email
  Future<void> resetPassword(String newPassword) async {
    try {
      final currentUser = _supabase.auth.currentUser;

      if (currentUser == null) {
        throw Exception(
          'Sesi tidak valid. Silakan klik ulang link di email Anda.',
        );
      }

      // Update password
      await _supabase.auth.updateUser(UserAttributes(password: newPassword));
    } on AuthException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      throw Exception('Gagal reset password: $e');
    }
  }

  Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
    } on AuthException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      throw Exception('Gagal logout: $e');
    }
  }

  // Update user password
  Future<void> updatePassword(
    String currentPassword,
    String newPassword,
  ) async {
    try {
      // Verify current password by trying to sign in with it
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null || currentUser.email == null) {
        throw Exception('User tidak ditemukan');
      }

      // Verify current password
      final signInResponse = await _supabase.auth.signInWithPassword(
        email: currentUser.email!,
        password: currentPassword,
      );

      if (signInResponse.user == null) {
        throw Exception('Password lama tidak valid');
      }

      // Update to new password
      await _supabase.auth.updateUser(UserAttributes(password: newPassword));
    } on AuthException catch (e) {
      if (e.message.contains('Invalid login credentials')) {
        throw Exception('Password lama tidak valid');
      }
      throw Exception(e.message);
    } catch (e) {
      throw Exception('Gagal mengubah password: $e');
    }
  }

  // Get current user profile
  Future<UserModel?> getCurrentUserProfile() async {
    try {
      final user = currentUser;
      if (user == null) return null;

      final userProfileQuery = await _supabase
          .from('users')
          .select()
          .eq('id', user.id)
          .limit(1);

      if (userProfileQuery.isEmpty) return null;

      return UserModel.fromMap(userProfileQuery.first);
    } catch (e) {
      print('Error getting user profile: $e');
      return null;
    }
  }

  // Update user profile
  Future<UserModel?> updateUserProfile(UserModel user) async {
    try {
      await _supabase.from('users').update(user.toMap()).eq('id', user.id);

      return user;
    } catch (e) {
      throw Exception('Gagal memperbarui profil: $e');
    }
  }

  // Delete user account (admin function - be careful!)
  Future<void> deleteUserAccount(String userId) async {
    try {
      // Delete from users table first
      await _supabase.from('users').delete().eq('id', userId);

      // Delete from auth.users will cascade automatically due to foreign key
    } catch (e) {
      throw Exception('Gagal menghapus akun: $e');
    }
  }

  // Get user by ID (admin function)
  Future<UserModel?> getUserById(String userId) async {
    try {
      final userQuery = await _supabase
          .from('users')
          .select()
          .eq('id', userId)
          .limit(1);

      if (userQuery.isEmpty) return null;

      return UserModel.fromMap(userQuery.first);
    } catch (e) {
      print('Error getting user by ID: $e');
      return null;
    }
  }

  // Get all users (admin function)
  Future<List<UserModel>> getAllUsers({int limit = 50, int offset = 0}) async {
    try {
      final usersQuery = await _supabase
          .from('users')
          .select()
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      return usersQuery.map((user) => UserModel.fromMap(user)).toList();
    } catch (e) {
      print('Error getting all users: $e');
      return [];
    }
  }

  // Search users by full name or email (admin function)
  Future<List<UserModel>> searchUsers(String query, {int limit = 20}) async {
    try {
      final usersQuery = await _supabase
          .from('users')
          .select()
          .or('full_name.ilike.%$query%,email.ilike.%$query%')
          .order('created_at', ascending: false)
          .limit(limit);

      return usersQuery.map((user) => UserModel.fromMap(user)).toList();
    } catch (e) {
      print('Error searching users: $e');
      return [];
    }
  }

  // Check if user exists by email
  Future<bool> userExistsByEmail(String email) async {
    try {
      final userQuery = await _supabase
          .from('users')
          .select('id')
          .eq('email', email.toLowerCase())
          .limit(1);

      return userQuery.isNotEmpty;
    } catch (e) {
      print('Error checking user existence: $e');
      return false;
    }
  }

  // Upload profile image
  Future<String> uploadProfileImage(String userId, File imageFile) async {
    try {
      print('[AuthService] Uploading profile image for user: $userId');

      // Upload ke storage
      final imageUrl = await _storageService.uploadProfileImage(
        userId,
        imageFile,
      );

      // Update profile_image_url di database
      await _supabase
          .from('users')
          .update({
            'profile_image_url': imageUrl,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', userId);

      print('[AuthService] Profile image updated in database');
      return imageUrl;
    } catch (e) {
      print('[AuthService] Error uploading profile image: $e');
      throw Exception('Gagal upload foto profil: $e');
    }
  }

  // Delete profile image
  Future<void> deleteProfileImage(String userId, String imageUrl) async {
    try {
      print('[AuthService] Deleting profile image for user: $userId');

      // Hapus dari storage
      await _storageService.deleteProfileImage(imageUrl);

      // Update profile_image_url di database menjadi null
      await _supabase
          .from('users')
          .update({
            'profile_image_url': null,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', userId);

      print('[AuthService] Profile image deleted from database');
    } catch (e) {
      print('[AuthService] Error deleting profile image: $e');
      throw Exception('Gagal hapus foto profil: $e');
    }
  }

  // Update profile with image
  Future<UserModel?> updateUserProfileWithImage(
    UserModel user,
    File? newImageFile,
  ) async {
    try {
      String? newImageUrl = user.profileImageUrl;

      // Jika ada gambar baru, upload dulu
      if (newImageFile != null) {
        // Hapus gambar lama jika ada
        if (user.profileImageUrl != null) {
          await _storageService.deleteProfileImage(user.profileImageUrl!);
        }

        // Upload gambar baru
        newImageUrl = await _storageService.uploadProfileImage(
          user.id,
          newImageFile,
        );
      }

      // Update user dengan URL gambar baru
      final updatedUser = user.copyWith(profileImageUrl: newImageUrl);

      // Update ke database
      await _supabase
          .from('users')
          .update(updatedUser.toMap())
          .eq('id', user.id);

      return updatedUser;
    } catch (e) {
      throw Exception('Gagal memperbarui profil: $e');
    }
  }
}
