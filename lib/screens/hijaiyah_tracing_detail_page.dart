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

  @override
  void initState() {
    super.initState();

    // Listen to tracing updates for completion status
    _tracingService.updateStream.listen((data) {
      if (data.containsKey('letterCompleted') &&
          data['letterCompleted'] == true) {
        setState(() {
          isLetterCompleted = true;
        });
      }
      if (data.containsKey('tracingReset')) {
        setState(() {
          isLetterCompleted = false;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black,
        title: Text(
          'Trace ${widget.letter}',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
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

              SizedBox(height: 30),

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

              // Tracing Canvas
              Expanded(
                child: Center(
                  child: AnimatedContainer(
                    duration: Duration(milliseconds: 500),
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
              ),

              SizedBox(height: 20),

              // Control Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
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

                  // Tombol Reset
                  ElevatedButton.icon(
                    onPressed: () {
                      _tracingService.resetTracing();
                      setState(() {
                        isLetterCompleted = false;
                      });
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
                ],
              ),

              SizedBox(height: 20),

              // Progress Feedback - SVG Version
              StreamBuilder<Map<String, dynamic>>(
                stream: _tracingService.updateStream,
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return SizedBox.shrink();
                  }

                  if (snapshot.hasData) {
                    final data = snapshot.data!;
                    String message = data['message'] ?? '';

                    if (data.containsKey('letterCompleted') &&
                        data['letterCompleted'] == true) {
                      return AnimatedContainer(
                        duration: Duration(milliseconds: 500),
                        padding: EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          color: Colors.green[50],
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(color: Colors.green[300]!),
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
                            Icon(
                              Icons.celebration,
                              color: Colors.green[600],
                              size: 30,
                            ),
                            SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Luar Biasa! 🎉',
                                    style: TextStyle(
                                      color: Colors.green[700],
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Huruf ${widget.letter} berhasil diselesaikan!',
                                    style: TextStyle(
                                      color: Colors.green[600],
                                      fontWeight: FontWeight.w500,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    } else if (data.containsKey('strokeCompleted') &&
                        data['strokeCompleted'] == true) {
                      final current = data['currentStrokeIndex'] ?? 0;
                      final total = data['totalStrokes'] ?? 0;
                      return Container(
                        padding: EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(color: Colors.blue[300]!),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.check_circle, color: Colors.blue[600]),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Bagus! Lanjut ke garis ${current + 1} dari $total',
                                style: TextStyle(
                                  color: Colors.blue[700],
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    } else if (data.containsKey('strokeInvalid') &&
                        data['strokeInvalid'] == true) {
                      return Container(
                        padding: EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          color: Colors.orange[50],
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(color: Colors.orange[300]!),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.refresh, color: Colors.orange[600]),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                message.isNotEmpty
                                    ? message
                                    : 'Coba lagi, ikuti jalur titik biru.',
                                style: TextStyle(
                                  color: Colors.orange[700],
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    } else if (data.containsKey('pathInvalid') &&
                        data['pathInvalid'] == true) {
                      return Container(
                        padding: EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          color: Colors.orange[50],
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(color: Colors.orange[300]!),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info, color: Colors.orange[600]),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                message.isNotEmpty
                                    ? message
                                    : 'Try again! Follow the dots.',
                                style: TextStyle(
                                  color: Colors.orange[700],
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    if (data.containsKey('pathCompleted') &&
                        data['pathCompleted'] == true) {
                      return Container(
                        padding: EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          color: Colors.orange[50],
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(color: Colors.orange[300]!),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.thumb_up, color: Colors.orange[600]),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Good! Continue with the next stroke.',
                                style: TextStyle(
                                  color: Colors.orange[700],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    if (data.containsKey('pathInvalid') &&
                        data['pathInvalid'] == true) {
                      return Container(
                        padding: EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          color: Colors.red[50],
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(color: Colors.red[300]!),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.error_outline, color: Colors.red[600]),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Try again! Follow the path more carefully.',
                                style: TextStyle(
                                  color: Colors.red[700],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                  }

                  return SizedBox(height: 60); // Placeholder
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
