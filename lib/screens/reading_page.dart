// lib/screens/reading_page.dart
import 'package:flutter/material.dart';

class ReadingPage extends StatelessWidget {
  final String type; // 'surah' or 'juz'
  final int number;
  final String name;

  const ReadingPage({
    super.key,
    required this.type,
    required this.number,
    required this.name,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F5DC),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Color(0xFFB8D4B8),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: Icon(Icons.arrow_back, color: Colors.black, size: 20),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      '$name ($type $number)',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                        fontFamily: 'OpenDyslexic',
                      ),
                    ),
                  ),
                  SizedBox(width: 40),
                ],
              ),
            ),
            Expanded(
              child: Center(
                child: Text(
                  'Halaman Pembacaan untuk $name ($type $number)\n(TODO: Tambahkan konten ayat di sini)',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black,
                    fontFamily: 'OpenDyslexic',
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}