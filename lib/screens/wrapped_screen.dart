import 'package:flutter/material.dart';
import '../services/wrapped_service.dart';
import '../utils/surah_names.dart';

class QuranWrappedScreen extends StatefulWidget {
  final bool showLastYear;

  const QuranWrappedScreen({Key? key, this.showLastYear = false})
    : super(key: key);

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

  bool _isLoading = true;
  bool _isWrappedAvailable = false;
  int _daysUntilWrapped = 0;
  List<Map<String, dynamic>> _topSurahs = [];
  int _totalSurahsRead = 0;
  int _totalReadingSessions = 0;
  int _totalDaysActive = 0;
  String _periodYear = '';

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
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOut));

    // Load wrapped data
    _loadWrappedData();
  }

  Future<void> _loadWrappedData() async {
    try {
      // Check availability
      _isWrappedAvailable = WrappedService.isWrappedAvailable();
      _daysUntilWrapped = WrappedService.getDaysUntilWrapped();

      // Get wrapped data
      final wrappedData =
          widget.showLastYear
              ? await WrappedService.getLastYearWrapped()
              : await WrappedService.getCurrentYearWrapped();

      setState(() {
        _topSurahs =
            (wrappedData['topSurahs'] as List<Map<String, dynamic>>).map((
              surah,
            ) {
              return {
                'rank': (_topSurahs.length + 1),
                'name': SurahNames.getName(surah['surat_number'] as int),
                'count': surah['count'] as int,
                'surat_number': surah['surat_number'] as int,
              };
            }).toList();

        _totalSurahsRead = wrappedData['totalSurahsRead'] as int;
        _totalReadingSessions = wrappedData['totalReadingSessions'] as int;
        _totalDaysActive = wrappedData['totalDaysActive'] as int;

        // Set period label (TESTING MODE)
        _periodYear =
            widget.showLastYear
                ? '7 Hari Lalu' // 14-7 days ago
                : '7 Hari Terakhir'; // Last 7 days

        _isLoading = false;
      });

      // Setup animations for items
      for (int i = 0; i < _topSurahs.length; i++) {
        final controller = AnimationController(
          duration: const Duration(milliseconds: 800),
          vsync: this,
        );
        _itemControllers.add(controller);
        _itemFadeAnimations.add(
          Tween<double>(
            begin: 0.0,
            end: 1.0,
          ).animate(CurvedAnimation(parent: controller, curve: Curves.easeIn)),
        );
        _itemSlideAnimations.add(
          Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero).animate(
            CurvedAnimation(parent: controller, curve: Curves.easeOutCubic),
          ),
        );
        _itemScaleAnimations.add(
          Tween<double>(
            begin: 0.8,
            end: 1.0,
          ).animate(CurvedAnimation(parent: controller, curve: Curves.easeOut)),
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
          if (mounted) {
            _itemControllers[i].forward();
          }
        });
      }
    } catch (e) {
      print('[WrappedScreen] ❌ Error loading wrapped data: $e');
      setState(() {
        _isLoading = false;
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
              // Testing Mode Banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  vertical: 8,
                  horizontal: 16,
                ),
                color: Colors.orange.withOpacity(0.9),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.science, color: Colors.white, size: 16),
                    const SizedBox(width: 8),
                    const Text(
                      'TESTING MODE - Data 7 Hari',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        fontFamily: 'OpenDyslexic',
                      ),
                    ),
                  ],
                ),
              ),
              // Header with back button and year toggle
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
                    const Spacer(),
                    // Year toggle button
                    if (!_isLoading && _periodYear.isNotEmpty)
                      GestureDetector(
                        onTap: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) => QuranWrappedScreen(
                                    showLastYear: !widget.showLastYear,
                                  ),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.calendar_today,
                                color: Colors.white,
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _periodYear,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: 'OpenDyslexic',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(child: _buildContent()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    // Loading state
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
            const SizedBox(height: 16),
            Text(
              'Memuat Wrapped...',
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 16,
                fontFamily: 'OpenDyslexic',
              ),
            ),
          ],
        ),
      );
    }

    // Check if wrapped is available for current year
    if (!widget.showLastYear && !_isWrappedAvailable) {
      return _buildUnavailableState();
    }

    // Check if no data
    if (_topSurahs.isEmpty) {
      return _buildNoDataState();
    }

    // Show wrapped data
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Title with year
          FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: Transform.rotate(
                angle: -0.05,
                child: Column(
                  children: [
                    Text(
                      'Top Surah $_periodYear',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontFamily: 'OpenDyslexic',
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
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
          const SizedBox(height: 40),
          // Stats summary
          FadeTransition(
            opacity: _fadeAnimation,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem(_totalDaysActive.toString(), 'Hari Aktif'),
                  _buildStatItem(_totalSurahsRead.toString(), 'Surah Dibaca'),
                  _buildStatItem(
                    _totalReadingSessions.toString(),
                    'Total Sesi',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 40),
          // Surah List
          Expanded(
            child: ListView.builder(
              itemCount: _topSurahs.length,
              itemBuilder: (context, index) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 20),
                  child: _buildSurahItem(_topSurahs[index], index),
                );
              },
            ),
          ),
          // App branding
          FadeTransition(
            opacity: _fadeAnimation,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 20),
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
    );
  }

  Widget _buildUnavailableState() {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.lock_clock, size: 80, color: Colors.white70),
          const SizedBox(height: 24),
          Text(
            'Wrapped ${DateTime.now().year}',
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontFamily: 'OpenDyslexic',
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            'Wrapped untuk tahun ini akan tersedia pada tanggal 31 Desember ${DateTime.now().year}',
            style: const TextStyle(
              fontSize: 18,
              color: Colors.white,
              fontFamily: 'OpenDyslexic',
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Text(
                  '$_daysUntilWrapped',
                  style: const TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontFamily: 'OpenDyslexic',
                  ),
                ),
                Text(
                  'Hari Lagi',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white.withOpacity(0.8),
                    fontFamily: 'OpenDyslexic',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          // Button to view last year
          ElevatedButton(
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder:
                      (context) => const QuranWrappedScreen(showLastYear: true),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Lihat Wrapped ${DateTime.now().year - 1}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
                fontFamily: 'OpenDyslexic',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoDataState() {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.book_outlined, size: 80, color: Colors.white70),
          const SizedBox(height: 24),
          Text(
            'Belum Ada Data',
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontFamily: 'OpenDyslexic',
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            widget.showLastYear
                ? 'Kamu belum membaca Al-Quran di tahun ${DateTime.now().year - 1}.\n\nMulai baca sekarang untuk melihat Wrapped di akhir tahun!'
                : 'Kamu belum membaca Al-Quran tahun ini.\n\nMulai baca sekarang untuk melihat Wrapped di akhir tahun!',
            style: const TextStyle(
              fontSize: 18,
              color: Colors.white,
              fontFamily: 'OpenDyslexic',
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontFamily: 'OpenDyslexic',
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.white.withOpacity(0.8),
            fontFamily: 'OpenDyslexic',
          ),
        ),
      ],
    );
  }

  Widget _buildSurahItem(Map<String, dynamic> surah, int index) {
    if (_itemControllers.isEmpty || index >= _itemControllers.length) {
      return const SizedBox.shrink();
    }

    return AnimatedBuilder(
      animation: _itemControllers[index],
      builder: (context, child) {
        return Opacity(
          opacity: _itemFadeAnimations[index].value,
          child: Transform.translate(
            offset: _itemSlideAnimations[index].value,
            child: Transform.scale(
              scale: _itemScaleAnimations[index].value,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Rank number with gradient
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: _getRankGradient(surah['rank'] as int),
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
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
                    // Surah info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            surah['name'] as String,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                              fontFamily: 'OpenDyslexic',
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Dibaca ${surah['count']} kali',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.black.withOpacity(0.6),
                              fontFamily: 'OpenDyslexic',
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Trophy icon for top 3
                    if ((surah['rank'] as int) <= 3)
                      Icon(
                        Icons.emoji_events,
                        color: _getTrophyColor(surah['rank'] as int),
                        size: 32,
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  List<Color> _getRankGradient(int rank) {
    switch (rank) {
      case 1:
        return [const Color(0xFFFFD700), const Color(0xFFFF8C00)]; // Gold
      case 2:
        return [const Color(0xFFC0C0C0), const Color(0xFF808080)]; // Silver
      case 3:
        return [const Color(0xFFCD7F32), const Color(0xFF8B4513)]; // Bronze
      default:
        return [Colors.black.withOpacity(0.7), Colors.black.withOpacity(0.5)];
    }
  }

  Color _getTrophyColor(int rank) {
    switch (rank) {
      case 1:
        return const Color(0xFFFFD700); // Gold
      case 2:
        return const Color(0xFFC0C0C0); // Silver
      case 3:
        return const Color(0xFFCD7F32); // Bronze
      default:
        return Colors.grey;
    }
  }
}
