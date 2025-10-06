import 'dart:io';
import 'package:afdyl/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:afdyl/services/auth_service.dart';
import 'package:afdyl/models/user_model.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final AuthService _authService = AuthService();

  bool _isEditing = false;
  bool _isLoading = true;
  bool _isSaving = false;
  File? _imageFile;
  UserModel? _currentUser;
  String? _errorMessage;

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    super.dispose();
  }

  // Load user profile from database
  Future<void> _loadUserProfile() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final user = await _authService.getCurrentUserProfile();
      if (user != null) {
        setState(() {
          _currentUser = user;
          _nameController.text = user.fullName;
          _emailController.text = user.email;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Gagal memuat profil pengguna';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  // Save profile changes to database
  Future<void> _saveProfileChanges() async {
    if (_currentUser == null) return;

    try {
      setState(() {
        _isSaving = true;
        _errorMessage = null;
      });

      // Validate input
      if (_nameController.text.trim().isEmpty) {
        throw Exception('Nama pengguna tidak boleh kosong');
      }

      if (_emailController.text.trim().isEmpty) {
        throw Exception('Email tidak boleh kosong');
      }

      // Check if password change is requested
      if (_oldPasswordController.text.isNotEmpty ||
          _newPasswordController.text.isNotEmpty) {
        if (_oldPasswordController.text.isEmpty) {
          throw Exception('Password lama harus diisi');
        }
        if (_newPasswordController.text.isEmpty) {
          throw Exception('Password baru harus diisi');
        }
        if (_newPasswordController.text.length < 6) {
          throw Exception('Password baru minimal 6 karakter');
        }

        // Update password in Supabase Auth
        await _authService.updatePassword(
          _oldPasswordController.text,
          _newPasswordController.text,
        );
      }

      // Update user profile (dengan gambar jika ada)
      final updatedUser = _currentUser!.copyWith(
        fullName: _nameController.text.trim(),
        email: _emailController.text.trim(),
      );

      // Upload gambar baru jika ada
      final result = await _authService.updateUserProfileWithImage(
        updatedUser,
        _imageFile,
      );

      if (result != null) {
        setState(() {
          _currentUser = result;
          _imageFile = null; // Reset setelah berhasil upload
          _isSaving = false;
        });

        // Clear password fields
        _oldPasswordController.clear();
        _newPasswordController.clear();

        _showSuccessMessage();
      } else {
        throw Exception('Gagal memperbarui profil');
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
        _isSaving = false;
      });
      _showErrorMessage(_errorMessage!);
    }
  }

  void _toggleEdit() async {
    if (_isEditing) {
      // Simpan perubahan
      await _saveProfileChanges();
      if (_errorMessage == null) {
        setState(() {
          _isEditing = false;
          // Clear password fields
          _oldPasswordController.clear();
          _newPasswordController.clear();
        });
      }
    } else {
      setState(() {
        _isEditing = true;
        _errorMessage = null;
      });
    }
  }

  /// Show success notification
  void _showSuccessMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.check_circle,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Perubahan berhasil disimpan',
                style: TextStyle(
                  fontFamily: 'OpenDyslexic',
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        duration: const Duration(seconds: 2),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  /// Show error notification
  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontFamily: 'OpenDyslexic',
                  fontSize: 14,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        duration: const Duration(seconds: 3),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  /// Get profile image (prioritas: file baru -> URL dari server -> null)
  ImageProvider? _getProfileImage() {
    if (_imageFile != null) {
      return FileImage(_imageFile!);
    } else if (_currentUser?.profileImageUrl != null &&
        _currentUser!.profileImageUrl!.isNotEmpty) {
      return NetworkImage(_currentUser!.profileImageUrl!);
    }
    return null;
  }

  /// Pilih foto dari kamera / gallery
  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        // Validasi ukuran file
        final file = File(pickedFile.path);
        final fileSize = await file.length();

        if (fileSize > 5 * 1024 * 1024) {
          _showErrorMessage('Ukuran gambar terlalu besar (maksimal 5MB)');
          return;
        }

        setState(() {
          _imageFile = file;
        });
      }
    } catch (e) {
      _showErrorMessage('Gagal memilih gambar: ${e.toString()}');
    }
  }

  void _showImagePickerOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text("Ambil dari Kamera"),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text("Pilih dari Galeri"),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionField({
    required String label,
    required TextEditingController controller,
    String? hint,
    bool obscure = false,
    bool enabled = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
            fontFamily: 'OpenDyslexic',
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          obscureText: obscure,
          enabled: enabled,
          cursorColor: Colors.black, // Set cursor color to black
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: const Color(0xFFE5E5E0),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
          style: const TextStyle(
            fontSize: 16,
            color: Colors.black87,
            fontFamily: 'OpenDyslexic',
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        toolbarHeight: 80, // Increased height to accommodate the extra spacing
        leading: Container(
          width: 40,
          height: 40,
          margin: const EdgeInsets.only(top: 8.0, left: 16.0),
          decoration: BoxDecoration(
            color: AppColors.tertiary.withOpacity(0.4),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: const Icon(
              Icons.chevron_left,
              color: AppColors.tertiary,
              size: 25,
            ),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ),
        title: Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Text(
            "Profil Anda",
            style: const TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.w600,
              fontSize: 18,
              fontFamily: 'OpenDyslexic',
            ),
          ),
        ),
      ),
      body: SafeArea(
        child:
            _isLoading
                ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.tertiary,
                        ),
                      ),
                      SizedBox(height: 16),
                      Text(
                        "Memuat profil...",
                        style: TextStyle(
                          fontFamily: 'OpenDyslexic',
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                )
                : _currentUser == null
                ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.red,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage ?? "Gagal memuat profil",
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontFamily: 'OpenDyslexic',
                          fontSize: 16,
                          color: Colors.red,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadUserProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                        ),
                        child: const Text(
                          "Coba Lagi",
                          style: TextStyle(
                            fontFamily: 'OpenDyslexic',
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
                : SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 20,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Error message display
                      if (_errorMessage != null) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Colors.red.shade100,
                            border: Border.all(color: Colors.red.shade300),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _errorMessage!,
                            style: TextStyle(
                              color: Colors.red.shade800,
                              fontFamily: 'OpenDyslexic',
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],

                      // Foto Profil bisa diubah
                      Center(
                        child: GestureDetector(
                          onTap: _isEditing ? _showImagePickerOptions : null,
                          child: Stack(
                            children: [
                              CircleAvatar(
                                radius: 60,
                                backgroundColor: Colors.grey[200],
                                backgroundImage: _getProfileImage(),
                                child:
                                    _getProfileImage() == null
                                        ? Icon(
                                          Icons.person,
                                          size: 60,
                                          color: Colors.grey[400],
                                        )
                                        : null,
                              ),
                              if (_isEditing)
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: AppColors.tertiary,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.2),
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    padding: const EdgeInsets.all(8),
                                    child: const Icon(
                                      Icons.camera_alt,
                                      size: 20,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),

                      _buildSectionField(
                        label: "Nama lengkap",
                        controller: _nameController,
                        enabled: _isEditing,
                      ),
                      const SizedBox(height: 16),

                      _buildSectionField(
                        label: "Email",
                        controller: _emailController,
                        enabled: _isEditing,
                      ),
                      const SizedBox(height: 16),

                      if (_isEditing) ...[
                        SizedBox(height: 20),
                        const Text(
                          "Ganti password (opsional)",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                            fontFamily: 'OpenDyslexic',
                          ),
                        ),
                        const SizedBox(height: 6),
                        _buildSectionField(
                          label: "Password lama",
                          controller: _oldPasswordController,
                          hint: "Masukkan password lama",
                          obscure: true,
                        ),
                        const SizedBox(height: 12),
                        _buildSectionField(
                          label: "Password baru",
                          controller: _newPasswordController,
                          hint: "Masukkan password baru (min. 6 karakter)",
                          obscure: true,
                        ),
                        const SizedBox(height: 24),
                      ] else ...[
                        _buildSectionField(
                          label: "Password",
                          controller: TextEditingController(text: "********"),
                          enabled: false,
                        ),
                        const SizedBox(height: 24),
                      ],

                      // Tombol Edit/Simpan
                      SizedBox(
                        width: double.infinity,
                        height: 60,
                        child: ElevatedButton(
                          onPressed: _isSaving ? null : _toggleEdit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                _isSaving
                                    ? Colors.grey
                                    : const Color(0xFFE6D679),
                            padding: EdgeInsets.zero,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child:
                              _isSaving
                                  ? const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      SizedBox(
                                        width: 12,
                                        height: 12,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 1.5,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                Colors.white,
                                              ),
                                        ),
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        "Menyimpan...",
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.white,
                                          fontFamily: 'OpenDyslexic',
                                        ),
                                      ),
                                    ],
                                  )
                                  : Text(
                                    _isEditing
                                        ? "Simpan perubahan"
                                        : "Edit profile",
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.black87,
                                      fontFamily: 'OpenDyslexic',
                                    ),
                                  ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Tombol Logout
                      SizedBox(
                        width: double.infinity,
                        height: 60,
                        child: OutlinedButton.icon(
                          onPressed: _showLogoutConfirmation,
                          icon: const Icon(Icons.logout, color: Colors.red),
                          label: const Text(
                            "Logout",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.red,
                              fontFamily: 'OpenDyslexic',
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.red, width: 2),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
      ),
    );
  }

  /// Konfirmasi logout
  void _showLogoutConfirmation() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            "Konfirmasi Logout",
            style: TextStyle(
              fontFamily: 'OpenDyslexic',
              fontWeight: FontWeight.bold,
            ),
          ),
          content: const Text(
            "Apakah Anda yakin ingin keluar dari aplikasi?",
            style: TextStyle(fontFamily: 'OpenDyslexic'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                "Batal",
                style: TextStyle(
                  fontFamily: 'OpenDyslexic',
                  color: Colors.grey,
                ),
              ),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop(); // Tutup dialog
                await _performLogout();
              },
              child: const Text(
                "Logout",
                style: TextStyle(
                  fontFamily: 'OpenDyslexic',
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Proses logout
  Future<void> _performLogout() async {
    try {
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.tertiary),
            ),
          );
        },
      );

      await _authService.signOut();

      // Close loading dialog
      if (mounted) Navigator.of(context).pop();

      // Navigate to login page and clear all routes
      if (mounted) {
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil('/login', (route) => false);
      }
    } catch (e) {
      // Close loading dialog
      if (mounted) Navigator.of(context).pop();

      // Show error
      _showErrorMessage('Gagal logout: ${e.toString()}');
    }
  }
}
