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

      await _authService.forgotPassword(email);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Email reset password telah dikirim'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() {
        _emailError = e.toString().replaceFirst('Exception: ', '');
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
