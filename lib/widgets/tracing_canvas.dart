import 'package:afdyl/constants/app_colors.dart';
import 'package:flutter/material.dart';

class TracingCanvas extends StatelessWidget {
  final String letter;
  final bool isPracticeMode;
  final List<List<Offset>> allStrokes; // Ubah ke multi-stroke

  const TracingCanvas({
    Key? key,
    required this.letter,
    required this.isPracticeMode,
    required this.allStrokes,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 300,
      height: 300,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.secondary,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Stack(
          children: [
            if (isPracticeMode)
              Center(
                child: Opacity(
                  opacity: 0.3,
                  child: Text(
                    letter,
                    style: TextStyle(
                      fontSize: 200,
                      fontFamily: 'Maqroo',
                      fontWeight: FontWeight.bold,
                      color: Colors.black54,
                    ),
                  ),
                ),
              ),
            Positioned.fill(
              child: RepaintBoundary(
                child: CustomPaint(
                  painter: TracingPainter(allStrokes), // Pass allStrokes
                  child: Container(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TracingPainter extends CustomPainter {
  final List<List<Offset>> allStrokes;

  TracingPainter(this.allStrokes);

  @override
  void paint(Canvas canvas, Size size) {
    if (allStrokes.isEmpty) return;
    Paint paint =
        Paint()
          ..color = Colors.black
          ..strokeCap = StrokeCap.round
          ..strokeWidth = 6.0
          ..style = PaintingStyle.stroke;

    // Render setiap stroke secara terpisah (garis tetap ada)
    for (var stroke in allStrokes) {
      if (stroke.length < 2) continue;
      for (int i = 0; i < stroke.length - 1; i++) {
        if (stroke[i] != Offset.zero && stroke[i + 1] != Offset.zero) {
          canvas.drawLine(stroke[i], stroke[i + 1], paint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
