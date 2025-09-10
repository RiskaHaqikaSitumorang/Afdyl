import 'dart:async';
import 'dart:ui'; // Untuk ImageFilter jika perlu blur, tapi opsional
import 'package:flutter/material.dart';

class QuranWrappedScreen extends StatefulWidget {
  const QuranWrappedScreen({super.key});

  @override
  _QuranWrappedScreenState createState() => _QuranWrappedScreenState();
}

class _QuranWrappedScreenState extends State<QuranWrappedScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<Animation<double>> _slideAnimations;
  final List<Map<String, String>> topSurahs = [
    {'rank': '#1', 'name': 'Al-Ikhlas'},
    {'rank': '#2', 'name': 'An-Nas'},
    {'rank': '#3', 'name': 'Al-Falaq'},
    {'rank': '#4', 'name': 'Al-Mauun'},
    {'rank': '#5', 'name': 'Al-Fatihah'},
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideAnimations = List.generate(
      topSurahs.length,
      (index) => Tween<double>(
        begin: -100.0,
        end: 0.0,
      ).animate(CurvedAnimation(
        parent: _controller,
        curve: Interval(
          index * 0.2,
          1.0,
          curve: Curves.easeOutBack,
        ),
      )),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.forward();
    });

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        // Opsional: Tambah konfetti atau efek lain
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFF5E6E8),
              Color(0xFFE8B4B8),
            ],
          ),
          image: DecorationImage(
            image: AssetImage('assets/images/bg_wrapped.png'),
            fit: BoxFit.cover,
            opacity: 0.1,
            alignment: Alignment.center,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 40),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  'Top Surah Kamu!',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                    fontFamily: 'OpenDyslexic',
                    letterSpacing: 1.5,
                    height: 1.2,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: Stack(
                  children: [
                    ListView.builder(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 40.0, // Padding horizontal lebih besar untuk jarak dari tepi
                        vertical: 20.0,  // Padding vertikal untuk posisi tengah
                      ),
                      itemCount: topSurahs.length,
                      itemBuilder: (context, index) {
                        final surah = topSurahs[index];
                        return AnimatedBuilder(
                          animation: _slideAnimations[index],
                          builder: (context, child) {
                            return Transform.translate(
                              offset: Offset(_slideAnimations[index].value, 0),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 8.0),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.start, // Mulai dari kiri, geser ke kanan
                                  crossAxisAlignment: CrossAxisAlignment.center, // Tengah vertikal di dalam Row
                                  children: [
                                    const SizedBox(width: 60), // Offset ke kanan lebih besar (sesuai gambar)
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
                                    const SizedBox(width: 20), // Jarak lebih besar antara rank dan nama
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
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'DysQuran',
                  style: const TextStyle(
                    fontSize: 20,
                    color: Color(0xFF388E3C),
                    fontWeight: FontWeight.bold,
                    fontFamily: 'OpenDyslexic',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}