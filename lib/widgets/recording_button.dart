import 'package:afdyl/constants/app_colors.dart';
import 'package:flutter/material.dart';

class RecordingButton extends StatelessWidget {
  final bool isListening;
  final bool isProcessing;
  final Animation<double> pulseAnimation;
  final VoidCallback onTap;

  const RecordingButton({
    Key? key,
    required this.isListening,
    required this.isProcessing,
    required this.pulseAnimation,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: AnimatedBuilder(
        animation: pulseAnimation,
        builder: (context, child) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Audio Visualizer Lines
              Container(
                height: 40,
                width: double.infinity,
                margin: EdgeInsets.only(bottom: 18),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: List.generate(7, (index) {
                    final heights = [15.0, 25.0, 35.0, 40.0, 30.0, 20.0, 18.0];
                    final animatedHeight =
                        isListening ? heights[index] : heights[index] * 0.3;
                    return Container(
                      width: 4,
                      height: animatedHeight,
                      margin: EdgeInsets.symmetric(horizontal: 3),
                      decoration: BoxDecoration(
                        color:
                            isListening
                                ? Color(0xFFD4C785).withOpacity(0.8)
                                : Color(0xFFD4C785).withOpacity(0.4),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    );
                  }),
                ),
              ),
              // Recording Button
              GestureDetector(
                onTap: isProcessing ? null : onTap,
                child: Container(
                  width: double.infinity,
                  height: 60,
                  decoration: BoxDecoration(
                    color: isListening ? AppColors.tertiary : AppColors.yellow,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 8,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      if (isProcessing)
                        SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppColors.tertiary,
                            ),
                          ),
                        )
                      else if (isListening)
                        // Icon Stop saat sedang recording
                        Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        )
                      else
                        // Icon Microphone saat idle
                        Icon(Icons.mic, color: AppColors.tertiary, size: 28),
                    ],
                  ),
                ),
              ),
              // Label text untuk feedback user
              SizedBox(height: 12),
              Text(
                isProcessing
                    ? 'Memproses...'
                    : isListening
                    ? 'Ketuk untuk berhenti'
                    : 'Ketuk untuk merekam',
                style: TextStyle(
                  fontSize: 14,
                  fontFamily: 'OpenDyslexic',
                  color: isListening ? Colors.red : Colors.black54,
                  fontWeight: isListening ? FontWeight.w600 : FontWeight.normal,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          );
        },
      ),
    );
  }
}
