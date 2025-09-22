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
          return Transform.scale(
            scale: isListening ? pulseAnimation.value : 1.0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Audio Visualizer Lines
                Container(
                  height: 40,
                  width: double.infinity,
                  margin: EdgeInsets.only(bottom: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: List.generate(7, (index) {
                      final heights = [15.0, 25.0, 35.0, 40.0, 30.0, 20.0, 18.0];
                      final animatedHeight = isListening
                          ? heights[index] * (0.5 + 0.5 * pulseAnimation.value)
                          : heights[index] * 0.3;
                      return Container(
                        width: 4,
                        height: animatedHeight,
                        margin: EdgeInsets.symmetric(horizontal: 3),
                        decoration: BoxDecoration(
                          color: isListening
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
                      color: Color(0xFFD4C785),
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
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                            ),
                          )
                        else
                          Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              color: isListening ? Colors.red : Colors.red[400],
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}