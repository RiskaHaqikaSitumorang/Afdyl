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
    if (!isProcessing) {
      HapticFeedback.mediumImpact(); // Pastikan import ada
      widget.onCheckTracing();
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final horizontalPadding = screenWidth > 400 ? 40.0 : 20.0;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          GestureDetector(
            onTap: _handlePlayPress,
            child: Semantics(
              label: 'Play pronunciation sound',
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Color(0xFFB8D4B8),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Color.fromRGBO(0, 0, 0, 0.1), // Ganti withOpacity
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: IconButton(
                  icon: Icon(
                    Icons.volume_up,
                    color: Colors.black,
                    size: 28,
                  ),
                  onPressed: null,
                  tooltip: 'Play Sound',
                ),
              ),
            ),
          ),
          GestureDetector(
            onTap: _handleCheckPress,
            child: Semantics(
              label: isProcessing
                  ? 'Processing tracing'
                  : showFeedback
                      ? (isCorrect ? 'Tracing correct' : 'Tracing incorrect')
                      : 'Check tracing',
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: showFeedback
                          ? (isCorrect ? Colors.green : Colors.red)
                          : Color(0xFFB8D4B8),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Color.fromRGBO(0, 0, 0, 0.1), // Ganti withOpacity
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                  if (isProcessing)
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                      ),
                    )
                  else
                    IconButton(
                      icon: Icon(
                        showFeedback
                            ? (isCorrect ? Icons.check : Icons.error)
                            : Icons.check_circle,
                        color: Colors.black,
                        size: 28,
                      ),
                      onPressed: null,
                      tooltip: isProcessing ? 'Processing...' : 'Check Tracing',
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