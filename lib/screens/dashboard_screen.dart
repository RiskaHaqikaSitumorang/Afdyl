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

class DashboardScreen extends StatefulWidget {
  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String currentTime =
      "${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')}";
  String prayerTime = "Memuat jadwal sholat...";
  String lastRead = "Q.S Al-Fatihah";
  String location = "Mendapatkan lokasi...";
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _startTimeUpdate();
    _getCurrentLocation();
  }

  void _startTimeUpdate() {
    _updateTime();
    const Duration updateInterval = Duration(minutes: 1);
    _timer = Timer.periodic(updateInterval, (timer) {
      if (mounted) {
        setState(() {
          _updateTime();
        });
      }
    });
  }

  void _updateTime() {
    final now = DateTime.now();
    currentTime =
        "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";
  }

  Future<void> _getCurrentLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            location = "Izin lokasi ditolak";
          });
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        setState(() {
          location = "Izin lokasi permanen ditolak, aktifkan di pengaturan";
        });
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 10),
      );
      await _getPlaceNameFromCoordinates(position.latitude, position.longitude);
      await _fetchPrayerTimes(position.latitude, position.longitude);
    } catch (e) {
      setState(() {
        location = "Gagal mendapatkan lokasi: $e";
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

  Future<void> _fetchPrayerTimes(double latitude, double longitude) async {
    try {
      final response = await http.get(
        Uri.parse(
          'http://api.aladhan.com/v1/timingsByLatLng?latitude=$latitude&longitude=$longitude&method=2',
        ),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final timings = data['data']['timings'];
        final now = DateTime.now();
        final currentHour = now.hour;
        String nextPrayer = "Tidak ada data";

        if (currentHour < int.parse(timings['Fajr'].split(':')[0])) {
          nextPrayer = "Fajr: ${timings['Fajr']}";
        } else if (currentHour < int.parse(timings['Dhuhr'].split(':')[0])) {
          nextPrayer = "Dhuhr: ${timings['Dhuhr']}";
        } else if (currentHour < int.parse(timings['Asr'].split(':')[0])) {
          nextPrayer = "Asr: ${timings['Asr']}";
        } else if (currentHour < int.parse(timings['Maghrib'].split(':')[0])) {
          nextPrayer = "Maghrib: ${timings['Maghrib']}";
        } else if (currentHour < int.parse(timings['Isha'].split(':')[0])) {
          nextPrayer = "Isha: ${timings['Isha']}";
        } else {
          nextPrayer = "Fajr: ${timings['Fajr']} (besok)";
        }

        setState(() {
          prayerTime = "Sekarang waktu $nextPrayer";
        });
      } else {
        setState(() {
          prayerTime = "Gagal memuat jadwal sholat";
        });
      }
    } catch (e) {
      setState(() {
        prayerTime = "Error: $e";
      });
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
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
                                    color: Colors.white.withOpacity(0.3),
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
                                    color: Colors.white.withOpacity(0.3),
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
                              Icon(
                                Icons.access_time,
                                color: Colors.red[600],
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                prayerTime,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: AppColors.blackPrimary.withOpacity(
                                    0.6,
                                  ),
                                  fontFamily: 'OpenDyslexic',
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Image.asset(
                                'assets/images/ic_point.png',
                                width: 24,
                                height: 24,
                                fit: BoxFit.contain,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                location,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: AppColors.blackPrimary.withOpacity(
                                    0.6,
                                  ),
                                  fontFamily: 'OpenDyslexic',
                                ),
                              ),
                            ],
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
                offset: const Offset(0, -32), // Move up to overlap with header
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
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
                          width: 30,
                          height: 30,
                          fit: BoxFit.contain,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                'Terakhir dibaca',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppColors.textSecondary,
                                  fontFamily: 'OpenDyslexic',
                                ),
                              ),
                              Flexible(
                                child: Text(
                                  lastRead,
                                  textAlign: TextAlign.right,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                    fontFamily: 'OpenDyslexic',
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // const SizedBox(height: 10), // Reduced spacing since card overlaps
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.0),
                child: Text(
                  'Aktivitas untuk anda',
                  style: TextStyle(
                    fontSize: 20,
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
                              Navigator.pushNamed(context, AppRoutes.quran);
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildActivityCard(
                            imagePath: 'assets/images/ic_text_bacaan.png',
                            title: 'Tebak Hijaiyah',
                            backgroundColor: AppColors.yellow,
                            onTap: () {
                              // Navigate to Tebak Hijaiyah page
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Menuju halaman Tebak Hijaiyah',
                                  ),
                                ),
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
                            imagePath: 'assets/images/ic_hijaiyah.png',
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
                            imagePath: 'assets/images/ic_sound_wave.png',
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
              const SizedBox(height: 30),
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
          color: backgroundColor,
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
