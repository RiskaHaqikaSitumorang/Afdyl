// lib/screens/dashboard_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import '../routes/app_routes.dart';
import '../widgets/page_transitions.dart';
import '../screens/profile_page.dart';
import '../constants/app_colors.dart';
import '../constants/arabic_text_styles.dart';
import '../services/prayer_service.dart';
import '../services/last_read_service.dart';
import '../models/prayer_times_model.dart';
import '../main.dart';

class DashboardScreen extends StatefulWidget {
  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with WidgetsBindingObserver, RouteAware {
  String currentTime =
      "${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')}";
  String prayerTime = "Memuat jadwal sholat...";
  String lastRead = "Belum ada bacaan";
  Map<String, dynamic>? lastReadData;
  String location = "Mendapatkan lokasi...";
  late Timer _timer;

  // Prayer times state
  PrayerTimes? prayerTimes;
  bool isLoadingPrayerTimes = true;
  final PrayerService _prayerService = PrayerService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startTimeUpdate();
    _getCurrentLocation();
    _loadLastReadData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)! as PageRoute);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    routeObserver.unsubscribe(this);
    _timer.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      // Refresh data saat user kembali ke aplikasi/dashboard
      _loadLastReadData();
    }
  }

  @override
  void didPush() {
    // Called when the current route has been pushed
    print('Dashboard: didPush called');
    _loadLastReadData();
  }

  @override
  void didPopNext() {
    // Called when the top route has been popped off, and this route shows up
    print('Dashboard: didPopNext called - User returned to dashboard');
    _loadLastReadData();
  }

  void _startTimeUpdate() {
    _updateTime();
    const Duration updateInterval = Duration(minutes: 1);
    _timer = Timer.periodic(updateInterval, (timer) {
      if (mounted) {
        setState(() {
          _updateTime();
          // Refresh next-prayer header each minute when data is available
          _updateNextPrayerMessageFromModel();
        });
      }
    });
  }

  void _updateTime() {
    final now = DateTime.now();
    currentTime =
        "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";
  }

  Future<void> _loadLastReadData() async {
    print('Loading last read data...');
    final data = await LastReadService.getLastRead();
    print('Last read data: $data');
    setState(() {
      lastReadData = data;
      if (data != null) {
        lastRead = LastReadService.formatLastReadText(data);
        print('Formatted last read: $lastRead');
      } else {
        lastRead = "Belum ada bacaan";
        print('No last read data found');
      }
    });
  }

  void _onLastReadTap() {
    if (lastReadData != null) {
      Navigator.pushNamed(
        context,
        AppRoutes.reading,
        arguments: {
          'type': lastReadData!['type'],
          'number': lastReadData!['surahNumber'],
          'name': lastReadData!['surahName'],
          'initialAyah': lastReadData!['ayahNumber'],
          'initialWord': lastReadData!['wordNumber'],
        },
      ).then((_) {
        // Refresh data saat kembali dari reading page
        print('Returned from reading page, refreshing last read data...');
        _loadLastReadData();
      });
    } else {
      // Jika belum ada data, buka halaman Quran
      Navigator.pushNamed(context, AppRoutes.quran).then((_) {
        // Refresh data saat kembali dari quran page
        print('Returned from quran page, refreshing last read data...');
        _loadLastReadData();
      });
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            location = "Izin lokasi ditolak";
            isLoadingPrayerTimes = false; // stop spinner if user denies
          });
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        setState(() {
          location = "Izin lokasi permanen ditolak, aktifkan di pengaturan";
          isLoadingPrayerTimes = false; // stop spinner if permanently denied
        });
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 10),
      );
      await _getPlaceNameFromCoordinates(position.latitude, position.longitude);
      await _fetchTodayPrayerTimes(position.latitude, position.longitude);
    } catch (e) {
      setState(() {
        location = "Gagal mendapatkan lokasi: $e";
        isLoadingPrayerTimes = false; // ensure spinner stops on error
      });
    }
  }

  Future<void> _getPlaceNameFromCoordinates(
    double latitude,
    double longitude,
  ) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        latitude,
        longitude,
      );
      if (placemarks.isNotEmpty) {
        Placemark placemark = placemarks.first;
        String locality = placemark.locality ?? "Unknown";
        String administrativeArea = placemark.administrativeArea ?? "Unknown";
        setState(() {
          location = "$locality, $administrativeArea";
        });
      } else {
        setState(() {
          location = "Lokasi tidak ditemukan";
        });
      }
    } catch (e) {
      setState(() {
        location = "Gagal mengambil nama lokasi: $e";
      });
    }
  }

  Future<void> _fetchTodayPrayerTimes(double latitude, double longitude) async {
    try {
      if (mounted) setState(() => isLoadingPrayerTimes = true);
      final fetchedPrayerTimes = await _prayerService.fetchPrayerTimes(
        latitude,
        longitude,
      );
      setState(() {
        prayerTimes = fetchedPrayerTimes;
        isLoadingPrayerTimes = false;
      });
      // Update the header message using the newly loaded model
      _updateNextPrayerMessageFromModel();
    } catch (e) {
      setState(() {
        isLoadingPrayerTimes = false;
      });
      print('Error fetching prayer times: $e');
    }
  }

  // --- Helpers to compute the next upcoming prayer name ---
  static const Map<String, String> _idPrayerNamesLower = {
    'Fajr': 'subuh',
    'Dhuhr': 'zuhur',
    'Asr': 'ashar',
    'Maghrib': 'maghrib',
    'Isha': 'isya',
  };

  DateTime _parseToday(String hhmm) {
    final clean = hhmm.split(' ').first; // strip timezone if exists
    final parts = clean.split(':');
    final now = DateTime.now();
    final h = int.tryParse(parts[0]) ?? 0;
    final m = (parts.length > 1) ? int.tryParse(parts[1]) ?? 0 : 0;
    return DateTime(now.year, now.month, now.day, h, m);
  }

  void _updateNextPrayerMessageFromModel() {
    if (prayerTimes == null) return;
    final now = DateTime.now();
    final order = [
      MapEntry('Fajr', prayerTimes!.fajr),
      MapEntry('Dhuhr', prayerTimes!.dhuhr),
      MapEntry('Asr', prayerTimes!.asr),
      MapEntry('Maghrib', prayerTimes!.maghrib),
      MapEntry('Isha', prayerTimes!.isha),
    ];
    String? nextNameLower;
    for (final e in order) {
      final t = _parseToday(e.value);
      if (t.isAfter(now)) {
        nextNameLower = _idPrayerNamesLower[e.key];
        break;
      }
    }
    nextNameLower ??= _idPrayerNamesLower['Fajr'];
    setState(() {
      final capitalizedPrayer =
          nextNameLower != null
              ? nextNameLower[0].toUpperCase() + nextNameLower.substring(1)
              : '-';
      prayerTime = 'Menuju waktu shalat $capitalizedPrayer';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.whiteSoft,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.primary, AppColors.primaryDark],
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      height: 200,
                      child: ClipRRect(
                        child: Opacity(
                          opacity: 1,
                          child: Transform.scale(
                            scale: 1,
                            alignment: Alignment.bottomCenter,
                            child: Image.asset(
                              'assets/images/img_masjid.png',
                              fit: BoxFit.fitHeight,
                              alignment: Alignment.bottomCenter,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              GestureDetector(
                                onTap: () {
                                  context.pushSlideLeft(const ProfilePage());
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.3),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.person,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  Navigator.pushNamed(
                                    context,
                                    AppRoutes.wrapped,
                                  );
                                },
                                child: Container(
                                  width: 40,
                                  height: 40,
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.3),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Image.asset(
                                    'assets/images/ic_rank.png',
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 32),
                          Text(
                            currentTime,
                            style: GoogleFonts.montserrat(
                              fontSize: 64,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 2,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                prayerTime,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: AppColors.blackPrimary,
                                  fontFamily: 'OpenDyslexic',
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Container(
                            width: double.infinity,
                            child: Expanded(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Opacity(
                                    opacity: 0.5,
                                    child: Image.asset(
                                      'assets/images/ic_point.png',
                                      width: 24,
                                      height: 24,
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Flexible(
                                    child: Text(
                                      location,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: AppColors.blackPrimary
                                            .withOpacity(0.5),
                                        fontFamily: 'OpenDyslexic',
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 50),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Terakhir dibaca section - positioned between header and activities
              Transform.translate(
                offset: const Offset(0, -42), // Move up to overlap with header
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: GestureDetector(
                    onTap: _onLastReadTap,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.shadowMedium,
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Image.asset(
                            'assets/images/ic_quran.png',
                            width: 24,
                            height: 24,
                            // color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Terakhir dibaca',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: AppColors.textSecondary,
                                    fontFamily: 'OpenDyslexic',
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  lastRead,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                    fontFamily: 'OpenDyslexic',
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.chevron_right,
                            color: AppColors.textSecondary,
                            size: 24,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Transform.translate(
                offset: const Offset(0, -20),
                child: Column(
                  children: [
                    // Prayer Times Section
                    _buildPrayerTimesSection(),
                    const SizedBox(height: 20),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 24.0),
                          child: Text(
                            'Aktivitas untuk anda',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.black,
                              fontFamily: 'OpenDyslexic',
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24.0),
                          child: Column(
                            children: [
                              // Baris pertama: Al-Quran dan Tebak Hijaiyah
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildActivityCard(
                                      imagePath: 'assets/images/ic_quran.png',
                                      title: 'Al-Quran',
                                      backgroundColor: AppColors.primary,
                                      onTap: () {
                                        Navigator.pushNamed(
                                          context,
                                          AppRoutes.quran,
                                        ).then((_) {
                                          // Refresh data saat kembali dari quran page
                                          print(
                                            'Returned from Al-Quran page, refreshing last read data...',
                                          );
                                          _loadLastReadData();
                                        });
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: _buildActivityCard(
                                      imagePath:
                                          'assets/images/ic_text_bacaan.png',
                                      title: 'Tebak Hijaiyah',
                                      backgroundColor: AppColors.yellow,
                                      onTap: () {
                                        Navigator.pushNamed(
                                          context,
                                          AppRoutes.hijaiyahRecognition,
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              // Baris kedua: Jejak Hijaiyah dan Latihan Lafal
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildActivityCard(
                                      imagePath:
                                          'assets/images/ic_hijaiyah.png',
                                      title: 'Jejak Hijaiyah',
                                      backgroundColor: AppColors.yellow,
                                      onTap: () {
                                        Navigator.pushNamed(
                                          context,
                                          AppRoutes.hijaiyahTracing,
                                        );
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: _buildActivityCard(
                                      imagePath:
                                          'assets/images/ic_sound_wave.png',
                                      title: 'Latihan Lafal',
                                      backgroundColor: AppColors.primary,
                                      onTap: () {
                                        Navigator.pushNamed(
                                          context,
                                          AppRoutes.latihanKata,
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              // Baris ketiga: Qibla (full width)
                              _buildActivityCardLarge(
                                imagePath: 'assets/images/Kaaba.png',
                                title: 'Qibla',
                                backgroundColor: AppColors.primary,
                                onTap: () {
                                  Navigator.pushNamed(context, AppRoutes.qibla);
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActivityCard({
    required String imagePath,
    required String title,
    required Color backgroundColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 140,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: _buildCardContent(title, imagePath),
        ),
      ),
    );
  }

  Widget _buildCardContent(String title, String imagePath) {
    switch (title) {
      case 'Al-Quran':
        // Layout: buku besar di kiri bawah, teks di kanan bawah
        return Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.primary, AppColors.primaryLight],
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                left: -20,
                bottom: -10,
                child: Image.asset(
                  imagePath,
                  width: 120,
                  // height: 150,
                  alignment: Alignment.bottomLeft,
                ),
              ),
              // Teks di kanan-bawah
              Padding(
                padding: const EdgeInsets.only(right: 16.0, bottom: 16.0),
                child: Align(
                  alignment: Alignment.bottomRight,
                  child: Text(
                    'Al-\nQuran',
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                      fontFamily: 'OpenDyslexic',
                    ),
                  ),
                ),
              ),
            ],
          ),
        );

      case 'Tebak Hijaiyah':
        // Layout baru: sesuai mock ke-2 (beige wedge di kiri-atas, sticky note miring di kiri-bawah,
        // huruf Arab besar, judul dua baris di kanan-tengah)
        return Stack(
          children: [
            // Background gradient lembut
            Positioned.fill(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.yellow, Color(0xFFFFFBD0)],
                  ),
                ),
              ),
            ),
            // Wedge/plate beige di kiri-atas (sedikit diputar agar sisi kanan miring)
            Positioned(
              left: -6,
              top: 0,
              child: Transform.rotate(
                angle: 0.2,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Color(0xFFE8C9A8), // beige lembut
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Center(
                    child: Opacity(
                      opacity: 0.8,
                      child: Text(
                        'ب',
                        style: ArabicTextStyles.custom(
                          fontSize: 52,
                          fontWeight: FontWeight.w700,
                          opacity: 0.9,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            // Sticky note kuning pucat di kiri-bawah
            Positioned(
              left: -12,
              bottom: -10,
              child: Transform.rotate(
                angle: -0.14,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Color(0xFFFFFFCC),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Opacity(
                      opacity: 0.8,
                      child: Text(
                        'ا',
                        style: ArabicTextStyles.custom(
                          fontSize: 52,
                          fontWeight: FontWeight.w700,
                          opacity: 0.9,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            // Judul dua baris di kanan, disejajarkan vertikal tengah
            Padding(
              padding: const EdgeInsets.only(right: 16.0, bottom: 16.0),
              child: Align(
                alignment: Alignment.bottomRight,
                child: Text(
                  'Tebak\nHijaiyah',
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                    fontFamily: 'OpenDyslexic',
                  ),
                ),
              ),
            ),
          ],
        );

      case 'Jejak Hijaiyah':
        // Layout: huruf besar di kiri, kotak kecil di belakang, teks di kiri bawah
        return Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.yellow, Color(0xFFFFFBD0)],
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                left: -6,
                top: -30,
                child: Opacity(
                  opacity: 0.7,
                  child: Image.asset(
                    imagePath,
                    width: 100,
                    alignment: Alignment.bottomLeft,
                  ),
                ),
              ),
              // Teks di kanan-bawah
              Padding(
                padding: const EdgeInsets.only(right: 16.0, bottom: 16.0),
                child: Align(
                  alignment: Alignment.bottomRight,
                  child: Text(
                    'Jejak\nHijaiyah',
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                      fontFamily: 'OpenDyslexic',
                    ),
                  ),
                ),
              ),
            ],
          ),
        );

      case 'Latihan Lafal':
        // Layout: lingkaran oranye di kiri-tengah dengan bar vertikal, teks di kanan tengah
        return Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.primary, AppColors.primaryLight],
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                left: -20,
                top: -12,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFFFFB74D).withOpacity(0.4),
                  ),
                  child: Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _AudioBar(height: 32),
                        const SizedBox(width: 10),
                        const _AudioBar(height: 56),
                        const SizedBox(width: 10),
                        _AudioBar(height: 32),
                      ],
                    ),
                  ),
                ),
              ),
              // Teks di kanan-bawah
              Padding(
                padding: const EdgeInsets.only(right: 16.0, bottom: 16.0),
                child: Align(
                  alignment: Alignment.bottomRight,
                  child: Text(
                    'Latihan\nLafal',
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                      fontFamily: 'OpenDyslexic',
                    ),
                  ),
                ),
              ),
            ],
          ),
        );

      default:
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Image.asset(imagePath, fit: BoxFit.contain),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black,
                fontFamily: 'OpenDyslexic',
              ),
            ),
          ],
        );
    }
  }

  Widget _buildActivityCardLarge({
    required String imagePath,
    required String title,
    required Color backgroundColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 80,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomLeft,
            end: Alignment.topRight,
            colors: [AppColors.primary, AppColors.primaryLight],
          ),
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: Stack(
            children: [
              // Kaaba icon pinned to the left, not affecting the centered title
              Align(
                alignment: Alignment.centerLeft,
                child: SizedBox(
                  width: 80,
                  height: 80,
                  child: Center(
                    child: Image.asset(
                      imagePath,
                      width: 60,
                      height: 60,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
              // Title perfectly centered relative to the whole card
              Center(
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18,
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
  }

  Widget _buildPrayerTimesSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Waktu Shalat',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black,
              fontFamily: 'OpenDyslexic',
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  AppColors.primary,
                  AppColors.primaryLight.withOpacity(0.8),
                ],
              ),
              color: const Color(0xFFE8DCC6),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child:
                isLoadingPrayerTimes
                    ? const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.primary,
                        ),
                      ),
                    )
                    : prayerTimes != null
                    ? SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children:
                            prayerTimes!.allPrayers
                                .map(
                                  (prayer) => _buildPrayerTimeCard(
                                    prayer.name,
                                    prayer.time,
                                  ),
                                )
                                .toList(),
                      ),
                    )
                    : const Center(
                      child: Text(
                        'Gagal memuat jadwal sholat',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.black54,
                          fontFamily: 'OpenDyslexic',
                        ),
                      ),
                    ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrayerTimeCard(String prayerName, String time) {
    return SizedBox(
      width: 95,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 6),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          // color: AppColors.tertiary.withOpacity(0.1),
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [
              AppColors.tertiary.withOpacity(0.1),
              AppColors.tertiary.withOpacity(0.3),
            ],
          ),
          border: Border.all(
            color: AppColors.tertiary.withOpacity(0.4),
            width: 1,
          ),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              time,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black,
                fontFamily: 'OpenDyslexic',
              ),
            ),
            const SizedBox(height: 6),
            Text(
              prayerName,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.black,
                fontFamily: 'OpenDyslexic',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Small decorative bar used in Latihan Lafal card
class _AudioBar extends StatelessWidget {
  final double height;
  const _AudioBar({this.height = 24});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: height,
      decoration: BoxDecoration(
        color: Color(0xFFFFB74D),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}
