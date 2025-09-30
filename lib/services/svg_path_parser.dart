import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:xml/xml.dart';
import 'package:path_drawing/path_drawing.dart';

class SVGPathPoint {
  final Offset position;
  final int strokeOrder;
  final bool isStartPoint;
  final bool isEndPoint;

  SVGPathPoint({
    required this.position,
    required this.strokeOrder,
    this.isStartPoint = false,
    this.isEndPoint = false,
  });
}

class SVGLetterData {
  final List<SVGPathPoint> pathPoints;
  final List<Path> strokePaths;
  final List<int> strokeOrder;
  final Size viewBox;

  SVGLetterData({
    required this.pathPoints,
    required this.strokePaths,
    required this.strokeOrder,
    required this.viewBox,
  });
}

class SVGPathParser {
  static const Map<String, String> letterToSvgFile = {
    'ا': 'alif.svg',
    'ب': 'ba.svg',
    'ت': 'ta.svg',
    'ث': 'tsa.svg',
    'ج': 'jim.svg',
    'ح': 'ha.svg',
    'خ': 'kha.svg',
    'د': 'dal.svg',
    'ذ': 'dzal.svg',
    'ر': 'ra.svg',
    'ز': 'zai.svg',
    'س': 'sin.svg',
    'ش': 'syin.svg',
    'ص': 'shad.svg',
    'ض': 'dhad.svg',
    'ط': 'tha.svg',
    'ظ': 'zha.svg',
    'ع': 'ain.svg',
    'غ': 'ghain.svg',
    'ف': 'fa.svg',
    'ق': 'qaf.svg',
    'ك': 'kaf.svg',
    'ل': 'lam.svg',
    'م': 'mim.svg',
    'ن': 'nun.svg',
    'ه': 'Hā.svg', // Sesuai dengan file yang ada
    'و': 'waw.svg',
    'ي': 'ya.svg',
  };

  static Future<SVGLetterData?> parseLetter(String letter) async {
    try {
      final fileName = letterToSvgFile[letter];
      if (fileName == null) {
        print('SVG file not found for letter: $letter');
        return null;
      }

      // Load SVG file
      final svgString = await rootBundle.loadString(
        'assets/images/hijaiyah_svg/$fileName',
      );
      final document = XmlDocument.parse(svgString);

      // Get SVG dimensions
      final svgElement = document.findElements('svg').first;
      final viewBox = _parseViewBox(svgElement);

      List<SVGPathPoint> allPoints = [];
      List<Path> strokePaths = [];
      List<int> strokeOrders = [];

      // Parse all path elements and group them
      final pathElements = document.findAllElements('path');
      List<Path> letterPaths = [];

      for (final pathElement in pathElements) {
        final pathData = pathElement.getAttribute('d');
        final fill = pathElement.getAttribute('fill') ?? '';
        final stroke = pathElement.getAttribute('stroke') ?? '';
        final style = pathElement.getAttribute('style') ?? '';

        if (pathData != null && pathData.isNotEmpty) {
          // Filter out background/frame paths
          if (_isBackgroundPath(fill, stroke, style)) {
            continue; // Skip background paths
          }

          // Parse the SVG path
          final path = parseSvgPathData(pathData);

          // Filter out very large paths that are likely frames
          if (_isLikelyLetterPath(path, viewBox)) {
            letterPaths.add(path);
          }
        }
      }

      // Process each letter path separately to preserve internal details
      int strokeOrderCounter = 1;
      for (final path in letterPaths) {
        strokePaths.add(path);
        strokeOrders.add(strokeOrderCounter);

        // Extract points from each path separately
        final points = _extractPointsFromPath(
          path,
          strokeOrderCounter,
          viewBox,
        );
        allPoints.addAll(points);
        strokeOrderCounter++;
      }

      // Parse circle elements (for dots like in Ba, Ta, etc.)
      int currentStrokeOrder =
          strokePaths.length + 1; // Continue from letter paths
      final circleElements = document.findAllElements('circle');
      for (final circleElement in circleElements) {
        final cx =
            double.tryParse(circleElement.getAttribute('cx') ?? '0') ?? 0;
        final cy =
            double.tryParse(circleElement.getAttribute('cy') ?? '0') ?? 0;
        final r = double.tryParse(circleElement.getAttribute('r') ?? '3') ?? 3;

        // Create a small circular path for the dot
        final dotPath =
            Path()..addOval(Rect.fromCircle(center: Offset(cx, cy), radius: r));

        strokePaths.add(dotPath);
        strokeOrders.add(currentStrokeOrder);

        // Add single point for dot
        allPoints.add(
          SVGPathPoint(
            position: Offset(cx / viewBox.width, cy / viewBox.height),
            strokeOrder: currentStrokeOrder,
            isStartPoint: true,
            isEndPoint: true,
          ),
        );

        currentStrokeOrder++;
      }

      return SVGLetterData(
        pathPoints: allPoints,
        strokePaths: strokePaths,
        strokeOrder: strokeOrders,
        viewBox: viewBox,
      );
    } catch (e) {
      print('Error parsing SVG for letter $letter: $e');
      return null;
    }
  }

  static Size _parseViewBox(XmlElement svgElement) {
    final viewBoxAttr = svgElement.getAttribute('viewBox');
    final widthAttr = svgElement.getAttribute('width');
    final heightAttr = svgElement.getAttribute('height');

    if (viewBoxAttr != null) {
      final parts = viewBoxAttr.split(' ');
      if (parts.length == 4) {
        final width = double.tryParse(parts[2]) ?? 300;
        final height = double.tryParse(parts[3]) ?? 300;
        return Size(width, height);
      }
    }

    // Fallback to width/height attributes
    final width =
        double.tryParse(widthAttr?.replaceAll('px', '') ?? '300') ?? 300;
    final height =
        double.tryParse(heightAttr?.replaceAll('px', '') ?? '300') ?? 300;

    return Size(width, height);
  }

  static List<SVGPathPoint> _extractPointsFromPath(
    Path path,
    int strokeOrder,
    Size viewBox,
  ) {
    List<SVGPathPoint> points = [];

    // Get path metrics to extract points along the path
    final pathMetrics = path.computeMetrics();

    for (final metric in pathMetrics) {
      final length = metric.length;
      if (length == 0) continue;

      // Filter out paths that are likely borders/frames
      if (_isFramePath(metric, viewBox)) {
        continue; // Skip border/frame paths
      }

      // Sample points along the path
      final pointCount = (length / 12).round().clamp(
        3,
        25,
      ); // Reduced point density for cleaner tracing

      for (int i = 0; i <= pointCount; i++) {
        final t = i / pointCount;
        final distance = t * length;

        final tangent = metric.getTangentForOffset(distance);
        if (tangent != null) {
          final normalizedPos = Offset(
            tangent.position.dx / viewBox.width,
            tangent.position.dy / viewBox.height,
          );

          // Filter out points that are too close to edges (likely frame)
          if (_isValidTracingPoint(normalizedPos)) {
            points.add(
              SVGPathPoint(
                position: normalizedPos,
                strokeOrder: strokeOrder,
                isStartPoint: i == 0,
                isEndPoint: i == pointCount,
              ),
            );
          }
        }
      }
    }

    return points;
  }

  // Check if path is likely a border/frame (touches edges)
  static bool _isFramePath(PathMetric metric, Size viewBox) {
    // Sample a few points to check if path follows the border
    final sampleCount = 5;
    int edgePoints = 0;

    for (int i = 0; i <= sampleCount; i++) {
      final t = i / sampleCount.toDouble();
      final tangent = metric.getTangentForOffset(t * metric.length);

      if (tangent != null) {
        final x = tangent.position.dx;
        final y = tangent.position.dy;
        final margin = 10.0; // 10px margin from edge

        // Check if point is near edge
        if (x <= margin ||
            x >= (viewBox.width - margin) ||
            y <= margin ||
            y >= (viewBox.height - margin)) {
          edgePoints++;
        }
      }
    }

    // If most points are near edges, it's likely a frame
    return edgePoints > (sampleCount * 0.6);
  }

  // Check if point is valid for tracing (not too close to edges)
  static bool _isValidTracingPoint(Offset normalizedPos) {
    const double edgeMargin = 0.05; // 5% margin from edges

    return normalizedPos.dx > edgeMargin &&
        normalizedPos.dx < (1.0 - edgeMargin) &&
        normalizedPos.dy > edgeMargin &&
        normalizedPos.dy < (1.0 - edgeMargin);
  }

  // Check if path is background/frame based on fill and stroke attributes
  static bool _isBackgroundPath(String fill, String stroke, String style) {
    // Skip paths that are clearly backgrounds
    final lowerFill = fill.toLowerCase();
    final lowerStyle = style.toLowerCase();

    // Skip white/light colored fills (usually backgrounds)
    if (lowerFill.contains('#fefe') ||
        lowerFill.contains('#fff') ||
        lowerFill.contains('white') ||
        lowerStyle.contains('fill:#fefe') ||
        lowerStyle.contains('fill:#fff')) {
      return true;
    }

    return false;
  }

  // Check if path is likely the actual letter (not frame)
  static bool _isLikelyLetterPath(Path path, Size viewBox) {
    final bounds = path.getBounds();

    // Calculate path coverage of the viewBox
    final coverageX = bounds.width / viewBox.width;
    final coverageY = bounds.height / viewBox.height;

    // If path covers more than 90% of width or height, it's likely a frame
    if (coverageX > 0.9 || coverageY > 0.9) {
      return false;
    }

    // Check if path is too close to edges
    const margin = 15.0; // pixels
    if (bounds.left < margin ||
        bounds.top < margin ||
        bounds.right > (viewBox.width - margin) ||
        bounds.bottom > (viewBox.height - margin)) {
      return false;
    }

    return true;
  }
}
