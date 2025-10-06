import 'package:afdyl/constants/app_colors.dart';
import 'package:flutter/material.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/loading_button.dart';
import '../services/auth_service.dart';
import '../routes/app_routes.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isLoading = false;
  String? _emailError;
  String? _passwordError;
  String? _loginError; // Error untuk invalid credentials
  final AuthService _authService = AuthService();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    setState(() {
      _emailError = null;
      _passwordError = null;
      _loginError = null; // Clear login error
      _isLoading = true;
    });

    String email = _emailController.text.trim();
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
      await _authService.login(email, password);
      Navigator.pushReplacementNamed(context, AppRoutes.dashboard);
    } catch (e) {
      setState(() {
        String message = e.toString().replaceAll('Exception: ', '');
        if (message.contains('Invalid login credentials')) {
          // Set error khusus untuk invalid credentials
          _loginError = "Email atau password salah. Silakan coba lagi.";
        } else if (message.contains('email')) {
          _emailError = message;
        } else {
          _passwordError = message;
        }
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _handleForgotPassword() async {
    String email = _emailController.text.trim();

    if (email.isEmpty) {
      setState(() {
        _emailError = 'Masukkan email terlebih dahulu';
      });
      return;
    }

    try {
      if (!email.contains('@')) {
        setState(() {
          _emailError = 'Format email tidak valid';
        });
        return;
      }

      // Show loading
      setState(() => _isLoading = true);

      await _authService.forgotPassword(email);

      if (!mounted) return;
      setState(() => _isLoading = false);

      // Show success dialog with instructions
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 28),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Email Terkirim!',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Link reset password telah dikirim ke:',
                  style: TextStyle(fontSize: 14),
                ),
                SizedBox(height: 8),
                Text(
                  email,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
                SizedBox(height: 16),
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Langkah selanjutnya:',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade900,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        '1. Buka email Anda\n'
                        '2. Cari email dari Supabase\n'
                        '3. Klik link reset password\n'
                        '4. Anda akan diarahkan ke app ini\n'
                        '5. Masukkan password baru Anda',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.blue.shade800,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 12),
                Text(
                  'Tidak menerima email? Periksa folder spam Anda.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  'OK, Mengerti',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.tertiary,
                  ),
                ),
              ),
            ],
          );
        },
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error, color: Colors.white),
              SizedBox(width: 12),
              Expanded(
                child: Text(e.toString().replaceFirst('Exception: ', '')),
              ),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 4),
        ),
      );
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
                    SizedBox(height: 80),
                    Text(
                      'Mari lanjutkan\nmembaca Qur\'an-\nmu',
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
                      keyboardType: TextInputType.emailAddress,
                      errorText: _emailError,
                      onChanged:
                          (value) => setState(() {
                            _emailError = null;
                            _loginError =
                                null; // Clear login error saat mengetik
                          }),
                    ),
                    SizedBox(height: 20),
                    CustomTextField(
                      controller: _passwordController,
                      hintText: 'Password',
                      prefixIcon: Icons.lock_outline,
                      obscureText: !_isPasswordVisible,
                      errorText: _passwordError,
                      onChanged:
                          (value) => setState(() {
                            _passwordError = null;
                            _loginError =
                                null; // Clear login error saat mengetik
                          }),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isPasswordVisible
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: Color(0xFF666666),
                          size: 20,
                        ),
                        onPressed:
                            _isLoading
                                ? null
                                : () => setState(
                                  () =>
                                      _isPasswordVisible = !_isPasswordVisible,
                                ),
                      ),
                    ),
                    // Error message untuk invalid login credentials
                    if (_loginError != null) ...[
                      SizedBox(height: 16),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.red[300]!,
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.error_outline,
                              color: Colors.red[700],
                              size: 20,
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _loginError!,
                                style: TextStyle(
                                  color: Colors.red[700],
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    SizedBox(height: 20),
                    Align(
                      alignment: Alignment.centerRight,
                      child: GestureDetector(
                        onTap: _isLoading ? null : _handleForgotPassword,
                        child: Text(
                          'Lupa password?',
                          style: TextStyle(
                            fontSize: 16,
                            color: _isLoading ? Colors.grey : Colors.black,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 80),
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
                    text: 'Masuk',
                    onPressed: _handleLogin,
                  ),
                  SizedBox(height: 40),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Belum punya akun? ',
                        style: TextStyle(fontSize: 16),
                      ),
                      GestureDetector(
                        onTap:
                            _isLoading
                                ? null
                                : () => Navigator.pushNamed(
                                  context,
                                  AppRoutes.register,
                                ),
                        child: Text(
                          'Daftar',
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
