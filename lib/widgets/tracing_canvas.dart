import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

class TracingCanvas extends StatelessWidget {
  final String letter;
  final bool isPracticeMode;
  final List<Offset> tracingPoints;
  final Function(DragStartDetails) onPanStart;
  final Function(DragUpdateDetails) onPanUpdate;
  final Function(DragEndDetails) onPanEnd;

  TracingCanvas({
    required this.letter,
    required this.isPracticeMode,
    required this.tracingPoints,
    required this.onPanStart,
    required this.onPanUpdate,
    required this.onPanEnd,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Color(0xFFD4C785),
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
                    fontWeight: FontWeight.bold,
                    color: Colors.black54,
                  ),
                ),
              ),
            ),
          Positioned.fill(
            child: GestureDetector(
              onPanStart: onPanStart,
              onPanUpdate: onPanUpdate,
              onPanEnd: onPanEnd,
              child: CustomPaint(
                painter: TracingPainter(tracingPoints),
                child: Container(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class TracingPainter extends CustomPainter {
  final List<Offset> points;

  TracingPainter(this.points);

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;
    Paint paint = Paint()
      ..color = Colors.black
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 8.0
      ..style = PaintingStyle.stroke;
    for (int i = 0; i < points.length - 1; i++) {
      if (points[i] != Offset.zero && points[i + 1] != Offset.zero) {
        canvas.drawLine(points[i], points[i + 1], paint);
      }
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}