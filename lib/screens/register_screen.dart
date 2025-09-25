import 'package:flutter/material.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/loading_button.dart';
import '../services/auth_service.dart';
import '../routes/app_routes.dart';

class RegisterScreen extends StatefulWidget {
  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _emailController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isLoading = false;
  String? _emailError;
  String? _usernameError;
  String? _passwordError;
  final AuthService _authService = AuthService();

  @override
  void dispose() {
    _emailController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    setState(() {
      _emailError = null;
      _usernameError = null;
      _passwordError = null;
      _isLoading = true;
    });

    String email = _emailController.text.trim();
    String username = _usernameController.text.trim();
    String password = _passwordController.text;

    if (email.isEmpty) {
      setState(() {
        _emailError = 'Email tidak boleh kosong';
        _isLoading = false;
      });
      return;
    } else if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      setState(() {
        _emailError = 'Format email tidak valid';
        _isLoading = false;
      });
      return;
    }

    if (username.isEmpty) {
      setState(() {
        _usernameError = 'Nama pengguna tidak boleh kosong';
        _isLoading = false;
      });
      return;
    } else if (username.length < 3) {
      setState(() {
        _usernameError = 'Nama pengguna minimal 3 karakter';
        _isLoading = false;
      });
      return;
    }

    if (password.isEmpty) {
      setState(() {
        _passwordError = 'Password tidak boleh kosong';
        _isLoading = false;
      });
      return;
    } else if (password.length < 6) {
      setState(() {
        _passwordError = 'Password minimal 6 karakter';
        _isLoading = false;
      });
      return;
    }

    try {
      await _authService.register(email, username, password);
      _emailController.clear();
      _usernameController.clear();
      _passwordController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Pendaftaran berhasil! Silakan masuk'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pushReplacementNamed(context, AppRoutes.login);
    } catch (e) {
      setState(() {
        _emailError = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(height: 60),
                    Text(
                      'Assalamualaikum\nSelamat Datang di\nAFDYL',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                        height: 1.3,
                      ),
                    ),
                    SizedBox(height: 80),
                    CustomTextField(
                      controller: _emailController,
                      hintText: 'Email',
                      prefixIcon: Icons.email_outlined,
                      errorText: _emailError,
                      keyboardType: TextInputType.emailAddress,
                      onChanged: (value) => setState(() => _emailError = null),
                    ),
                    SizedBox(height: 20),
                    CustomTextField(
                      controller: _usernameController,
                      hintText: 'Nama pengguna',
                      prefixIcon: Icons.person_outline,
                      errorText: _usernameError,
                      onChanged: (value) => setState(() => _usernameError = null),
                    ),
                    SizedBox(height: 20),
                    CustomTextField(
                      controller: _passwordController,
                      hintText: 'Kata sandi',
                      prefixIcon: Icons.lock_outline,
                      obscureText: !_isPasswordVisible,
                      errorText: _passwordError,
                      onChanged: (value) => setState(() => _passwordError = null),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isPasswordVisible ? Icons.visibility_off : Icons.visibility,
                          color: Color(0xFF666666),
                          size: 20,
                        ),
                        onPressed: _isLoading
                            ? null
                            : () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                      ),
                    ),
                    SizedBox(height: 60),
                  ],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(24.0),
              child: Column(
                children: [
                  LoadingButton(
                    isLoading: _isLoading,
                    text: 'Daftar',
                    onPressed: _handleRegister,
                  ),
                  SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Sudah punya akun? ',
                        style: TextStyle(fontSize: 16),
                      ),
                      GestureDetector(
                        onTap: _isLoading
                            ? null
                            : () => Navigator.pushReplacementNamed(context, AppRoutes.login),
                        child: Text(
                          'Masuk',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}