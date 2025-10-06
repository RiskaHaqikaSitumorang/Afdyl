import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/svg_tracing_service.dart';
import '../services/svg_path_parser.dart';
import '../constants/app_colors.dart';

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
  ui.Image? _backgroundImage;

  @override
  void initState() {
    super.initState();
    _loadBackgroundImage();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.tracingService.initializeLetter(widget.letter);
    });
  }

  Future<void> _loadBackgroundImage() async {
    final pngPath = SVGPathParser.getPngBackgroundPath(widget.letter);
    if (pngPath == null) return;

    try {
      final ByteData data = await rootBundle.load(pngPath);
      final Uint8List bytes = data.buffer.asUint8List();
      final ui.Codec codec = await ui.instantiateImageCodec(bytes);
      final ui.FrameInfo frameInfo = await codec.getNextFrame();

      if (mounted) {
        setState(() {
          _backgroundImage = frameInfo.image;
        });
      }
    } catch (e) {
      print('Error loading background image: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 350, // Fixed width (same as parent)
      height: 350, // Fixed height (same as parent)
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey[300]!, width: 2),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(13),
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
                  backgroundImage: _backgroundImage,
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
  final ui.Image? backgroundImage;

  SVGTracingPainter({
    required this.letter,
    required this.tracingService,
    this.backgroundImage,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Update canvas size
    tracingService.setCanvasSize(size);

    // 1. Draw white background only
    _drawBackground(canvas, size);

    // 2. Draw separated dashed guide paths (each <g> group separately)
    _drawSeparatedDashedPaths(canvas, size);

    // 3. Draw all user's traces (red)
    _drawAllUserTraces(canvas, size);

    // 4. [DEBUG] Draw target points (uncomment untuk debug)
    // _drawDebugTargetPoints(canvas, size);
  }

  void _drawBackground(Canvas canvas, Size size) {
    // Draw white background
    final backgroundPaint =
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.fill;
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      backgroundPaint,
    );

    // Draw PNG image as background if available
    if (backgroundImage != null && tracingService.currentLetterData != null) {
      // Use SVG viewBox as reference for consistent scaling
      final viewBox = tracingService.currentLetterData!.viewBox;

      // Calculate scale using viewBox (same as SVG paths)
      final scaleX = size.width / viewBox.width;
      final scaleY = size.height / viewBox.height;
      final scale = scaleX < scaleY ? scaleX : scaleY;

      // Calculate offset to center (same as SVG paths)
      final scaledWidth = viewBox.width * scale;
      final scaledHeight = viewBox.height * scale;
      final offsetX = (size.width - scaledWidth) / 2;
      final offsetY = (size.height - scaledHeight) / 2;

      final imageWidth = backgroundImage!.width.toDouble();
      final imageHeight = backgroundImage!.height.toDouble();
      final srcRect = Rect.fromLTWH(0, 0, imageWidth, imageHeight);
      final dstRect = Rect.fromLTWH(
        offsetX,
        offsetY,
        scaledWidth,
        scaledHeight,
      );

      final paint =
          Paint()
            ..filterQuality = FilterQuality.high
            ..color = Colors.white.withOpacity(
              0.4,
            ); // Semi-transparent so dashed lines are visible
      canvas.drawImageRect(backgroundImage!, srcRect, dstRect, paint);
    }
  }

  void _drawSeparatedDashedPaths(Canvas canvas, Size size) {
    if (tracingService.currentLetterData == null) return;

    final pathPaint =
        Paint()
          ..color = Colors.grey[400]!.withOpacity(0.0)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.0
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round;

    // Get SVG viewBox size
    final viewBox = tracingService.currentLetterData!.viewBox;

    // Calculate scale to fit canvas while maintaining aspect ratio
    final scaleX = size.width / viewBox.width;
    final scaleY = size.height / viewBox.height;
    final scale = scaleX < scaleY ? scaleX : scaleY;

    // Calculate offset to center the paths
    final offsetX = (size.width - (viewBox.width * scale)) / 2;
    final offsetY = (size.height - (viewBox.height * scale)) / 2;

    // Save canvas state
    canvas.save();

    // Apply transformation: translate to center, then scale
    canvas.translate(offsetX, offsetY);
    canvas.scale(scale, scale);

    // Draw each group separately
    for (
      int i = 0;
      i < tracingService.currentLetterData!.separatedPaths.length;
      i++
    ) {
      final groupPaths = tracingService.currentLetterData!.separatedPaths[i];

      // Draw each path in the group
      for (final path in groupPaths) {
        _drawDashedPath(canvas, path, pathPaint);
      }
    }

    // Restore canvas state
    canvas.restore();
  }

  void _drawDashedPath(Canvas canvas, Path path, Paint paint) {
    // Simple dashed path implementation
    // This creates a visual dashed effect
    final pathMetrics = path.computeMetrics();

    for (final pathMetric in pathMetrics) {
      double distance = 0.0;
      const double dashLength = 15.0;
      const double gapLength = 10.0;

      while (distance < pathMetric.length) {
        final segment = pathMetric.extractPath(distance, distance + dashLength);
        canvas.drawPath(segment, paint);
        distance += dashLength + gapLength;
      }
    }
  }

  void _drawAllUserTraces(Canvas canvas, Size size) {
    // Get stroke width from service (for adaptive coverage)
    final strokeWidth = tracingService.strokeWidth;

    // Draw all completed traces (from allTraces) with appropriate color
    for (int i = 0; i < tracingService.allTraces.length; i++) {
      final trace = tracingService.allTraces[i];
      if (trace.length < 2) continue;

      // Check if this trace is validated (green) or still pending (AppColors.primary)
      final isValidated = tracingService.validatedTraces[i] ?? false;
      final traceColor = isValidated ? Colors.green[600]! : AppColors.softBlack;

      final tracePaint =
          Paint()
            ..color = traceColor
            ..strokeWidth = strokeWidth
            ..style = PaintingStyle.stroke
            ..strokeCap = StrokeCap.round
            ..strokeJoin = StrokeJoin.round;

      final path = Path();
      path.moveTo(trace.first.dx, trace.first.dy);
      for (int j = 1; j < trace.length; j++) {
        path.lineTo(trace[j].dx, trace[j].dy);
      }
      canvas.drawPath(path, tracePaint);
    }

    // Draw current active trace (being drawn now) - always AppColors.primary
    final currentTrace = tracingService.currentTrace;
    if (currentTrace.length >= 2) {
      final currentTracePaint =
          Paint()
            ..color = AppColors.softBlack
            ..strokeWidth = strokeWidth
            ..style = PaintingStyle.stroke
            ..strokeCap = StrokeCap.round
            ..strokeJoin = StrokeJoin.round;

      final path = Path();
      path.moveTo(currentTrace.first.dx, currentTrace.first.dy);
      for (int i = 1; i < currentTrace.length; i++) {
        path.lineTo(currentTrace[i].dx, currentTrace[i].dy);
      }
      canvas.drawPath(path, currentTracePaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
