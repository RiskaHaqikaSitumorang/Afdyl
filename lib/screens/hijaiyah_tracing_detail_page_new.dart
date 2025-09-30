import 'package:flutter/material.dart';
import '../widgets/path_tracing_canvas.dart';
import '../services/path_based_tracing_service.dart';
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
  final PathBasedTracingService _tracingService = PathBasedTracingService();

  @override
  void initState() {
    super.initState();
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
      backgroundColor: AppColors.whiteSoft,
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
                    Text(
                      widget.letter,
                      style: TextStyle(
                        fontSize: 80,
                        fontFamily: 'Maqroo',
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
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
                        'Follow the dots in order to trace the letter correctly',
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
                  child: PathTracingCanvas(
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
                  ElevatedButton.icon(
                    onPressed: () => _tracingService.playSound(widget.letter),
                    icon: Icon(Icons.volume_up),
                    label: Text('Play Sound'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _tracingService.resetTracing(),
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

              // Progress Feedback
              StreamBuilder<Map<String, dynamic>>(
                stream: _tracingService.updateStream,
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    final data = snapshot.data!;

                    if (data.containsKey('letterCompleted') &&
                        data['letterCompleted'] == true) {
                      return Container(
                        padding: EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          color: Colors.green[50],
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(color: Colors.green[300]!),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.check_circle, color: Colors.green[600]),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Excellent! You traced the letter correctly!',
                                style: TextStyle(
                                  color: Colors.green[700],
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
