import 'dart:async';
import 'dart:ui';
import 'dart:math' as math;
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
  final List<List<Path>> separatedPaths; // Each group contains multiple paths

  SVGLetterData({
    required this.pathPoints,
    required this.strokePaths,
    required this.strokeOrder,
    required this.viewBox,
    required this.separatedPaths,
  });
}

class SVGPathParser {
  // Mapping untuk file SVG dashed (untuk tracing path)
  static const Map<String, String> letterToSvgFile = {
    'ا': 'alif-dashed.svg',
    'ب': 'ba-dashed.svg',
    'ت': 'ta-dashed.svg',
    'ث': 'tsa-dashed.svg',
    'ج': 'jim-dashed.svg',
    'ح': 'ha-dashed.svg',
    'خ': 'kha-dashed.svg',
    'د': 'dal-dashed.svg',
    'ذ': 'dzal-dashed.svg',
    'ر': 'ra-dashed.svg',
    'ز': 'zai-dashed.svg',
    'س': 'sin-dashed.svg',
    'ش': 'syin-dashed.svg',
    'ص': 'shad-dashed.svg',
    'ض': 'dhad-dashed.svg',
    'ط': 'tha-dashed.svg',
    'ظ': 'zha-dashed.svg',
    'ع': 'ain-dashed.svg',
    'غ': 'ghain-dashed.svg',
    'ف': 'fa-dashed.svg',
    'ق': 'qaf-dashed.svg',
    'ك': 'kaf-dashed.svg',
    'ل': 'lam-dashed.svg',
    'م': 'mim-dashed.svg',
    'ن': 'nun-dashed.svg',
    'ه': 'Hā-dashed.svg',
    'و': 'waw-dashed.svg',
    'ي': 'ya-dashed.svg',
  };

  // Mapping untuk file PNG original (untuk background)
  static const Map<String, String> letterToPngFile = {
    'ا': 'alif.png',
    'ب': 'ba.png',
    'ت': 'ta.png',
    'ث': 'tsa.png',
    'ج': 'jim.png',
    'ح': 'ha.png',
    'خ': 'kha.png',
    'د': 'dal.png',
    'ذ': 'dzal.png',
    'ر': 'ra.png',
    'ز': 'zai.png',
    'س': 'sin.png',
    'ش': 'syin.png',
    'ص': 'shad.png',
    'ض': 'dhad.png',
    'ط': 'tha.png',
    'ظ': 'zha.png',
    'ع': 'ain.png',
    'غ': 'ghain.png',
    'ف': 'fa.png',
    'ق': 'qaf.png',
    'ك': 'kaf.png',
    'ل': 'lam.png',
    'م': 'mim.png',
    'ن': 'nun.png',
    'ه': 'Hā.png',
    'و': 'waw.png',
    'ي': 'ya.png',
  };

  static String? getPngBackgroundPath(String letter) {
    final fileName = letterToPngFile[letter];
    if (fileName != null) {
      return 'assets/images/hijaiyah_original/$fileName';
    }
    return null;
  }

  static Future<SVGLetterData?> parseLetter(String letter) async {
    try {
      final fileName = letterToSvgFile[letter];
      if (fileName == null) {
        print('SVG file not found for letter: $letter');
        return null;
      }

      // Load SVG dashed file
      final svgString = await rootBundle.loadString(
        'assets/images/hijaiyah_svg_dashed/$fileName',
      );
      final document = XmlDocument.parse(svgString);

      // Get SVG dimensions
      final svgElement = document.findElements('svg').first;
      final viewBox = _parseViewBox(svgElement);

      List<SVGPathPoint> allPoints = [];
      List<Path> strokePaths = [];
      List<int> strokeOrders = [];
      List<List<Path>> separatedPaths = [];

      // Parse setiap <g> element yang berisi path untuk tracing dashed
      final gElements = document.findAllElements('g');
      List<Path> tracingPaths = [];
      int strokeOrder = 1;

      print('Found ${gElements.length} <g> elements in SVG');

      for (final gElement in gElements) {
        final pathElements = gElement.findElements('path');
        List<Path> groupPaths = [];

        for (final pathElement in pathElements) {
          final pathData = pathElement.getAttribute('d');

          if (pathData != null && pathData.isNotEmpty) {
            try {
              final path = parseSvgPathData(pathData);
              if (_isValidTracingPath(path, viewBox)) {
                tracingPaths.add(path);
                groupPaths.add(path);
                print(
                  'Added tracing path from <g> tag, stroke order: $strokeOrder',
                );
              }
            } catch (e) {
              print('Error parsing path data: $e');
            }
          }
        }

        if (groupPaths.isNotEmpty) {
          separatedPaths.add(groupPaths);
          strokeOrder++; // Increment stroke order for each <g> group
        }
      }

      // Combine all dashed paths into single tracing path
      if (tracingPaths.isNotEmpty) {
        // Create separate tracing points for each <g> group (no connecting paths)
        for (int i = 0; i < tracingPaths.length; i++) {
          final points = _extractPointsFromPath(
            tracingPaths[i],
            i + 1, // Each <g> tag has separate stroke order
            viewBox,
          );
          allPoints.addAll(points);

          print('Added ${points.length} points for stroke ${i + 1}');
        }

        // Add all stroke paths dengan order yang benar
        for (int i = 0; i < tracingPaths.length; i++) {
          strokePaths.add(tracingPaths[i]);
          strokeOrders.add(i + 1);
        }
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
        separatedPaths: separatedPaths,
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

  // Check if path is valid for tracing (reasonable size and position)
  static bool _isValidTracingPath(Path path, Size viewBox) {
    final bounds = path.getBounds();

    // Check if path has reasonable size (not too small or too large)
    final minSize = math.min(viewBox.width, viewBox.height) * 0.1;
    final maxSize = math.min(viewBox.width, viewBox.height) * 0.9;

    if (bounds.width < minSize ||
        bounds.height < minSize ||
        bounds.width > maxSize ||
        bounds.height > maxSize) {
      return false;
    }

    return true;
  }
}
