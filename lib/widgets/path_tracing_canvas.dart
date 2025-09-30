import 'package:flutter/material.dart';
import '../services/path_based_tracing_service.dart';

class PathTracingCanvas extends StatefulWidget {
  final String letter;
  final PathBasedTracingService tracingService;

  const PathTracingCanvas({
    Key? key,
    required this.letter,
    required this.tracingService,
  }) : super(key: key);

  @override
  State<PathTracingCanvas> createState() => _PathTracingCanvasState();
}

class _PathTracingCanvasState extends State<PathTracingCanvas> {
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
      width: 300,
      height: 300,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey[300]!, width: 2),
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
            widget.tracingService.endTracing(widget.letter);
          },
          child: StreamBuilder<Map<String, dynamic>>(
            stream: widget.tracingService.updateStream,
            builder: (context, snapshot) {
              return CustomPaint(
                painter: PathTracingPainter(
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

class PathTracingPainter extends CustomPainter {
  final String letter;
  final PathBasedTracingService tracingService;

  PathTracingPainter({required this.letter, required this.tracingService});

  @override
  void paint(Canvas canvas, Size size) {
    // Update canvas size
    tracingService.setCanvasSize(size);

    // Get letter path points
    final pathPoints = tracingService.getCurrentLetterPoints(letter);

    if (pathPoints.isNotEmpty) {
      _drawGuidePaths(canvas, size, pathPoints);
      _drawPathDots(canvas, size, pathPoints);
      _drawStrokeNumbers(canvas, size, pathPoints);
    }

    // Draw user's current trace
    _drawUserTrace(canvas, size);

    // Draw letter outline (faded)
    _drawLetterOutline(canvas, size);
  }

  void _drawGuidePaths(Canvas canvas, Size size, List<PathPoint> pathPoints) {
    if (pathPoints.length < 2) return;

    // Group points by stroke order
    Map<int, List<PathPoint>> strokeGroups = {};
    for (var point in pathPoints) {
      strokeGroups.putIfAbsent(point.order, () => []).add(point);
    }

    // Draw path lines for each stroke with improved styling
    strokeGroups.forEach((order, points) {
      if (points.length < 2) return;

      // Check if this stroke is completed
      bool isStrokeCompleted = points.every((point) => point.isCompleted);

      final paint =
          Paint()
            ..color =
                isStrokeCompleted
                    ? Colors.green.withOpacity(0.7) // Completed stroke - green
                    : (order == 1
                        ? Colors.blue.withOpacity(0.6)
                        : order == 2
                        ? Colors.orange.withOpacity(0.6)
                        : order == 3
                        ? Colors.purple.withOpacity(0.6)
                        : Colors.red.withOpacity(0.6))
            ..strokeWidth =
                isStrokeCompleted
                    ? 5.0
                    : 4.0 // Thicker for completed
            ..style = PaintingStyle.stroke
            ..strokeCap = StrokeCap.round;

      final path = Path();
      path.moveTo(points.first.position.dx, points.first.position.dy);

      // Use smooth curves for better appearance
      if (points.length > 3) {
        for (int i = 1; i < points.length; i++) {
          if (i == 1 || i == points.length - 1) {
            // Straight line for start and end
            path.lineTo(points[i].position.dx, points[i].position.dy);
          } else {
            // Smooth curve for middle points
            final currentPoint = points[i].position;
            final prevPoint = points[i - 1].position;
            final controlPoint = Offset(
              (prevPoint.dx + currentPoint.dx) / 2,
              (prevPoint.dy + currentPoint.dy) / 2,
            );
            path.quadraticBezierTo(
              controlPoint.dx,
              controlPoint.dy,
              currentPoint.dx,
              currentPoint.dy,
            );
          }
        }
      } else {
        for (int i = 1; i < points.length; i++) {
          path.lineTo(points[i].position.dx, points[i].position.dy);
        }
      }

      canvas.drawPath(path, paint);
    });
  }

  void _drawPathDots(Canvas canvas, Size size, List<PathPoint> pathPoints) {
    for (int i = 0; i < pathPoints.length; i++) {
      var point = pathPoints[i];

      // Different colors and styles for different stroke orders
      Color dotColor;
      double radius;

      if (point.isCompleted) {
        dotColor = Colors.green[600]!;
        radius = 8.0;
      } else {
        switch (point.order) {
          case 1:
            dotColor = Colors.blue[500]!;
            break;
          case 2:
            dotColor = Colors.orange[500]!;
            break;
          case 3:
            dotColor = Colors.purple[500]!;
            break;
          default:
            dotColor = Colors.red[500]!;
        }

        // Make start points larger and more prominent
        bool isStartPoint = _isStartOfStroke(point, pathPoints);
        radius = isStartPoint ? 10.0 : 6.0;
      }

      // Draw dot with shadow effect
      final shadowPaint =
          Paint()
            ..color = Colors.black.withOpacity(0.2)
            ..style = PaintingStyle.fill;

      final paint =
          Paint()
            ..color = dotColor
            ..style = PaintingStyle.fill;

      // Draw shadow
      canvas.drawCircle(
        Offset(point.position.dx + 1, point.position.dy + 1),
        radius,
        shadowPaint,
      );

      // Draw main dot
      canvas.drawCircle(point.position, radius, paint);

      // Draw white border
      final borderPaint =
          Paint()
            ..color = Colors.white
            ..strokeWidth = 2.0
            ..style = PaintingStyle.stroke;

      canvas.drawCircle(point.position, radius, borderPaint);
    }
  }

  bool _isStartOfStroke(PathPoint point, List<PathPoint> allPoints) {
    // Check if this is the first point of its stroke order
    for (int i = 0; i < allPoints.length; i++) {
      if (allPoints[i].order == point.order) {
        return allPoints[i] == point;
      }
    }
    return false;
  }

  void _drawStrokeNumbers(
    Canvas canvas,
    Size size,
    List<PathPoint> pathPoints,
  ) {
    // Draw numbers for start of each stroke
    Map<int, PathPoint> strokeStarts = {};

    for (var point in pathPoints) {
      if (!strokeStarts.containsKey(point.order)) {
        strokeStarts[point.order] = point;
      }
    }

    strokeStarts.forEach((order, startPoint) {
      // Draw background circle for number
      final bgPaint =
          Paint()
            ..color =
                startPoint.isCompleted
                    ? Colors.green[600]!
                    : Colors.white.withOpacity(0.9)
            ..style = PaintingStyle.fill;

      canvas.drawCircle(startPoint.position, 12.0, bgPaint);

      // Draw border
      final borderPaint =
          Paint()
            ..color =
                startPoint.isCompleted ? Colors.green[800]! : Colors.grey[600]!
            ..strokeWidth = 1.5
            ..style = PaintingStyle.stroke;

      canvas.drawCircle(startPoint.position, 12.0, borderPaint);

      // Draw number text
      final textPainter = TextPainter(
        text: TextSpan(
          text: order.toString(),
          style: TextStyle(
            color: startPoint.isCompleted ? Colors.white : Colors.black87,
            fontSize: 14.0,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      );

      textPainter.layout();

      final offset = Offset(
        startPoint.position.dx - textPainter.width / 2,
        startPoint.position.dy - textPainter.height / 2,
      );

      textPainter.paint(canvas, offset);
    });
  }

  void _drawUserTrace(Canvas canvas, Size size) {
    final List<Offset> currentTrace =
        tracingService.allStrokes.isNotEmpty
            ? tracingService.allStrokes[0]
            : <Offset>[];

    if (currentTrace.length < 2) return;

    final paint =
        Paint()
          ..color = Colors.red[600]!
          ..strokeWidth = 4.0
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round;

    final path = Path();
    path.moveTo(currentTrace.first.dx, currentTrace.first.dy);

    for (int i = 1; i < currentTrace.length; i++) {
      path.lineTo(currentTrace[i].dx, currentTrace[i].dy);
    }

    canvas.drawPath(path, paint);
  }

  void _drawLetterOutline(Canvas canvas, Size size) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: letter,
        style: TextStyle(
          fontSize: size.width * 0.6,
          fontFamily: 'Maqroo',
          fontWeight: FontWeight.bold,
          color: Colors.grey[200],
        ),
      ),
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();

    final offset = Offset(
      (size.width - textPainter.width) / 2,
      (size.height - textPainter.height) / 2,
    );

    textPainter.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(PathTracingPainter oldDelegate) {
    return true; // Always repaint for real-time updates
  }
}
