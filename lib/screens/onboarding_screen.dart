import 'package:flutter/material.dart';
import '../widgets/loading_button.dart';
import '../routes/app_routes.dart';

class OnboardingScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: Column(
            children: [
              Expanded(
                flex: 3,
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: Color(0xFFE8C5C5),
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        top: 0,
                        left: 0,
                        child: Container(
                          width: 120,
                          height: 200,
                          decoration: BoxDecoration(
                            color: Color(0xFF8CC8A8),
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(20),
                              bottomRight: Radius.circular(80),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          width: 100,
                          height: 150,
                          decoration: BoxDecoration(
                            color: Color(0xFF8CC8A8),
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(80),
                              bottomRight: Radius.circular(20),
                            ),
                          ),
                        ),
                      ),
                      Center(
                        child: SizedBox(
                          width: 200,
                          height: 280,
                          child: Padding(
                            padding: EdgeInsets.all(20),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: Image.asset(
                                'assets/images/muslimah_hijab.png',
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) {
                                  return Icon(
                                    Icons.person,
                                    size: 100,
                                    color: Colors.grey,
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 40),
              Expanded(
                flex: 2,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Selamat Datang\ndi AFDYL!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                        height: 1.2,
                      ),
                    ),
                    SizedBox(height: 20),
                    Text(
                      'Aplikasi belajar membaca Al-Qur\'an yang ramah\n'
                      'untuk anak-anak dan pengguna dengan\ndisleksia.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF666666),
                        height: 1.5,
                      ),
                    ),
                    SizedBox(height: 40),
                    Row(
                      children: [
                        Expanded(
                          child: LoadingButton(
                            isLoading: false,
                            text: 'Daftar',
                            onPressed:
                                () => Navigator.pushReplacementNamed(
                                  context,
                                  AppRoutes.register,
                                ),
                          ),
                        ),
                        SizedBox(width: 15),
                        Expanded(
                          child: LoadingButton(
                            isLoading: false,
                            text: 'Masuk',
                            onPressed:
                                () => Navigator.pushReplacementNamed(
                                  context,
                                  AppRoutes.login,
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
      ),
    );
  }
}
