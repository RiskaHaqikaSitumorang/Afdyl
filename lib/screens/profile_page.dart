import 'dart:io';
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
          _nameController.text = user.username;
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

      // Update user profile
      final updatedUser = _currentUser!.copyWith(
        username: _nameController.text.trim(),
        email: _emailController.text.trim(),
      );

      final result = await _authService.updateUserProfile(updatedUser);
      if (result != null) {
        setState(() {
          _currentUser = result;
          _isSaving = false;
        });

        // Clear password fields
        _oldPasswordController.clear();
        _newPasswordController.clear();

        _showSuccessDialog();
      } else {
        throw Exception('Gagal memperbarui profil');
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
        _isSaving = false;
      });
      _showErrorDialog(_errorMessage!);
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

  /// Popup success auto-close
  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        Future.delayed(const Duration(seconds: 2), () {
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).pop(); // tutup popup otomatis
          }
        });

        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  "assets/images/ic_checkmark.png",
                  width: 100,
                  height: 100,
                ),
                const SizedBox(height: 16),
                const Text(
                  "Perubahan berhasil disimpan",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    fontFamily: 'OpenDyslexic',
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Popup error dialog
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            "Error",
            style: TextStyle(
              fontFamily: 'OpenDyslexic',
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
          ),
          content: Text(
            message,
            style: const TextStyle(fontFamily: 'OpenDyslexic'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                "OK",
                style: TextStyle(
                  fontFamily: 'OpenDyslexic',
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Pilih foto dari kamera / gallery
  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);

    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
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
      backgroundColor: const Color(0xFFFFFEF3),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back, color: Colors.green),
              ),
              const SizedBox(height: 10),

              // Loading state
              if (_isLoading)
                const Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.green,
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
                  ),
                )
              // Error state
              else if (_currentUser == null)
                Expanded(
                  child: Center(
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
                  ),
                )
              // Main content
              else ...[
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
                          backgroundImage:
                              _imageFile != null
                                  ? FileImage(_imageFile!)
                                  : const AssetImage("/images/ic_avatar.png")
                                      as ImageProvider,
                        ),
                        if (_isEditing)
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white,
                              ),
                              padding: const EdgeInsets.all(6),
                              child: const Icon(
                                Icons.camera_alt,
                                size: 20,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 30),

                _buildSectionField(
                  label: "Nama pengguna",
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

                Expanded(child: SizedBox()),

                SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _toggleEdit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          _isSaving ? Colors.grey : const Color(0xFFE6D679),
                      padding: EdgeInsets.zero, // Hilangkan padding default
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
                                    valueColor: AlwaysStoppedAnimation<Color>(
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
                              _isEditing ? "Simpan perubahan" : "Edit profile",
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Colors.black87,
                                fontFamily: 'OpenDyslexic',
                              ),
                            ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
