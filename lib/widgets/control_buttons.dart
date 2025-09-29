import 'package:afdyl/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Tambah untuk HapticFeedback
import '../services/tracing_service.dart';

class ControlButtons extends StatefulWidget {
  final VoidCallback onPlaySound;
  final VoidCallback onCheckTracing;
  final TracingService tracingService;

  const ControlButtons({
    Key? key,
    required this.onPlaySound,
    required this.onCheckTracing,
    required this.tracingService,
  }) : super(key: key);

  @override
  _ControlButtonsState createState() => _ControlButtonsState();
}

class _ControlButtonsState extends State<ControlButtons> {
  bool showFeedback = false;
  bool isCorrect = false;
  bool isProcessing = false;

  @override
  void initState() {
    super.initState();
    widget.tracingService.feedbackStream.listen((data) {
      if (mounted) {
        setState(() {
          showFeedback = data['showFeedback'] ?? false;
          isCorrect = data['isCorrect'] ?? false;
          isProcessing = data['processing'] ?? false;
        });
      }
    });
  }

  void _handlePlayPress() {
    HapticFeedback.lightImpact(); // Pastikan import ada
    widget.onPlaySound();
  }

  void _handleCheckPress() {
    if (!isProcessing && widget.tracingService.hasStrokes) {
      HapticFeedback.mediumImpact();
      widget.onCheckTracing();
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final horizontalPadding = screenWidth > 400 ? 40.0 : 20.0;
    final hasTracing = widget.tracingService.hasStrokes;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Play Sound Button
          GestureDetector(
            onTap: _handlePlayPress,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: AppColors.tertiary.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.volume_up,
                    color: AppColors.tertiary,
                    size: 28,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Dengar',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.tertiary,
                    fontFamily: 'OpenDyslexic',
                  ),
                ),
              ],
            ),
          ),

          // Check Tracing Button
          Opacity(
            opacity: hasTracing ? 1.0 : 0.5,
            child: GestureDetector(
              onTap: hasTracing ? _handleCheckPress : null,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color:
                          showFeedback
                              ? (isCorrect ? Colors.green : Colors.red)
                              : (hasTracing
                                  ? Color(0xFFB8D4B8).withOpacity(0.6)
                                  : Colors.grey[300]),
                      shape: BoxShape.circle,
                    ),
                    child:
                        isProcessing
                            ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.black,
                                ),
                              ),
                            )
                            : Icon(
                              showFeedback
                                  ? (isCorrect ? Icons.check : Icons.error)
                                  : Icons.check_circle,
                              color:
                                  hasTracing
                                      ? Color.fromARGB(255, 71, 108, 71)
                                      : Colors.grey[600],
                              size: 28,
                            ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    isProcessing
                        ? 'Cek...'
                        : (showFeedback
                            ? (isCorrect ? 'Benar!' : 'Salah!')
                            : 'Periksa'),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color:
                          hasTracing
                              ? (showFeedback
                                  ? (isCorrect
                                      ? Color.fromARGB(255, 71, 108, 71)
                                      : Colors.red)
                                  : Color.fromARGB(255, 71, 108, 71))
                              : Colors.grey[600],
                      fontFamily: 'OpenDyslexic',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
