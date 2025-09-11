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
    {'rank': '#4', 'name': 'Al-Maun'},
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
          child: Stack(
            children: [
              // Tombol back
              Positioned(
                top: 8,
                left: 8,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.black),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
              ),
              Column(
                children: [
                  const SizedBox(height: 95), // Turunin title sedikit
                  const Text(
                    'Top Surah\nKamu!',
                    style: TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                      fontFamily: 'OpenDyslexic',
                      height: 1.2,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 30),
                  Expanded(
                    child: Center(
                      child: ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: topSurahs.length,
                        itemBuilder: (context, index) {
                          final surah = topSurahs[index];
                          return AnimatedBuilder(
                            animation: _slideAnimations[index],
                            builder: (context, child) {
                              return Transform.translate(
                                offset: Offset(_slideAnimations[index].value, 0),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 14.0),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      // Rank sejajar pakai width tetap
                                      SizedBox(
                                        width: 50,
                                        child: Text(
                                          surah['rank']!,
                                          textAlign: TextAlign.right,
                                          style: const TextStyle(
                                            fontSize: 26,
                                            fontWeight: FontWeight.bold,
                                            fontFamily: 'OpenDyslexic',
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 14),
                                      // Kotak putih
                                      Container(
                                        width: 40,
                                        height: 40,
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                      ),
                                      const SizedBox(width: 20),
                                      // Nama surah
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
                    ),
                  ),
                  const SizedBox(height: 25),
                  const Text(
                    'Quran Wrapped',
                    style: TextStyle(
                      fontSize: 18,
                      color: Color(0xFF388E3C),
                      fontWeight: FontWeight.bold,
                      fontFamily: 'OpenDyslexic',
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
