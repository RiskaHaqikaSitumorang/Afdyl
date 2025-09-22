import 'package:flutter/material.dart';

class QuranWrappedScreen extends StatefulWidget {
  @override
  _QuranWrappedScreenState createState() => _QuranWrappedScreenState();
}

class _QuranWrappedScreenState extends State<QuranWrappedScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  final List<AnimationController> _itemControllers = [];
  final List<Animation<double>> _itemFadeAnimations = [];
  final List<Animation<Offset>> _itemSlideAnimations = [];
  final List<Animation<double>> _itemScaleAnimations = [];

  final List<Map<String, dynamic>> topSurahs = [
    {'rank': 1, 'name': 'Al-Ikhlas'},
    {'rank': 2, 'name': 'An-Nas'},
    {'rank': 3, 'name': 'Al-Falaq'},
    {'rank': 4, 'name': 'Al-Maun'},
    {'rank': 5, 'name': 'Al-Fatihah'},
  ];

  @override
  void initState() {
    super.initState();

    // Controller untuk header dan branding
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOut),
    );

    // Controller untuk setiap item surah
    for (int i = 0; i < topSurahs.length; i++) {
      final controller = AnimationController(
        duration: const Duration(milliseconds: 800),
        vsync: this,
      );
      _itemControllers.add(controller);
      _itemFadeAnimations.add(
        Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(parent: controller, curve: Curves.easeIn),
        ),
      );
      _itemSlideAnimations.add(
        Tween<Offset>(
          begin: const Offset(0, 0.5),
          end: Offset.zero,
        ).animate(
          CurvedAnimation(parent: controller, curve: Curves.easeOutCubic),
        ),
      );
      _itemScaleAnimations.add(
        Tween<double>(begin: 0.8, end: 1.0).animate(
          CurvedAnimation(parent: controller, curve: Curves.easeOut),
        ),
      );
    }

    // Mulai animasi header
    _fadeController.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      _slideController.forward();
    });

    // Mulai animasi item satu per satu
    for (int i = 0; i < _itemControllers.length; i++) {
      Future.delayed(Duration(milliseconds: 500 + (i * 300)), () {
        _itemControllers[i].forward();
      });
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    for (var controller in _itemControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/bg_wrapped.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header with back button
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.arrow_back_ios,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Title
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: SlideTransition(
                          position: _slideAnimation,
                          child: Transform.rotate(
                            angle: -0.05,
                            child: Column(
                              children: [
                                Text(
                                  'Top Surah',
                                  style: const TextStyle(
                                    fontSize: 36,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    fontFamily: 'OpenDyslexic',
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                Text(
                                  'Kamu!',
                                  style: const TextStyle(
                                    fontSize: 36,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    fontFamily: 'OpenDyslexic',
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 60),
                      // Surah List
                      Column(
                        children: topSurahs.asMap().entries.map((entry) {
                          int index = entry.key;
                          Map<String, dynamic> surah = entry.value;
                          return Container(
                            margin: const EdgeInsets.only(bottom: 24),
                            child: _buildSurahItem(surah, index),
                          );
                        }).toList(),
                      ),
                      const Spacer(),
                      // App branding
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 40),
                          child: Text(
                            'DysQuran',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.white.withOpacity(0.8),
                              fontFamily: 'OpenDyslexic',
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSurahItem(Map<String, dynamic> surah, int index) {
    return AnimatedBuilder(
      animation: _itemControllers[index],
      builder: (context, child) {
        return Opacity(
          opacity: _itemFadeAnimations[index].value,
          child: Transform.translate(
            offset: _itemSlideAnimations[index].value,
            child: Transform.scale(
              scale: _itemScaleAnimations[index].value,
              child: Row(
                children: [
                  // Rank number
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        '#${surah['rank']}',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontFamily: 'OpenDyslexic',
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Surah icon placeholder
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F5DC),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Surah name
                  Expanded(
                    child: Text(
                      surah['name'],
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                        fontFamily: 'OpenDyslexic',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}