import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../widgets/tracing_canvas.dart';
import '../widgets/control_buttons.dart';
import '../widgets/mode_toggle.dart';
import '../services/tracing_service.dart';

class HijaiyahTracingDetailPage extends StatefulWidget {
  final String letter;
  final String pronunciation;

  HijaiyahTracingDetailPage({
    required this.letter,
    required this.pronunciation,
  });

  @override
  _HijaiyahTracingDetailPageState createState() =>
      _HijaiyahTracingDetailPageState();
}

class _HijaiyahTracingDetailPageState extends State<HijaiyahTracingDetailPage> {
  final TracingService _tracingService = TracingService();
  bool isPracticeMode = true;

  @override
  void initState() {
    super.initState();
    _tracingService.initialize();
  }

  @override
  void dispose() {
    _tracingService.dispose();
    super.dispose();
  }

  void _toggleMode() {
    setState(() {
      isPracticeMode = !isPracticeMode;
      _tracingService.clearTracing();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F5DC),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Color(0xFFB8D4B8),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: Icon(
                        Icons.arrow_back,
                        color: Colors.black, // Corrected from Models.black
                        size: 20,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'Tracing Hijaiyah',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 20,
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
            SizedBox(height: 20),
            // Letter and Pronunciation
            Text(
              '(${widget.pronunciation})',
              style: TextStyle(
                fontSize: 18,
                color: Colors.black,
                fontFamily: 'OpenDyslexic',
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              widget.letter,
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            SizedBox(height: 20),
            // Control Buttons
            ControlButtons(
              onPlaySound: _tracingService.playSound,
              onCheckTracing: _tracingService.checkTracing,
              showFeedback: _tracingService.showFeedback,
              isCorrect: _tracingService.isCorrect,
              isProcessing: _tracingService.isProcessing,
            ),
            SizedBox(height: 30),
            // Tracing Canvas
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: TracingCanvas(
                  letter: widget.letter,
                  isPracticeMode: isPracticeMode,
                  tracingPoints: _tracingService.tracingPoints,
                  onPanStart: _tracingService.startTracing,
                  onPanUpdate: _tracingService.updateTracing,
                  onPanEnd: _tracingService.endTracing,
                ),
              ),
            ),
            SizedBox(height: 20),
            // Mode Toggle
            ModeToggle(
              isPracticeMode: isPracticeMode,
              onToggle: _toggleMode,
            ),
            SizedBox(height: 20),
            // Clear Button
            if (_tracingService.tracingPoints.isNotEmpty)
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 40),
                child: SizedBox(
                  width: double.infinity,
                  height: 45,
                  child: ElevatedButton(
                    onPressed: _tracingService.clearTracing,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[300],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                    child: Text(
                      'Hapus',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.black,
                        fontFamily: 'OpenDyslexic',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}