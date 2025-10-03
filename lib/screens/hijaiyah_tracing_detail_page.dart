import 'package:flutter/material.dart';
import '../widgets/svg_tracing_canvas.dart';
import '../services/svg_tracing_service.dart';
import '../constants/app_colors.dart';

class HijaiyahTracingDetailPage extends StatefulWidget {
  final String letter;
  final String pronunciation;

  const HijaiyahTracingDetailPage({
    Key? key,
    required this.letter,
    required this.pronunciation,
  }) : super(key: key);

  @override
  State<HijaiyahTracingDetailPage> createState() =>
      _HijaiyahTracingDetailPageState();
}

class _HijaiyahTracingDetailPageState extends State<HijaiyahTracingDetailPage> {
  final SVGTracingService _tracingService = SVGTracingService();
  final ScrollController _scrollController = ScrollController();
  bool isLetterCompleted = false;

  // State untuk menyimpan feedback terakhir
  Map<String, dynamic>? _lastFeedback;

  @override
  void initState() {
    super.initState();

    // Listen to tracing updates for completion status
    _tracingService.updateStream.listen((data) {
      if (data.containsKey('letterCompleted') &&
          data['letterCompleted'] == true) {
        setState(() {
          isLetterCompleted = true;
          _lastFeedback = data; // Simpan feedback
        });
        _scrollToBottom();
      }
      if (data.containsKey('tracingReset')) {
        setState(() {
          isLetterCompleted = false;
          _lastFeedback = null; // Clear feedback saat reset
        });
      }

      // Auto scroll to bottom when feedback appears
      if (data.containsKey('strokeCompleted') ||
          data.containsKey('strokeInvalid') ||
          data.containsKey('pathInvalid')) {
        setState(() {
          _lastFeedback = data; // Simpan feedback
        });
        _scrollToBottom();
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _tracingService.initializeLetter(widget.letter);
    });
  }

  void _scrollToBottom() {
    // Delay to ensure widget is built
    Future.delayed(Duration(milliseconds: 300), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 500),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _tracingService.dispose();
    super.dispose();
  }

  Widget _buildFeedbackWidget() {
    // Jika tidak ada feedback, return placeholder
    if (_lastFeedback == null) {
      return SizedBox(height: 80);
    }

    final data = _lastFeedback!;
    String message = data['message'] ?? '';

    // Letter Completed
    if (data.containsKey('letterCompleted') &&
        data['letterCompleted'] == true) {
      return AnimatedContainer(
        duration: Duration(milliseconds: 500),
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.green[50],
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.green[300]!, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.green.withOpacity(0.2),
              blurRadius: 10,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(Icons.celebration, color: Colors.green[600], size: 40),
            SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Luar Biasa! 🎉',
                    style: TextStyle(
                      color: Colors.green[700],
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Huruf ${widget.letter} berhasil diselesaikan!',
                    style: TextStyle(
                      color: Colors.green[600],
                      fontWeight: FontWeight.w500,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }
    // Stroke Completed
    else if (data.containsKey('strokeCompleted') &&
        data['strokeCompleted'] == true) {
      final current = data['currentStrokeIndex'] ?? 0;
      final total = data['totalStrokes'] ?? 0;
      return Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.blue[50],
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.blue[300]!, width: 2),
        ),
        child: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.blue[600], size: 35),
            SizedBox(width: 15),
            Expanded(
              child: Text(
                'Bagus! Lanjut ke garis ${current + 1} dari $total',
                style: TextStyle(
                  color: Colors.blue[700],
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      );
    }
    // Stroke Invalid
    else if (data.containsKey('strokeInvalid') &&
        data['strokeInvalid'] == true) {
      return Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.orange[50],
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.orange[300]!, width: 2),
        ),
        child: Row(
          children: [
            Icon(Icons.refresh, color: Colors.orange[600], size: 35),
            SizedBox(width: 15),
            Expanded(
              child: Text(
                message.isNotEmpty
                    ? message
                    : 'Coba lagi, ikuti jalur garis putus-putus.',
                style: TextStyle(
                  color: Colors.orange[700],
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      );
    }
    // Path Invalid
    else if (data.containsKey('pathInvalid') && data['pathInvalid'] == true) {
      return Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.red[50],
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.red[300]!, width: 2),
        ),
        child: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red[600], size: 35),
            SizedBox(width: 15),
            Expanded(
              child: Text(
                message.isNotEmpty
                    ? message
                    : 'Coba lagi! Ikuti jalur lebih hati-hati.',
                style: TextStyle(
                  color: Colors.red[700],
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return SizedBox(height: 80);
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
            "Jejak Hijaiyah",
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
        child: SingleChildScrollView(
          controller: _scrollController,
          physics: AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Letter Display
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 10,
                        offset: Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      AnimatedContainer(
                        duration: Duration(milliseconds: 500),
                        child: Text(
                          widget.letter,
                          style: TextStyle(
                            fontSize: 80,
                            fontFamily: 'Maqroo',
                            fontWeight: FontWeight.bold,
                            color:
                                isLetterCompleted
                                    ? Colors.green[600]
                                    : AppColors.primary,
                          ),
                        ),
                      ),
                      SizedBox(height: 10),
                      Text(
                        widget.pronunciation,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[700],
                        ),
                      ),
                      if (isLetterCompleted) ...[
                        SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.star, color: Colors.amber, size: 20),
                            SizedBox(width: 5),
                            Text(
                              'Completed!',
                              style: TextStyle(
                                color: Colors.green[600],
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            SizedBox(width: 5),
                            Icon(Icons.star, color: Colors.amber, size: 20),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),

                SizedBox(height: 20),

                // Instructions
                Container(
                  padding: EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: Colors.blue[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue[600]),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Trace semua bagian huruf (termasuk titik-titik) lalu tekan tombol "Cek".',
                          style: TextStyle(
                            color: Colors.blue[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 20),

                // Tracing Canvas - FIXED SIZE
                Center(
                  child: AnimatedContainer(
                    duration: Duration(milliseconds: 500),
                    width: 400, // Fixed width
                    height: 400, // Fixed height
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color:
                              isLetterCompleted
                                  ? Colors.green.withOpacity(0.3)
                                  : Colors.black12,
                          blurRadius: isLetterCompleted ? 15 : 10,
                          offset: Offset(0, 5),
                        ),
                      ],
                    ),
                    child: SVGTracingCanvas(
                      letter: widget.letter,
                      tracingService: _tracingService,
                    ),
                  ),
                ),

                SizedBox(height: 20),

                // Control Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Tombol Reset
                    ElevatedButton.icon(
                      onPressed: () {
                        _tracingService.resetTracing();
                        setState(() {
                          isLetterCompleted = false;
                          _lastFeedback = null; // Clear feedback
                        });
                        // Scroll to top
                        if (_scrollController.hasClients) {
                          _scrollController.animateTo(
                            0,
                            duration: Duration(milliseconds: 500),
                            curve: Curves.easeOut,
                          );
                        }
                      },
                      icon: Icon(Icons.refresh),
                      label: Text('Reset'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[600],
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                      ),
                    ),

                    // Tombol Sound
                    ElevatedButton.icon(
                      onPressed: () => _tracingService.playSound(widget.letter),
                      icon: Icon(Icons.volume_up),
                      label: Text('Sound'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                      ),
                    ),

                    // Tombol Cek - untuk validasi tracing
                    ElevatedButton.icon(
                      onPressed: () => _tracingService.validateTracing(),
                      icon: Icon(Icons.check_circle),
                      label: Text('Cek'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green[600],
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(
                          horizontal: 25,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 20),

                // Progress Feedback - PERSISTENT (tidak hilang sampai reset)
                _buildFeedbackWidget(),

                SizedBox(height: 20), // Extra space at bottom
              ],
            ),
          ),
        ),
      ),
    );
  }
}
