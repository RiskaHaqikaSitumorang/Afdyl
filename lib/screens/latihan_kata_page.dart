import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/latihan_service.dart';
import '../services/arabic_tts_service.dart';
import '../widgets/recording_button.dart';
import '../constants/app_colors.dart';

class LatihanKataPage extends StatefulWidget {
  @override
  LatihanKataPageState createState() => LatihanKataPageState();
}

class LatihanKataPageState extends State<LatihanKataPage>
    with TickerProviderStateMixin {
  final LatihanService _latihanService = LatihanService();
  final ArabicTTSService _ttsService = ArabicTTSService();
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  String _arabicText = '';
  String _currentStatus = '';
  bool _isListening = false;
  bool _isProcessing = false;
  bool _isSpeaking = false;

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
    await _ttsService.initialize();
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
        _currentStatus = data['status'] ?? '';
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
    _ttsService.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _toggleTTS() async {
    if (_arabicText.isEmpty) return;

    if (_ttsService.isSpeaking) {
      await _ttsService.stop();
      setState(() {
        _isSpeaking = false;
      });
    } else {
      setState(() {
        _isSpeaking = true;
      });
      await _ttsService.speak(_arabicText);
      // Will automatically set _isSpeaking to false when completed
      setState(() {
        _isSpeaking = false;
      });
    }
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
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Tips untuk user
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.amber[50],
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.amber[200]!),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.lightbulb_outline,
                            color: Colors.amber[700],
                            size: 20,
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Tips: Tekan tombol rekam, tunggu 1-2 detik, lalu bacalah ayat dengan jelas. Pastikan di tempat yang cukup tenang.',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.amber[900],
                                fontFamily: 'OpenDyslexic',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 20),

                    // Status text with better UI
                    if (_currentStatus.isNotEmpty)
                      Container(
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color:
                              _currentStatus.contains('Error') ||
                                      _currentStatus.contains('Timeout') ||
                                      _currentStatus.contains('Tidak ada suara')
                                  ? Colors.red[50]
                                  : Colors.blue[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color:
                                _currentStatus.contains('Error') ||
                                        _currentStatus.contains('Timeout') ||
                                        _currentStatus.contains(
                                          'Tidak ada suara',
                                        )
                                    ? Colors.red[200]!
                                    : Colors.blue[200]!,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _currentStatus.contains('Error') ||
                                      _currentStatus.contains('Timeout') ||
                                      _currentStatus.contains('Tidak ada suara')
                                  ? Icons.error_outline
                                  : Icons.info_outline,
                              color:
                                  _currentStatus.contains('Error') ||
                                          _currentStatus.contains('Timeout') ||
                                          _currentStatus.contains(
                                            'Tidak ada suara',
                                          )
                                      ? Colors.red[700]
                                      : Colors.blue[700],
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _currentStatus,
                                style: TextStyle(
                                  color:
                                      _currentStatus.contains('Error') ||
                                              _currentStatus.contains(
                                                'Timeout',
                                              ) ||
                                              _currentStatus.contains(
                                                'Tidak ada suara',
                                              )
                                          ? Colors.red[700]
                                          : Colors.blue[700],
                                  fontWeight: FontWeight.w500,
                                  fontFamily: 'OpenDyslexic',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    SizedBox(height: 20),

                    // Hasil audio (jika ada)
                    if (_arabicText.isNotEmpty && !_isListening) ...[
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
                              'Ayat dari Audio Anda:',
                              style: TextStyle(
                                fontSize: 14,
                                color: AppColors.softBlack,
                                fontFamily: 'OpenDyslexic',
                              ),
                            ),
                            SizedBox(height: 12),
                            Text(
                              _arabicText,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 24,
                                color: Colors.black,
                                fontFamily: 'Maqroo',
                              ),
                            ),
                            SizedBox(height: 16),
                            // TTS Button
                            ElevatedButton.icon(
                              onPressed: _toggleTTS,
                              icon: Icon(
                                _isSpeaking ? Icons.stop : Icons.volume_up,
                                color: Colors.white,
                              ),
                              label: Text(
                                _isSpeaking ? 'Hentikan' : 'Dengarkan',
                                style: TextStyle(
                                  fontFamily: 'OpenDyslexic',
                                  color: Colors.white,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    _isSpeaking
                                        ? Colors.red
                                        : AppColors.tertiary,
                                padding: EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
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
