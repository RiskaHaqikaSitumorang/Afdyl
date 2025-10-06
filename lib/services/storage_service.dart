import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path/path.dart' as path;

/// Service untuk mengelola Supabase Storage
/// Menangani upload, download, dan delete file dari storage bucket
class StorageService {
  final SupabaseClient _supabase = Supabase.instance.client;
  static const String bucketName = 'afdyl';
  static const String profileImageFolder = 'profile_images';

  /// Upload profile image ke Supabase Storage
  ///
  /// [userId] - ID user untuk nama file
  /// [imageFile] - File gambar yang akan diupload
  ///
  /// Returns: Public URL dari gambar yang diupload
  Future<String> uploadProfileImage(String userId, File imageFile) async {
    try {
      // Validasi file
      if (!await imageFile.exists()) {
        throw Exception('File tidak ditemukan');
      }

      // Validasi ukuran file (max 5MB)
      final fileSize = await imageFile.length();
      if (fileSize > 5 * 1024 * 1024) {
        throw Exception('Ukuran file terlalu besar (maksimal 5MB)');
      }

      // Validasi tipe file
      final extension = path.extension(imageFile.path).toLowerCase();
      if (!['.jpg', '.jpeg', '.png', '.webp'].contains(extension)) {
        throw Exception(
          'Format file tidak didukung. Gunakan JPG, PNG, atau WEBP',
        );
      }

      // Generate path unik dengan timestamp untuk menghindari cache
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = '$userId-$timestamp$extension';
      final filePath = '$profileImageFolder/$fileName';

      print('[StorageService] Uploading file: $filePath');

      // Hapus gambar lama jika ada
      await _deleteOldProfileImages(userId);

      // Upload file ke Supabase Storage
      await _supabase.storage
          .from(bucketName)
          .upload(
            filePath,
            imageFile,
            fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
          );

      // Dapatkan public URL
      final publicUrl = _supabase.storage
          .from(bucketName)
          .getPublicUrl(filePath);

      print('[StorageService] Upload successful: $publicUrl');
      return publicUrl;
    } on StorageException catch (e) {
      print('[StorageService] Storage error: ${e.message}');
      throw Exception('Gagal upload gambar: ${e.message}');
    } catch (e) {
      print('[StorageService] Upload error: $e');
      throw Exception('Gagal upload gambar: $e');
    }
  }

  /// Hapus profile image dari Supabase Storage
  ///
  /// [imageUrl] - URL lengkap dari gambar yang akan dihapus
  Future<void> deleteProfileImage(String imageUrl) async {
    try {
      // Extract file path dari URL
      final filePath = _extractFilePathFromUrl(imageUrl);
      if (filePath == null) {
        print('[StorageService] Invalid URL, cannot extract file path');
        return;
      }

      print('[StorageService] Deleting file: $filePath');

      // Hapus file dari storage
      await _supabase.storage.from(bucketName).remove([filePath]);

      print('[StorageService] Delete successful');
    } on StorageException catch (e) {
      print('[StorageService] Storage error during delete: ${e.message}');
      // Tidak throw error karena file mungkin sudah terhapus
    } catch (e) {
      print('[StorageService] Delete error: $e');
      // Tidak throw error agar tidak mengganggu proses lain
    }
  }

  /// Hapus semua profile images lama untuk user tertentu
  ///
  /// [userId] - ID user yang gambarnya akan dihapus
  Future<void> _deleteOldProfileImages(String userId) async {
    try {
      // List semua file di folder profile_images
      final fileList = await _supabase.storage
          .from(bucketName)
          .list(path: profileImageFolder);

      // Filter file yang dimulai dengan userId
      final userFiles =
          fileList
              .where((file) => file.name.startsWith('$userId-'))
              .map((file) => '$profileImageFolder/${file.name}')
              .toList();

      if (userFiles.isEmpty) {
        print('[StorageService] No old images to delete');
        return;
      }

      print('[StorageService] Deleting ${userFiles.length} old images');

      // Hapus semua file lama
      await _supabase.storage.from(bucketName).remove(userFiles);

      print('[StorageService] Old images deleted successfully');
    } catch (e) {
      print('[StorageService] Error deleting old images: $e');
      // Tidak throw error agar upload tetap bisa berlanjut
    }
  }

  /// Extract file path dari public URL
  ///
  /// Contoh URL: https://xxx.supabase.co/storage/v1/object/public/afdyl/profile_images/123.jpg
  /// Returns: profile_images/123.jpg
  String? _extractFilePathFromUrl(String url) {
    try {
      final uri = Uri.parse(url);
      final segments = uri.pathSegments;

      // Cari index dari bucket name
      final bucketIndex = segments.indexOf(bucketName);
      if (bucketIndex == -1 || bucketIndex >= segments.length - 1) {
        return null;
      }

      // Ambil path setelah bucket name
      final filePath = segments.sublist(bucketIndex + 1).join('/');
      return filePath;
    } catch (e) {
      print('[StorageService] Error extracting file path: $e');
      return null;
    }
  }

  /// Get public URL dari file path
  ///
  /// [filePath] - Path file di storage (contoh: profile_images/123.jpg)
  String getPublicUrl(String filePath) {
    return _supabase.storage.from(bucketName).getPublicUrl(filePath);
  }

  /// Cek apakah file exists di storage
  ///
  /// [filePath] - Path file yang akan dicek
  Future<bool> fileExists(String filePath) async {
    try {
      // Coba list file dengan path spesifik
      final fileList = await _supabase.storage
          .from(bucketName)
          .list(path: path.dirname(filePath));

      final fileName = path.basename(filePath);
      return fileList.any((file) => file.name == fileName);
    } catch (e) {
      print('[StorageService] Error checking file existence: $e');
      return false;
    }
  }

  /// Dapatkan ukuran file di storage
  ///
  /// [filePath] - Path file yang akan dicek ukurannya
  /// Returns: Ukuran file dalam bytes, atau null jika error
  Future<int?> getFileSize(String filePath) async {
    try {
      final fileList = await _supabase.storage
          .from(bucketName)
          .list(path: path.dirname(filePath));

      final fileName = path.basename(filePath);
      final file = fileList.firstWhere(
        (file) => file.name == fileName,
        orElse: () => throw Exception('File not found'),
      );

      return file.metadata?['size'] as int?;
    } catch (e) {
      print('[StorageService] Error getting file size: $e');
      return null;
    }
  }
}
