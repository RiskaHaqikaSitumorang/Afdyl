import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/latihan_service.dart';
import '../widgets/recording_button.dart';
import '../constants/app_colors.dart';

class LatihanKataPage extends StatefulWidget {
  @override
  LatihanKataPageState createState() => LatihanKataPageState();
}

class LatihanKataPageState extends State<LatihanKataPage>
    with TickerProviderStateMixin {
  final LatihanService _latihanService = LatihanService();
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  String _arabicText = '';
  bool _isListening = false;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    print('[LatihanKataPage] 🎬 initState dipanggil');
    _setupAnimations();
    _initializeServices();
  }

  void _setupAnimations() {
    print('[LatihanKataPage] 🎨 Setup animations...');

    _pulseController = AnimationController(
      duration: Duration(milliseconds: 1000),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  Future<void> _initializeServices() async {
    print('[LatihanKataPage] 🚀 Memulai inisialisasi services...');
    await _latihanService.initialize();
    print('[LatihanKataPage] ✅ Services berhasil diinisialisasi');

    await _checkMicrophonePermission();
    print('[LatihanKataPage] ✅ Microphone permission checked');

    _latihanService.statusStream.listen((data) {
      print('[LatihanKataPage] 📨 Status update diterima:');
      print('  - isListening: ${data['isListening']}');
      print('  - isProcessing: ${data['isProcessing']}');
      print(
        '  - arabicText: ${data['arabicText']?.isEmpty ?? true ? "kosong" : "ada (${data['arabicText']?.length} karakter)"}',
      );
      print('  - status: ${data['status']}');

      setState(() {
        _isListening = data['isListening'] ?? false;
        _isProcessing = data['isProcessing'] ?? false;
        _arabicText = data['arabicText'] ?? '';
        if (_isListening) {
          print('[LatihanKataPage] 🎙️  Mulai animasi pulse');
          _pulseController.repeat(reverse: true);
        } else {
          print('[LatihanKataPage] ⏹️  Stop animasi pulse');
          _pulseController.stop();
        }
      });
    });
    print('[LatihanKataPage] 📡 Stream listener terpasang');
  }

  Future<void> _checkMicrophonePermission() async {
    print('[LatihanKataPage] 🎤 Memeriksa microphone permission...');
    PermissionStatus permission = await Permission.microphone.status;
    print('[LatihanKataPage] 📊 Status permission: $permission');

    if (permission.isDenied) {
      print('[LatihanKataPage] ⚠️  Permission denied, meminta izin...');
      permission = await Permission.microphone.request();
      print(
        '[LatihanKataPage] 📊 Status permission setelah request: $permission',
      );
    }
    if (permission.isPermanentlyDenied) {
      print(
        '[LatihanKataPage] ❌ Permission permanently denied, membuka app settings',
      );
      // Tidak menampilkan status, sesuai permintaan hapus teks
      openAppSettings();
    } else if (permission.isGranted) {
      print('[LatihanKataPage] ✅ Microphone permission granted');
    }
  }

  @override
  void dispose() {
    print('[LatihanKataPage] 🔚 dispose() dipanggil');
    _latihanService.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    print(
      '[LatihanKataPage] 🎨 build() dipanggil - listening: $_isListening, processing: $_isProcessing',
    );
    return Scaffold(
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
                    margin: const EdgeInsets.only(top: 8.0),
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
                  Expanded(
                    child: Text(
                      'Latihan Kata',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
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
              child: Align(
                alignment: Alignment.center,
                child:
                    _arabicText.isNotEmpty && !_isListening
                        ? Padding(
                          padding: EdgeInsets.symmetric(horizontal: 20),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Label testing mode
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.orange.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: Colors.orange,
                                    width: 2,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.science,
                                      color: Colors.orange,
                                      size: 20,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      'MODE TESTING',
                                      style: TextStyle(
                                        color: Colors.orange,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        fontFamily: 'OpenDyslexic',
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(height: 20),
                              // Hasil audio
                              Container(
                                width: double.infinity,
                                padding: EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(15),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 10,
                                      offset: Offset(0, 5),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  children: [
                                    Text(
                                      'Audio Terdeteksi:',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[600],
                                        fontFamily: 'OpenDyslexic',
                                      ),
                                    ),
                                    SizedBox(height: 12),
                                    Text(
                                      _arabicText,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black,
                                        fontFamily: 'OpenDyslexic',
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        )
                        : SizedBox.shrink(),
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: EdgeInsets.only(bottom: 40),
                child: RecordingButton(
                  isListening: _isListening,
                  isProcessing: _isProcessing,
                  pulseAnimation: _pulseAnimation,
                  onTap: () {
                    print('[LatihanKataPage] 👆 onTap callback dipanggil');
                    if (_isListening) {
                      print('[LatihanKataPage] 🛑 Memanggil stopListening...');
                      _latihanService.stopListening();
                    } else {
                      print(
                        '[LatihanKataPage] ▶️  Memanggil startListening...',
                      );
                      _latihanService.startListening();
                    }
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
