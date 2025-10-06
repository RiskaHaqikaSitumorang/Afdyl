// lib/screens/qibla_page.dart
import 'package:afdyl/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:math' as math;
import '../services/qibla_service.dart';
import '../widgets/qibla_widgets.dart';

class QiblaPage extends StatefulWidget {
  @override
  _QiblaPageState createState() => _QiblaPageState();
}

class _QiblaPageState extends State<QiblaPage> with TickerProviderStateMixin {
  final QiblaService _qiblaService = QiblaService();
  late AnimationController _compassController;
  late AnimationController _pulseController;
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _compassController = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );
    _pulseController = AnimationController(
      duration: Duration(milliseconds: 1500),
      vsync: this,
    );
    _pulseController.repeat();
    _showInitialBubble(); // Menampilkan bubble text saat masuk
    _initializeQibla();
  }

  @override
  void dispose() {
    _compassController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _initializeQibla() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });
    try {
      await _qiblaService.initializeQibla();
      _qiblaService.startCompassListening(() => setState(() {}));
      setState(() {
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
        isLoading = false;
      });
    }
  }

  void _showInitialBubble() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Jauhkan perangkat dari benda logam atau elektronik untuk akurasi terbaik.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.black87,
                fontFamily: 'OpenDyslexic',
              ),
            ),
            backgroundColor: Colors.white.withOpacity(0.9),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            margin: EdgeInsets.all(16),
            duration: Duration(seconds: 5), // Muncul selama 5 detik
          ),
        );
      }
    });
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
        title: Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Text(
            "Qibla",
            style: const TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.w600,
              fontSize: 18,
              fontFamily: 'OpenDyslexic',
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: Column(children: [Expanded(child: _buildContent())]),
      ),
    );
  }

  Widget _buildContent() {
    if (isLoading) return _buildLoadingState();
    if (errorMessage != null) return _buildErrorState();
    return _buildQiblaCompass();
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFD4C785)),
          ),
          SizedBox(height: 20),
          Text(
            'Mencari arah Qibla...',
            style: TextStyle(
              fontSize: 18,
              color: Colors.black,
              fontFamily: 'OpenDyslexic',
            ),
          ),
          SizedBox(height: 10),
          Text(
            'Pastikan GPS dan sensor perangkat aktif\nJauhkan dari benda logam.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.black54,
              fontFamily: 'OpenDyslexic',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 80, color: Colors.red[300]),
            SizedBox(height: 20),
            Text(
              'Tidak dapat menentukan arah Qibla',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.black,
                fontFamily: 'OpenDyslexic',
              ),
            ),
            SizedBox(height: 16),
            Text(
              errorMessage!,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.black87,
                fontFamily: 'OpenDyslexic',
                height: 1.5,
              ),
            ),
            SizedBox(height: 30),
            ElevatedButton(
              onPressed: _initializeQibla,
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFFD4C785),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
                padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              ),
              child: Text(
                'Coba Lagi',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black,
                  fontFamily: 'OpenDyslexic',
                ),
              ),
            ),
            SizedBox(height: 20),
            if (errorMessage!.contains('permission'))
              ElevatedButton(
                onPressed: () async => await openAppSettings(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[300],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                ),
                child: Text(
                  'Buka Pengaturan',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black,
                    fontFamily: 'OpenDyslexic',
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildQiblaCompass() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (!_qiblaService.hasSensorSupport) ...[SizedBox(height: 10)],
          SizedBox(
            width: 320, // Diameter diperbesar dari 280 ke 320
            height:
                320, // Sesuaikan tinggi dengan lebar untuk lingkaran sempurna
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 320,
                  height: 320,
                  decoration: BoxDecoration(
                    color: Color(0xFFF5F5DC),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.black, width: 3),
                  ),
                ),
                buildDirectionLabels(),
                if (_qiblaService.qiblaDirection != null)
                  AnimatedBuilder(
                    animation: _compassController,
                    builder: (context, child) {
                      final angle =
                          _qiblaService.getQiblaAngle() * (math.pi / 180);
                      return Transform.rotate(
                        angle: angle,
                        child: SizedBox(
                          width:
                              240, // Sesuaikan ukuran panah agar proporsional
                          height: 240, // Sesuaikan tinggi dengan lebar
                          child: CustomPaint(painter: QiblaArrowPainter()),
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
          SizedBox(height: 40),
          Image.asset(
            'assets/images/Kaaba.png', // Pastikan path sesuai
            width: 80,
            height: 80,
            fit: BoxFit.cover,
          ),
        ],
      ),
    );
  }
}
