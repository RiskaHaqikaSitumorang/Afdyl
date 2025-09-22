import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  final _storage = FirebaseStorage.instance;

  bool _isEditing = false;
  bool _loading = true;
  File? _imageFile;
  String? _photoUrl;

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();

   @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = _auth.currentUser;
    if (user != null) {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      final data = doc.data();
      if (data != null) {
        _nameController.text = data['username'] ?? '';
        _emailController.text = data['email'] ?? user.email ?? '';
        _photoUrl = data['photoUrl'];
      }
    }
    setState(() => _loading = false);
  }

  Future<String?> _uploadImage(File image) async {
    final uid = _auth.currentUser!.uid;
    final ref = _storage.ref().child('user_photos/$uid.jpg');
    await ref.putFile(image);
    return ref.getDownloadURL();
  }

  void _toggleEdit() async {
    if (_isEditing) {
      await _saveChanges();
    }
    setState(() => _isEditing = !_isEditing);
  }

  Future<void> _saveChanges() async {
    try {
      final uid = _auth.currentUser!.uid;
      String? photoUrl = _photoUrl;

      if (_imageFile != null) {
        photoUrl = await _uploadImage(_imageFile!);
      }

      await _firestore.collection('users').doc(uid).update({
        'username': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'photoUrl': photoUrl,
      });

      if (_newPasswordController.text.isNotEmpty &&
          _oldPasswordController.text.isNotEmpty) {
        // Re-authenticate sebelum ganti password
        final cred = EmailAuthProvider.credential(
          email: _auth.currentUser!.email!,
          password: _oldPasswordController.text.trim(),
        );
        await _auth.currentUser!.reauthenticateWithCredential(cred);
        await _auth.currentUser!.updatePassword(_newPasswordController.text.trim());
      }

      _showSuccessDialog();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menyimpan: $e')),
      );
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        Future.delayed(const Duration(seconds: 2), () {
          if (Navigator.of(context).canPop()) Navigator.of(context).pop();
        });

        return Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: const Color(0xFFE5E5E0),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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

              // Foto Profil bisa diubah
              Center(
                child: GestureDetector(
                  onTap: _isEditing ? _showImagePickerOptions : null,
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 60,
                        backgroundImage: _imageFile != null
                            ? FileImage(_imageFile!)
                            : const AssetImage("assets/images/avatar.png")
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
                const Text(
                  "Ganti password",
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
                  hint: "Password lama",
                  obscure: true,
                ),
                const SizedBox(height: 12),
                _buildSectionField(
                  label: "Password baru",
                  controller: _newPasswordController,
                  hint: "Password baru",
                  obscure: true,
                ),
                const SizedBox(height: 24),
              ] else ...[
                _buildSectionField(
                  label: "Password",
                  controller: TextEditingController(text: ""),
                  enabled: false,
                ),
                const SizedBox(height: 24),
              ],

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _toggleEdit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE6D679),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    _isEditing ? "Simpan perubahan" : "Edit profile",
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                      fontFamily: 'OpenDyslexic',
                    ),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}