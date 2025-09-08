// lib/widgets/qibla_widgets.dart
import 'package:flutter/material.dart';

class QiblaArrowPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint arrowPaint = Paint()
      ..color = Colors.green[700]!
      ..style = PaintingStyle.fill;
    final Paint outlinePaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final double centerX = size.width / 2;
    final double centerY = size.height / 2;
    Path arrowPath = Path();
    arrowPath.moveTo(centerX, centerY - 80); // Arrow tip
    arrowPath.lineTo(centerX - 15, centerY - 40); // Left wing
    arrowPath.lineTo(centerX - 8, centerY - 40); // Left inner
    arrowPath.lineTo(centerX - 8, centerY + 60); // Left side
    arrowPath.lineTo(centerX + 8, centerY + 60); // Right side
    arrowPath.lineTo(centerX + 8, centerY - 40); // Right inner
    arrowPath.lineTo(centerX + 15, centerY - 40); // Right wing
    arrowPath.close();
    canvas.drawPath(arrowPath, arrowPaint);
    canvas.drawPath(arrowPath, outlinePaint);
    Path tailPath = Path();
    tailPath.moveTo(centerX - 8, centerY + 60);
    tailPath.lineTo(centerX - 15, centerY + 80);
    tailPath.lineTo(centerX, centerY + 70);
    tailPath.lineTo(centerX + 15, centerY + 80);
    tailPath.lineTo(centerX + 8, centerY + 60);
    tailPath.close();
    canvas.drawPath(tailPath, arrowPaint);
    canvas.drawPath(tailPath, outlinePaint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

Widget buildDirectionLabels() {
  return Stack(
    alignment: Alignment.center,
    children: [
      Positioned(top: 20, child: Text('N', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black, fontFamily: 'OpenDyslexic'))),
      Positioned(right: 20, child: Text('E', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black, fontFamily: 'OpenDyslexic'))),
      Positioned(bottom: 20, child: Text('S', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black, fontFamily: 'OpenDyslexic'))),
      Positioned(left: 20, child: Text('W', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black, fontFamily: 'OpenDyslexic'))),
    ],
  );
}