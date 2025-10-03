import 'dart:async';

import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'svg_path_parser.dart';

class SVGTracingService {
  // Current state
  List<Offset> currentTrace = [];
  List<List<Offset>> allTraces = []; // Store all disconnected traces
  Map<int, bool> validatedTraces =
      {}; // Track which traces are validated (green)
  bool isTracing = false;

  // SVG data
  SVGLetterData? currentLetterData;
  String currentLetter = '';

  // Canvas properties
  Size? canvasSize;

  // Stroke width for adaptive coverage
  double strokeWidth = 36.0; // Match the stroke width in canvas painter

  // Audio
  final AudioPlayer _audioPlayer = AudioPlayer();

  // Stream for UI updates
  final StreamController<Map<String, dynamic>> _updateController =
      StreamController.broadcast();
  Stream<Map<String, dynamic>> get updateStream => _updateController.stream;

  // Tolerance for path matching (optimized for clean SVG paths)
  static const double pathTolerance = 30.0;
  static const double dotTolerance = 20.0;

  // Audio mapping
  static const Map<String, String> _audioMapping = {
    'ا': 'alif',
    'ب': 'ba',
    'ت': 'ta',
    'ث': 'tsa',
    'ج': 'jim',
    'ح': 'ha',
    'خ': 'kha',
    'د': 'dal',
    'ذ': 'dzal',
    'ر': 'ra',
    'ز': 'zai',
    'س': 'sin',
    'ش': 'syin',
    'ص': 'shad',
    'ض': 'dhad',
    'ط': 'tha',
    'ظ': 'zha',
    'ع': 'ain',
    'غ': 'ghain',
    'ف': 'fa',
    'ق': 'qaf',
    'ك': 'kaf',
    'ل': 'lam',
    'م': 'mim',
    'ن': 'nun',
    'ه': 'HHa',
    'و': 'waw',
    'ي': 'ya',
  };

  void setCanvasSize(Size size) {
    canvasSize = size;
  }

  /// Update stroke width for adaptive coverage radius
  /// Larger stroke width = more forgiving coverage
  void setStrokeWidth(double width) {
    strokeWidth = width;
  }

  Future<void> initializeLetter(String letter) async {
    currentLetter = letter;
    isTracing = false;
    currentTrace.clear();

    // Load SVG data
    currentLetterData = await SVGPathParser.parseLetter(letter);

    if (currentLetterData != null) {
      print('Loaded SVG data for $letter:');
      print('- ${currentLetterData!.pathPoints.length} dashed path points');
      print('- ViewBox: ${currentLetterData!.viewBox}');
    } else {
      print('Failed to load SVG data for letter: $letter');
    }

    _updateController.add({
      'letterInitialized': true,
      'letter': letter,
      'hasData': currentLetterData != null,
      'totalTracingPoints': currentLetterData?.pathPoints.length ?? 0,
    });
  }

  void startTracing(Offset position) {
    currentTrace.clear();
    currentTrace.add(position);
    isTracing = true;

    _updateController.add({'tracingStarted': true});
  }

  void updateTracing(Offset position) {
    if (isTracing) {
      currentTrace.add(position);
      _updateController.add({'tracingUpdated': true});
    }
  }

  Future<void> endTracing() async {
    if (!isTracing || currentLetterData == null) return;

    isTracing = false;

    // Save current trace to allTraces if it has points
    if (currentTrace.isNotEmpty) {
      allTraces.add(List.from(currentTrace));
      print(
        '💾 Saved trace ${allTraces.length} with ${currentTrace.length} points',
      );
    }

    // Clear current trace for next stroke
    currentTrace.clear();

    // Just stop tracing, don't validate automatically
    // User must press "Cek" button to validate
    _updateController.add({
      'tracingStopped': true,
      'totalTraces': allTraces.length,
    });
  }

  // Manual validation method - called when user presses "Cek" button
  Future<void> validateTracing() async {
    if (currentLetterData == null) {
      _updateController.add({
        'strokeInvalid': true,
        'message': 'Data huruf belum dimuat.',
      });
      return;
    }

    // Check if user has made any traces
    if (allTraces.isEmpty && currentTrace.isEmpty) {
      _updateController.add({
        'strokeInvalid': true,
        'message': 'Silakan trace huruf terlebih dahulu.',
      });
      return;
    }

    double coverage = _calculateDashedPathCoverage();
    const double requiredCoverage = 1.0; // 100% coverage required!

    print(
      'Validating tracing: ${(coverage * 100).toStringAsFixed(1)}% coverage',
    );

    if (coverage >= requiredCoverage) {
      // Perfect tracing! Mark all traces as valid (green)
      for (int i = 0; i < allTraces.length; i++) {
        validatedTraces[i] = true;
      }

      // await _playSuccessSound(currentLetter);
      _updateController.add({
        'letterCompleted': true,
        'coverage': coverage,
        'message': 'Sempurna! Huruf berhasil diselesaikan dengan benar.',
      });
    } else {
      // Need better coverage
      String errorMessage = 'Tracing belum lengkap. ';
      if (coverage < 0.3) {
        errorMessage += 'Trace semua bagian huruf termasuk titik-titiknya.';
      } else if (coverage < 0.7) {
        errorMessage += 'Hampir benar, lengkapi bagian yang terlewat.';
      } else {
        errorMessage += 'Sedikit lagi, pastikan semua bagian ter-trace.';
      }

      _updateController.add({
        'strokeInvalid': true,
        'coverage': coverage,
        'message': errorMessage,
      });
    }

    // Hide feedback after 3 seconds
    Future.delayed(Duration(seconds: 3), () {
      _updateController.add({'feedbackHidden': true});
    });
  }

  // Calculate coverage percentage for dashed paths
  double _calculateDashedPathCoverage() {
    if (currentLetterData == null || canvasSize == null) {
      return 0.0;
    }

    // Combine all traces (completed + current)
    List<Offset> combinedTrace = [];
    for (final trace in allTraces) {
      combinedTrace.addAll(trace);
    }
    combinedTrace.addAll(currentTrace);

    if (combinedTrace.length < 5) {
      return 0.0;
    }

    // Get all dashed path points (unified tracing)
    final allTargetPoints = currentLetterData!.pathPoints;
    if (allTargetPoints.isEmpty) return 0.0;

    // Get SVG viewBox size
    final viewBox = currentLetterData!.viewBox;

    // Calculate scale to fit canvas while maintaining aspect ratio (same as rendering)
    final scaleX = canvasSize!.width / viewBox.width;
    final scaleY = canvasSize!.height / viewBox.height;
    final scale = scaleX < scaleY ? scaleX : scaleY;

    // Calculate offset to center (same as rendering)
    final offsetX = (canvasSize!.width - (viewBox.width * scale)) / 2;
    final offsetY = (canvasSize!.height - (viewBox.height * scale)) / 2;

    // Convert normalized coordinates to canvas coordinates with proper transformation
    final canvasTargetPoints =
        allTargetPoints.map((point) {
          // SVG coordinates (normalized in pathPoints are already in viewBox space)
          final svgX = point.position.dx * viewBox.width;
          final svgY = point.position.dy * viewBox.height;

          // Apply same transformation as rendering
          final canvasX = (svgX * scale) + offsetX;
          final canvasY = (svgY * scale) + offsetY;

          return Offset(canvasX, canvasY);
        }).toList();

    // Calculate how many target points are "covered" by combined user traces
    int coveredPoints = 0;

    // ✨ ADAPTIVE COVERAGE RADIUS based on stroke width
    // Larger stroke = more forgiving coverage radius
    final double coverageRadius = strokeWidth;

    print(
      '📏 Adaptive Coverage: strokeWidth=$strokeWidth → radius=${coverageRadius.toStringAsFixed(1)}px',
    );

    for (Offset targetPoint in canvasTargetPoints) {
      bool pointCovered = false;

      // Check against combined traces
      for (Offset tracePoint in combinedTrace) {
        double distance = (tracePoint - targetPoint).distance;
        if (distance <= coverageRadius) {
          pointCovered = true;
          break;
        }
      }

      if (pointCovered) {
        coveredPoints++;
      }
    }

    double coverageRatio = coveredPoints / canvasTargetPoints.length;

    print(
      '🎯 Coverage: ${(coverageRatio * 100).toStringAsFixed(1)}% ($coveredPoints/${canvasTargetPoints.length} points)',
    );
    print(
      '📝 Total traces: ${allTraces.length} completed + current (${currentTrace.length} points)',
    );
    print('📐 Scale: $scale, Offset: ($offsetX, $offsetY)');

    return coverageRatio;
  }

  Future<void> _playSuccessSound(String letter) async {
    try {
      String? audioFileName = _audioMapping[letter];
      if (audioFileName != null) {
        await _audioPlayer.play(AssetSource('audio/$audioFileName.m4a'));
      } else {
        await _audioPlayer.play(AssetSource('audio/benar.m4a'));
      }
    } catch (e) {
      print('Error playing sound: $e');
    }
  }

  // Get current stroke points for drawing guide dots
  List<Offset> getCurrentStrokeGuidePoints() {
    if (currentLetterData == null || canvasSize == null) return [];

    // Return all dashed path points since we're using coverage-based tracing
    return currentLetterData!.pathPoints
        .map(
          (point) => Offset(
            point.position.dx * canvasSize!.width,
            point.position.dy * canvasSize!.height,
          ),
        )
        .toList();
  }

  // Compatibility methods
  List<List<Offset>> get allStrokes => [currentTrace];

  void resetTracing() {
    currentTrace.clear();
    allTraces.clear();
    validatedTraces.clear(); // Clear validation status
    isTracing = false;
    _updateController.add({'tracingReset': true});
    print('🔄 Tracing reset - all traces cleared');
  }

  void initialize(String letter) {
    initializeLetter(letter);
  }

  bool get hasStrokes => currentTrace.isNotEmpty;

  void clearTracing() {
    resetTracing();
  }

  Stream<Map<String, dynamic>> get feedbackStream => updateStream;

  bool showFeedback = false;
  bool isCorrect = false;

  Future<void> playSound(String letter) async {
    await _playSuccessSound(letter);
  }

  Future<void> checkTracing(String letter) async {
    // Check coverage instead of stroke completion
    double coverage = _calculateDashedPathCoverage();
    if (coverage >= 0.7) {
      await _playSuccessSound(letter);
    }
  }

  // Methods for canvas rendering - returns separated stroke groups
  List<Offset> getCurrentStrokePoints() {
    if (currentLetterData == null || canvasSize == null) return [];

    // Return all path points (each <g> group is separate)
    return currentLetterData!.pathPoints
        .map(
          (point) => Offset(
            point.position.dx * canvasSize!.width,
            point.position.dy * canvasSize!.height,
          ),
        )
        .toList();
  }

  // Get stroke groups separately (for debugging)
  Map<int, List<Offset>> getStrokeGroups() {
    if (currentLetterData == null || canvasSize == null) return {};

    Map<int, List<Offset>> groups = {};

    for (final point in currentLetterData!.pathPoints) {
      final canvasPoint = Offset(
        point.position.dx * canvasSize!.width,
        point.position.dy * canvasSize!.height,
      );

      groups.putIfAbsent(point.strokeOrder, () => []).add(canvasPoint);
    }

    return groups;
  }

  List<Offset> getAllGuidePoints() {
    if (currentLetterData == null || canvasSize == null) return [];

    return currentLetterData!.pathPoints
        .map(
          (point) => Offset(
            point.position.dx * canvasSize!.width,
            point.position.dy * canvasSize!.height,
          ),
        )
        .toList();
  }

  Map<int, List<Offset>> getStrokeOrderMap() {
    if (currentLetterData == null || canvasSize == null) return {};

    Map<int, List<Offset>> strokeMap = {};

    for (final point in currentLetterData!.pathPoints) {
      final canvasPoint = Offset(
        point.position.dx * canvasSize!.width,
        point.position.dy * canvasSize!.height,
      );

      strokeMap.putIfAbsent(point.strokeOrder, () => []).add(canvasPoint);
    }

    return strokeMap;
  }

  List<Offset> getCompletedStrokePoints() {
    // For coverage-based tracing, we don't track completed strokes
    // Return empty list to maintain compatibility
    return [];
  }

  // Reset/clear all traces untuk mengulang dari awal
  void clearAllTraces() {
    currentTrace.clear();
    allTraces.clear();
    _updateController.add({
      'tracesCleared': true,
      'message': 'Tracing direset, silakan mulai lagi.',
    });
    print('🔄 All traces cleared');
  }

  void dispose() {
    _updateController.close();
    _audioPlayer.dispose();
  }
}
