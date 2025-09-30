import 'package:flutter/material.dart';
import '../services/svg_tracing_service.dart';

class SVGTracingCanvas extends StatefulWidget {
  final String letter;
  final SVGTracingService tracingService;

  const SVGTracingCanvas({
    Key? key,
    required this.letter,
    required this.tracingService,
  }) : super(key: key);

  @override
  State<SVGTracingCanvas> createState() => _SVGTracingCanvasState();
}

class _SVGTracingCanvasState extends State<SVGTracingCanvas> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.tracingService.initializeLetter(widget.letter);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 350,
      height: 350,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey[300]!, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: GestureDetector(
          onPanStart: (details) {
            RenderBox box = context.findRenderObject() as RenderBox;
            Offset localPosition = box.globalToLocal(details.globalPosition);

            // Set canvas size if not set
            if (widget.tracingService.canvasSize == null) {
              widget.tracingService.setCanvasSize(box.size);
            }

            widget.tracingService.startTracing(localPosition);
          },
          onPanUpdate: (details) {
            RenderBox box = context.findRenderObject() as RenderBox;
            Offset localPosition = box.globalToLocal(details.globalPosition);
            widget.tracingService.updateTracing(localPosition);
          },
          onPanEnd: (details) {
            widget.tracingService.endTracing();
          },
          child: StreamBuilder<Map<String, dynamic>>(
            stream: widget.tracingService.updateStream,
            builder: (context, snapshot) {
              return CustomPaint(
                painter: SVGTracingPainter(
                  letter: widget.letter,
                  tracingService: widget.tracingService,
                ),
                size: Size.infinite,
              );
            },
          ),
        ),
      ),
    );
  }
}

class SVGTracingPainter extends CustomPainter {
  final String letter;
  final SVGTracingService tracingService;

  SVGTracingPainter({required this.letter, required this.tracingService});

  @override
  void paint(Canvas canvas, Size size) {
    // Update canvas size
    tracingService.setCanvasSize(size);

    // 1. Draw faded letter outline (all strokes)
    _drawLetterOutline(canvas, size);

    // 2. Draw completed strokes (green)
    _drawCompletedStrokes(canvas, size);

    // 3. Draw current stroke guide points (blue dots)
    _drawCurrentStrokeGuide(canvas, size);

    // 4. Draw stroke numbers
    _drawStrokeNumbers(canvas, size);

    // 5. Draw user's current trace (red)
    _drawUserTrace(canvas, size);
  }

  void _drawLetterOutline(Canvas canvas, Size size) {
    final strokeMap = tracingService.getStrokeOrderMap();
    if (strokeMap.isEmpty) return;

    // Draw each stroke with different opacity based on completion status
    strokeMap.forEach((strokeOrder, points) {
      final isCurrentStroke =
          strokeOrder == tracingService.currentStrokeIndex + 1;
      final isCompleted = strokeOrder <= tracingService.currentStrokeIndex;

      Color strokeColor;
      double strokeWidth;

      if (isCompleted) {
        strokeColor = Colors.green[300]!;
        strokeWidth = 3.0;
      } else if (isCurrentStroke) {
        strokeColor = Colors.blue[200]!;
        strokeWidth = 2.5;
      } else {
        strokeColor = Colors.grey[200]!;
        strokeWidth = 1.5;
      }

      final outlinePaint =
          Paint()
            ..color = strokeColor
            ..strokeWidth = strokeWidth
            ..style = PaintingStyle.stroke
            ..strokeCap = StrokeCap.round;

      if (points.length < 2) {
        // Single point (dot)
        canvas.drawCircle(points.first, 4.0, outlinePaint);
      } else {
        // Path - draw as dashed line for better visibility
        final path = Path();
        path.moveTo(points.first.dx, points.first.dy);
        for (int i = 1; i < points.length; i++) {
          path.lineTo(points[i].dx, points[i].dy);
        }
        _drawDashedPath(canvas, path, outlinePaint, 6.0, 3.0);
      }
    });
  }

  void _drawCompletedStrokes(Canvas canvas, Size size) {
    final completedPoints = tracingService.getCompletedStrokePoints();

    final completedPaint =
        Paint()
          ..color = Colors.green[600]!
          ..strokeWidth = 6.0
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round;

    if (completedPoints.isNotEmpty) {
      if (completedPoints.length < 2) {
        // Single point (dot)
        canvas.drawCircle(completedPoints.first, 6.0, completedPaint);
      } else {
        // Path
        final path = Path();
        path.moveTo(completedPoints.first.dx, completedPoints.first.dy);
        for (int i = 1; i < completedPoints.length; i++) {
          path.lineTo(completedPoints[i].dx, completedPoints[i].dy);
        }
        canvas.drawPath(path, completedPaint);
      }
    }
  }

  void _drawCurrentStrokeGuide(Canvas canvas, Size size) {
    final currentStrokePoints = tracingService.getCurrentStrokePoints();

    if (currentStrokePoints.isEmpty) return;

    // Draw guide path as dashed line for better visibility
    final guidePaint =
        Paint()
          ..color = Colors.blue[300]!
          ..strokeWidth = 3.0
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round;

    if (currentStrokePoints.length > 1) {
      final path = Path();
      path.moveTo(currentStrokePoints.first.dx, currentStrokePoints.first.dy);
      for (int i = 1; i < currentStrokePoints.length; i++) {
        path.lineTo(currentStrokePoints[i].dx, currentStrokePoints[i].dy);
      }

      // Draw dashed path for better center line visibility
      _drawDashedPath(canvas, path, guidePaint, 8.0, 4.0);
    }

    // Draw fewer, more prominent guide dots
    final dotPaint =
        Paint()
          ..color = Colors.blue[500]!
          ..style = PaintingStyle.fill;

    // Only show every 3rd point to avoid clutter, plus start and end
    for (int i = 0; i < currentStrokePoints.length; i++) {
      bool shouldShow =
          i == 0 || // Start point
          i == currentStrokePoints.length - 1 || // End point
          i % 3 == 0; // Every 3rd point

      if (shouldShow) {
        final point = currentStrokePoints[i];
        double radius = 5.0;

        // Make start and end points larger
        if (i == 0 || i == currentStrokePoints.length - 1) {
          radius = 8.0;
        }

        canvas.drawCircle(point, radius, dotPaint);

        // White border for visibility
        final borderPaint =
            Paint()
              ..color = Colors.white
              ..strokeWidth = 2.0
              ..style = PaintingStyle.stroke;
        canvas.drawCircle(point, radius, borderPaint);
      }
    }
  }

  void _drawDashedPath(
    Canvas canvas,
    Path path,
    Paint paint,
    double dashWidth,
    double dashSpace,
  ) {
    final pathMetrics = path.computeMetrics();
    for (final metric in pathMetrics) {
      double distance = 0;
      bool draw = true;

      while (distance < metric.length) {
        final nextDistance = distance + (draw ? dashWidth : dashSpace);
        if (draw) {
          final extractPath = metric.extractPath(
            distance,
            nextDistance.clamp(0, metric.length),
          );
          canvas.drawPath(extractPath, paint);
        }
        distance = nextDistance;
        draw = !draw;
      }
    }
  }

  void _drawStrokeNumbers(Canvas canvas, Size size) {
    final strokeMap = tracingService.getStrokeOrderMap();

    strokeMap.forEach((strokeOrder, points) {
      if (points.isNotEmpty) {
        final startPoint = points.first;

        // Determine color based on completion status
        Color numberColor =
            strokeOrder <= tracingService.currentStrokeIndex
                ? Colors.green[700]!
                : strokeOrder == tracingService.currentStrokeIndex + 1
                ? Colors.red[700]!
                : Colors.grey[600]!;

        final textPainter = TextPainter(
          text: TextSpan(
            text: strokeOrder.toString(),
            style: TextStyle(
              color: numberColor,
              fontSize: 14.0,
              fontWeight: FontWeight.bold,
              backgroundColor: Colors.white.withOpacity(0.8),
            ),
          ),
          textDirection: TextDirection.ltr,
        );

        textPainter.layout();

        final offset = Offset(
          startPoint.dx - textPainter.width / 2,
          startPoint.dy - textPainter.height / 2 - 15,
        );

        // Draw background circle
        final bgPaint =
            Paint()
              ..color = Colors.white.withOpacity(0.9)
              ..style = PaintingStyle.fill;

        canvas.drawCircle(
          Offset(startPoint.dx, startPoint.dy - 15),
          12.0,
          bgPaint,
        );

        textPainter.paint(canvas, offset);
      }
    });
  }

  void _drawUserTrace(Canvas canvas, Size size) {
    final List<Offset> currentTrace =
        tracingService.allStrokes.isNotEmpty
            ? tracingService.allStrokes[0]
            : <Offset>[];

    if (currentTrace.length < 2) return;

    final tracePaint =
        Paint()
          ..color = Colors.red[600]!
          ..strokeWidth = 5.0
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round;

    final path = Path();
    path.moveTo(currentTrace.first.dx, currentTrace.first.dy);

    for (int i = 1; i < currentTrace.length; i++) {
      path.lineTo(currentTrace[i].dx, currentTrace[i].dy);
    }

    canvas.drawPath(path, tracePaint);

    // Draw trace start point
    final startPaint =
        Paint()
          ..color = Colors.red[800]!
          ..style = PaintingStyle.fill;

    canvas.drawCircle(currentTrace.first, 4.0, startPaint);
  }

  @override
  bool shouldRepaint(SVGTracingPainter oldDelegate) {
    return true; // Always repaint for real-time updates
  }
}
