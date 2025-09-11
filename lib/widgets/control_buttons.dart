import 'package:flutter/material.dart';

class ControlButtons extends StatelessWidget {
  final VoidCallback onPlaySound;
  final VoidCallback onCheckTracing;
  final bool showFeedback;
  final bool isCorrect;
  final bool isProcessing;

  ControlButtons({
    required this.onPlaySound,
    required this.onCheckTracing,
    required this.showFeedback,
    required this.isCorrect,
    required this.isProcessing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 40),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Color(0xFFB8D4B8),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: Icon(
                Icons.volume_up,
                color: Colors.black,
                size: 28,
              ),
              onPressed: onPlaySound,
            ),
          ),
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: showFeedback
                      ? (isCorrect ? Colors.green[300] : Colors.red[300])
                      : Color(0xFFB8D4B8),
                  shape: BoxShape.circle,
                ),
                child: isProcessing
                    ? SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                        ),
                      )
                    : IconButton(
                        icon: Icon(
                          showFeedback
                              ? (isCorrect ? Icons.check : Icons.close)
                              : Icons.done,
                          color: Colors.black,
                          size: 28,
                        ),
                        onPressed: isProcessing ? null : onCheckTracing,
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}