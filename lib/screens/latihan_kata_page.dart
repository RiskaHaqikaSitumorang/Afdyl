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
    _setupAnimations();
    _initializeServices();
  }

  void _setupAnimations() {
    _pulseController = AnimationController(
      duration: Duration(milliseconds: 1000),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  Future<void> _initializeServices() async {
    await _latihanService.initialize();
    await _checkMicrophonePermission();
    _latihanService.statusStream.listen((data) {
      setState(() {
        _isListening = data['isListening'] ?? false;
        _isProcessing = data['isProcessing'] ?? false;
        _arabicText = data['arabicText'] ?? '';
        if (_isListening) {
          _pulseController.repeat(reverse: true);
        } else {
          _pulseController.stop();
        }
      });
    });
  }

  Future<void> _checkMicrophonePermission() async {
    PermissionStatus permission = await Permission.microphone.status;
    if (permission.isDenied) {
      permission = await Permission.microphone.request();
    }
    if (permission.isPermanentlyDenied) {
      // Tidak menampilkan status, sesuai permintaan hapus teks
      openAppSettings();
    }
  }

  @override
  void dispose() {
    _latihanService.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                          child: Container(
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
                            child: TextField(
                              controller: TextEditingController(
                                text: _arabicText,
                              ),
                              readOnly: true,
                              cursorColor:
                                  Colors.black, // Set cursor color to black
                              textAlign: TextAlign.center,
                              textDirection: TextDirection.rtl,
                              style: TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                                fontFamily: 'OpenDyslexic',
                              ),
                              decoration: InputDecoration(
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 15,
                                ),
                                suffixIcon: Icon(
                                  Icons.volume_up,
                                  color: Colors.grey[600],
                                  size: 24,
                                ),
                              ),
                            ),
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
                  onTap:
                      _isListening
                          ? _latihanService.stopListening
                          : _latihanService.startListening,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
