import 'package:afdyl/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../services/wrapped_service.dart';
import '../utils/surah_names.dart';

class QuranWrappedScreen extends StatefulWidget {
  const QuranWrappedScreen({Key? key}) : super(key: key);

  @override
  State<QuranWrappedScreen> createState() => _QuranWrappedScreenState();
}

class _QuranWrappedScreenState extends State<QuranWrappedScreen> {
  bool _isLoading = true;
  bool _useDummyData = true; // Default to dummy for competition
  List<Map<String, dynamic>> _topSurahs = [];
  final GlobalKey _screenshotKey = GlobalKey();
  int _wrappedYear =
      DateTime.now().year; // Track which year's data we're showing

  @override
  void initState() {
    super.initState();
    _loadWrappedData();
  }

  /// Check if wrapped is available (only on/after Dec 31)
  bool _isWrappedAvailable() {
    final now = DateTime.now();
    final yearEnd = DateTime(now.year, 12, 31);
    return now.isAfter(yearEnd) || now.isAtSameMomentAs(yearEnd);
  }

  Future<void> _loadWrappedData() async {
    setState(() => _isLoading = true);

    try {
      final wrappedData =
          _useDummyData
              ? await WrappedService.getDummyWrapped()
              : await WrappedService.getCurrentYearWrapped();

      // Determine the year based on current date
      final now = DateTime.now();
      final yearEnd = DateTime(now.year, 12, 31);
      final isAfterYearEnd =
          now.isAfter(yearEnd) || now.isAtSameMomentAs(yearEnd);

      setState(() {
        _topSurahs =
            (wrappedData['topSurahs'] as List<Map<String, dynamic>>)
                .asMap()
                .entries
                .map((entry) {
                  int index = entry.key;
                  Map<String, dynamic> surah = entry.value;

                  return {
                    'rank': index + 1,
                    'name': SurahNames.getName(surah['surat_number'] as int),
                  };
                })
                .toList();

        // Set the year: if after Dec 31, show current year's data
        _wrappedYear = isAfterYearEnd ? now.year : now.year;
        _isLoading = false;
      });
    } catch (e) {
      print('[WrappedScreen] ❌ Error loading wrapped data: $e');
      setState(() => _isLoading = false);
    }
  }

  /// Capture screenshot and return file path
  Future<String?> _captureScreenshot() async {
    try {
      // Capture screenshot
      RenderRepaintBoundary boundary =
          _screenshotKey.currentContext!.findRenderObject()
              as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData = await image.toByteData(
        format: ui.ImageByteFormat.png,
      );
      Uint8List pngBytes = byteData!.buffer.asUint8List();

      // Save to temp file with timestamp
      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final file = File('${tempDir.path}/quran_wrapped_$timestamp.png');
      await file.writeAsBytes(pngBytes);

      return file.path;
    } catch (e) {
      print('[WrappedScreen] ❌ Error capturing screenshot: $e');
      return null;
    }
  }

  /// Share to other apps using native share sheet
  Future<void> _shareToApps() async {
    // Check if Real mode and not yet available
    if (!_useDummyData && !_isWrappedAvailable()) {
      showDialog(
        context: context,
        builder:
            (context) => AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.lock_clock,
                      color: Colors.orange,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Belum Tersedia',
                      style: TextStyle(
                        fontFamily: 'OpenDyslexic',
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Fitur share Wrapped hanya tersedia setiap:',
                    style: TextStyle(fontFamily: 'OpenDyslexic', fontSize: 14),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.tertiary,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.tertiary.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Text(
                        '31 Desember',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontFamily: 'OpenDyslexic',
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.info_outline,
                          color: Colors.blue,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: const Text(
                            'Gunakan Mode Demo untuk mencoba fitur share',
                            style: TextStyle(
                              fontFamily: 'OpenDyslexic',
                              fontSize: 12,
                              color: Colors.blue,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'OK',
                    style: TextStyle(
                      fontFamily: 'OpenDyslexic',
                      color: AppColors.tertiary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
      );
      return;
    }

    try {
      // Show loading
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Mempersiapkan untuk dibagikan...',
            style: TextStyle(fontFamily: 'OpenDyslexic'),
          ),
          duration: Duration(seconds: 1),
        ),
      );

      // Capture screenshot
      final imagePath = await _captureScreenshot();
      if (imagePath == null) {
        throw Exception('Gagal mengambil screenshot');
      }

      // Share using native share sheet
      final message =
          _useDummyData
              ? 'Lihat Top Surah saya di Afdyl Quran! 📖✨\n\n#QuranWrapped #AfdylQuran'
              : 'Ini adalah Top Surah saya di tahun $_wrappedYear! 📖✨\n\n#QuranWrapped #AfdylQuran';

      await Share.shareXFiles(
        [XFile(imagePath)],
        text: message,
        subject: 'Quran Wrapped $_wrappedYear',
      );
    } catch (e) {
      print('[WrappedScreen] ❌ Error sharing: $e');
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error: $e',
            style: const TextStyle(fontFamily: 'OpenDyslexic'),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        toolbarHeight: 80, // Increased height to accommodate the extra spacing
        leading: Container(
          width: 40,
          height: 40,
          margin: const EdgeInsets.only(top: 8.0, left: 16.0),
          decoration: BoxDecoration(
            color: AppColors.tertiary.withOpacity(0.4),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: const Icon(
              Icons.chevron_left,
              color: AppColors.tertiary,
              size: 25,
            ),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(top: 8.0, right: 16.0),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppColors.secondary.withOpacity(0.4),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                _buildModeButton('Demo', _useDummyData, () {
                  setState(() => _useDummyData = true);
                  _loadWrappedData();
                }),
                _buildModeButton('Real', !_useDummyData, () {
                  setState(() => _useDummyData = false);
                  _loadWrappedData();
                }),
              ],
            ),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/bg_wrapped_2.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: RepaintBoundary(
                  key: _screenshotKey,
                  child: Container(
                    decoration: const BoxDecoration(
                      image: DecorationImage(
                        image: AssetImage('assets/images/bg_wrapped_2.png'),
                        fit: BoxFit.cover,
                      ),
                    ),
                    child: Column(
                      children: [
                        SizedBox(height: 60),
                        // Content
                        Expanded(
                          child:
                              _isLoading
                                  ? const Center(
                                    child: CircularProgressIndicator(
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        AppColors.tertiary,
                                      ),
                                    ),
                                  )
                                  : _buildWrappedContent(),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Afdyl Quran',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: Colors.black.withOpacity(0.6),
                            fontFamily: 'OpenDyslexic',
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      // Share button
      floatingActionButton:
          !_isLoading && _topSurahs.isNotEmpty
              ? FloatingActionButton(
                onPressed: _shareToApps,
                backgroundColor: AppColors.tertiary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(100),
                ),
                child: const Icon(Icons.share, color: AppColors.whiteSoft),
              )
              : null,
    );
  }

  Widget _buildModeButton(String label, bool isActive, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? AppColors.tertiary : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? AppColors.whiteSoft : AppColors.softBlack,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            fontFamily: 'OpenDyslexic',
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildWrappedContent() {
    // Check if Real mode but not yet Dec 31
    if (!_useDummyData && !_isWrappedAvailable()) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: // Main message
                  Transform.rotate(
                angle: -0.05, // Slight rotation upward
                child: const Text(
                  'Wrapped Belum Tersedia',
                  style: TextStyle(
                    fontSize: 46,
                    fontWeight: FontWeight.bold,
                    color: AppColors.softBlack,
                    fontFamily: 'OpenDyslexic',
                    shadows: [
                      Shadow(
                        color: Colors.black26,
                        offset: Offset(2, 2),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            const SizedBox(height: 30),
            // Info box
            Container(
              padding: const EdgeInsets.all(20),
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.95),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.celebration,
                    size: 40,
                    color: AppColors.tertiary,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Quran Wrapped hanya tersedia setiap',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.black87,
                      fontFamily: 'OpenDyslexic',
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.tertiary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      '31 Desember',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontFamily: 'OpenDyslexic',
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Kami akan merangkum semua aktivitas membaca Al-Quran kamu sepanjang tahun! 📖✨',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.black54,
                      fontFamily: 'OpenDyslexic',
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    if (_topSurahs.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.book_outlined, size: 80, color: Colors.white70),
              const SizedBox(height: 24),
              const Text(
                'Belum Ada Data',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontFamily: 'OpenDyslexic',
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                _useDummyData
                    ? 'Silakan gunakan mode "Real" untuk melihat data aktual'
                    : 'Mulai baca Al-Quran untuk melihat Wrapped Anda!',
                style: const TextStyle(
                  fontSize: 18,
                  color: AppColors.softBlack,
                  fontFamily: 'OpenDyslexic',
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/images/bg_wrapped_2.png'),
          fit: BoxFit.cover,
        ),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Title
              Transform.rotate(
                angle:
                    -0.1, // Slight rotation upward (negative for counterclockwise)
                child: Column(
                  children: [
                    const Text(
                      'Top Surah',
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                        fontFamily: 'OpenDyslexic',
                        height: 1.0,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const Text(
                      'Kamu!',
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                        fontFamily: 'OpenDyslexic',
                        height: 1.2,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // Year badge
              if (!_useDummyData)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.tertiary,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    'Tahun $_wrappedYear',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.whiteSoft,
                      fontFamily: 'OpenDyslexic',
                    ),
                  ),
                ),
              // Demo mode indicator
              if (_useDummyData)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    '🎬 Mode Demo',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontFamily: 'OpenDyslexic',
                    ),
                  ),
                ),
              const SizedBox(height: 10),
              // Surah list
              ..._topSurahs.map((surah) => _buildSimpleSurahItem(surah)),
              const SizedBox(height: 60),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSimpleSurahItem(Map<String, dynamic> surah) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 24.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Rank
            Text(
              '#${surah['rank']}',
              style: const TextStyle(
                fontSize: 38,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
                fontFamily: 'OpenDyslexic',
              ),
            ),
            const SizedBox(width: 24),
            // Surah name
            Expanded(
              child: Text(
                surah['name'] as String,
                style: const TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
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
