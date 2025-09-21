import 'package:flutter/material.dart';
import '../widgets/tracing_canvas.dart';
import '../widgets/control_buttons.dart';
import '../widgets/mode_toggle.dart';
import '../services/tracing_service.dart';

class HijaiyahTracingDetailPage extends StatefulWidget {
  final String letter;
  final String pronunciation;

  const HijaiyahTracingDetailPage({
    Key? key,
    required this.letter,
    required this.pronunciation,
  }) : super(key: key);

  @override
  _HijaiyahTracingDetailPageState createState() => _HijaiyahTracingDetailPageState();
}

class _HijaiyahTracingDetailPageState extends State<HijaiyahTracingDetailPage> {
  final TracingService _tracingService = TracingService();
  bool isPracticeMode = true;
  final GlobalKey _canvasKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _tracingService.initialize(widget.letter);
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
        child: Stack(
          children: [
            // Main content
            Column(
              children: [
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
                          icon: Icon(Icons.arrow_back, color: Colors.black, size: 20),
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
                ControlButtons(
                  onPlaySound: () => _tracingService.playSound(widget.pronunciation),
                  onCheckTracing: () => _tracingService.checkTracing(widget.letter),
                  tracingService: _tracingService,
                ),
                SizedBox(height: 30),
                Expanded(
                  child: Center(
                    child: StreamBuilder<Map<String, dynamic>>(
                      stream: _tracingService.feedbackStream,
                      builder: (context, snapshot) {
                        if (_canvasKey.currentContext != null) {
                          final RenderBox? renderBox = _canvasKey.currentContext!.findRenderObject() as RenderBox?;
                          if (renderBox != null) {
                            _tracingService.setCanvasSize(renderBox.size);
                          }
                        }

                        return GestureDetector(
                          key: _canvasKey,
                          behavior: HitTestBehavior.opaque,
                          onPanStart: (details) {
                            final RenderBox? renderBox = _canvasKey.currentContext?.findRenderObject() as RenderBox?;
                            if (renderBox == null) return;
                            final Offset localPosition = renderBox.globalToLocal(details.globalPosition);
                            _tracingService.startTracing(localPosition);
                          },
                          onPanUpdate: (details) {
                            final RenderBox? renderBox = _canvasKey.currentContext?.findRenderObject() as RenderBox?;
                            if (renderBox == null) return;
                            final Offset localPosition = renderBox.globalToLocal(details.globalPosition);
                            _tracingService.updateTracing(localPosition);
                            setState(() {});
                          },
                          onPanEnd: (details) {
                            _tracingService.endTracing();
                          },
                          child: TracingCanvas(
                            letter: widget.letter,
                            isPracticeMode: isPracticeMode,
                            allStrokes: _tracingService.allStrokes,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                SizedBox(height: 20),
                ModeToggle(isPracticeMode: isPracticeMode, onToggle: _toggleMode),
                SizedBox(height: 20),
                if (_tracingService.hasStrokes)
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 40),
                    child: SizedBox(
                      width: double.infinity,
                      height: 45,
                      child: ElevatedButton(
                        onPressed: _tracingService.clearTracing,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey[300],
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                        ),
                        child: Text(
                          'Hapus Semua',
                          style: TextStyle(fontSize: 16, color: Colors.black, fontFamily: 'OpenDyslexic', fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ),
                SizedBox(height: 20),
              ],
            ),
            
            // Feedback overlay - positioned separately to avoid UI conflicts
            StreamBuilder<Map<String, dynamic>>(
              stream: _tracingService.feedbackStream,
              builder: (context, snapshot) {
                if (!_tracingService.showFeedback) {
                  return SizedBox.shrink();
                }
                
                return Positioned.fill(
                  child: Container(
                    color: Colors.black26, // Semi-transparent backdrop
                    child: Center(
                      child: Container(
                        margin: EdgeInsets.symmetric(horizontal: 30),
                        padding: EdgeInsets.all(32),
                        constraints: BoxConstraints(
                          maxWidth: 380,
                          maxHeight: 250,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                              offset: Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                color: _tracingService.isCorrect ? 
                                  Color(0xFF4CAF50).withOpacity(0.1) : 
                                  Color(0xFFF44336).withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                _tracingService.isCorrect ? Icons.check_circle : Icons.error,
                                size: 50,
                                color: _tracingService.isCorrect ? Color(0xFF4CAF50) : Color(0xFFF44336),
                              ),
                            ),
                            SizedBox(height: 20),
                            Text(
                              _tracingService.isCorrect ? 'Benar!' : 'Coba Lagi!',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                                fontFamily: 'OpenDyslexic',
                              ),
                            ),
                            if (!_tracingService.isCorrect) ...[

                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}