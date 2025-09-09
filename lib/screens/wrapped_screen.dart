import 'dart:async';

import 'package:flutter/material.dart';


class QuranWrappedScreen extends StatelessWidget {
  const QuranWrappedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Hardcode data top surah sebagai placeholder (nanti ganti dengan data dari Firestore)
    final List<Map<String, String>> topSurahs = [
      {'rank': '#1', 'name': 'Al-Ikhlas'},
      {'rank': '#2', 'name': 'An-Nas'},
      {'rank': '#3', 'name': 'Al-Falaq'},
      {'rank': '#4', 'name': 'Al-Mauun'},
      {'rank': '#5', 'name': 'Al-Fatihah'},
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF5E6E8), // Warna pink lembut seperti gambar
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Top Surah Kamu!',
                style: TextStyle(
                  fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                    fontFamily: 'OpenDyslexic',
                ),
                textAlign: TextAlign.center,
              ),
            ),
            // List Top Surah
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                itemCount: topSurahs.length,
                itemBuilder: (context, index) {
                  final surah = topSurahs[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text(
                              surah['rank']!,
                               style: const TextStyle(
                               fontSize: 18,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'OpenDyslexic',
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Text(
                          surah['name']!,
                          style: const TextStyle(
                           fontSize: 24,
    color: Colors.black,
    fontFamily: 'OpenDyslexic',
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            // Footer (DysQuran branding)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'DysQuran',
                 style: const TextStyle(
                  fontSize: 20,
    color: Color(0xFF388E3C), // ganti dengan warna hijau yang mirip
    fontWeight: FontWeight.bold,
    fontFamily: 'OpenDyslexic',
                  
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}