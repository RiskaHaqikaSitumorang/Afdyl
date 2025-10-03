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
      }
      if (data.containsKey('tracingReset')) {
        setState(() {
          isLetterCompleted = false;
          _lastFeedback = null; // Clear feedback saat reset
        });
      }

      // Update feedback
      if (data.containsKey('strokeCompleted') ||
          data.containsKey('strokeInvalid') ||
          data.containsKey('pathInvalid')) {
        setState(() {
          _lastFeedback = data; // Simpan feedback
        });
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _tracingService.initializeLetter(widget.letter);
    });
  }

  @override
  void dispose() {
    _tracingService.dispose();
    super.dispose();
  }

  Widget _buildFeedbackWidget() {
    // Jika tidak ada feedback, return empty
    if (_lastFeedback == null) {
      return SizedBox.shrink();
    }

    final data = _lastFeedback!;
    String message = data['message'] ?? '';

    // Letter Completed
    if (data.containsKey('letterCompleted') &&
        data['letterCompleted'] == true) {
      return Container(
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.green[50],
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.green[300]!, width: 1.5),
        ),
        child: Row(
          children: [
            Icon(Icons.celebration, color: Colors.green[600], size: 28),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Luar Biasa! 🎉 Huruf ${widget.letter} selesai!',
                style: TextStyle(
                  color: Colors.green[700],
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
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
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.blue[50],
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.blue[300]!, width: 1.5),
        ),
        child: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.blue[600], size: 24),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Bagus! Lanjut ke garis ${current + 1} dari $total',
                style: TextStyle(
                  color: Colors.blue[700],
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
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
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.orange[50],
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.orange[300]!, width: 1.5),
        ),
        child: Row(
          children: [
            Icon(Icons.refresh, color: Colors.orange[600], size: 24),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                message.isNotEmpty ? message : 'Coba lagi, ikuti jalur garis.',
                style: TextStyle(
                  color: Colors.orange[700],
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
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
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.red[50],
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.red[300]!, width: 1.5),
        ),
        child: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red[600], size: 24),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                message.isNotEmpty
                    ? message
                    : 'Coba lagi! Ikuti jalur lebih hati-hati.',
                style: TextStyle(
                  color: Colors.red[700],
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return SizedBox.shrink();
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
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 16.0,
            vertical: 8.0,
          ), // Reduced padding
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Letter Display - COMPACT VERSION
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ), // Reduced padding
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Letter
                    Text(
                      widget.letter,
                      style: TextStyle(
                        fontSize: 50, // Reduced from 80
                        fontFamily: 'Maqroo',
                        fontWeight: FontWeight.bold,
                        color:
                            isLetterCompleted
                                ? Colors.green[600]
                                : AppColors.softBlack,
                      ),
                    ),
                    SizedBox(width: 12),
                    // Pronunciation
                    Text(
                      widget.pronunciation,
                      style: TextStyle(
                        fontSize: 18, // Reduced from 24
                        fontWeight: FontWeight.w600,
                        color: AppColors.softBlack,
                      ),
                    ),
                    // Completion icon (only when completed)
                    if (isLetterCompleted) ...[
                      SizedBox(width: 8),
                      Icon(
                        Icons.check_circle,
                        color: Colors.green[600],
                        size: 22,
                      ),
                    ],
                  ],
                ),
              ),

              // Instructions - COMPACT
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ), // Reduced padding
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue[600], size: 18),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Trace semua bagian huruf (termasuk titik-titik) lalu tekan tombol "Cek".',
                        style: TextStyle(
                          color: Colors.blue[700],
                          fontWeight: FontWeight.w500,
                          fontSize: 13, // Smaller text
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 16),
              Row(
                children: [
                  // Tombol Reset
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        _tracingService.resetTracing();
                        setState(() {
                          isLetterCompleted = false;
                          _lastFeedback = null;
                        });
                      },
                      icon: Icon(Icons.refresh, size: 18),
                      label: Text('Reset', style: TextStyle(fontSize: 13)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[600],
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 8),

                  // Tombol Sound
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _tracingService.playSound(widget.letter),
                      icon: Icon(Icons.volume_up, size: 18),
                      label: Text('Sound', style: TextStyle(fontSize: 13)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.tertiary,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              SizedBox(height: 16),

              // Combined Canvas and Feedback in Expanded
              Expanded(
                child: Column(
                  children: [
                    // Tracing Canvas - FIXED SIZE (sedikit lebih kecil)
                    Center(
                      child: Container(
                        width: double.infinity, // Full screen width
                        height: 360, // Reduced from 400
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [
                            BoxShadow(
                              color:
                                  isLetterCompleted
                                      ? Colors.green.withOpacity(0.3)
                                      : Colors.black12,
                              blurRadius: isLetterCompleted ? 12 : 8,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: SVGTracingCanvas(
                          letter: widget.letter,
                          tracingService: _tracingService,
                        ),
                      ),
                    ),

                    // Spacer untuk mendorong konten ke bawah
                    Spacer(),

                    // Content di bagian bawah
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Control Buttons - COMPACT
                        Row(
                          children: [
                            // Tombol Cek
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed:
                                    () => _tracingService.validateTracing(),
                                icon: Icon(Icons.check_circle, size: 18),
                                label: Text(
                                  'Cek',
                                  style: TextStyle(fontSize: 16),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green[600],
                                  foregroundColor: Colors.white,
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),

                        SizedBox(height: 10), // Reduced from 20
                        // Progress Feedback - COMPACT & PERSISTENT
                        _buildFeedbackWidget(),
                        SizedBox(height: 16), // Padding dari bawah screen
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
