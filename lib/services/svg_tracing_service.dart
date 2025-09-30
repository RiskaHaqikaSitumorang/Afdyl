import 'dart:async';

import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'svg_path_parser.dart';

class SVGTracingService {
  // Current state
  List<Offset> currentTrace = [];
  bool isTracing = false;
  int currentStrokeIndex = 0;
  List<bool> completedStrokes = [];

  // SVG data
  SVGLetterData? currentLetterData;
  String currentLetter = '';

  // Canvas properties
  Size? canvasSize;

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

  Future<void> initializeLetter(String letter) async {
    currentLetter = letter;
    currentStrokeIndex = 0;
    isTracing = false;
    currentTrace.clear();

    // Load SVG data
    currentLetterData = await SVGPathParser.parseLetter(letter);

    if (currentLetterData != null) {
      completedStrokes = List.filled(
        currentLetterData!.strokeOrder.length,
        false,
      );

      print('Loaded SVG data for $letter:');
      print('- ${currentLetterData!.pathPoints.length} path points');
      print('- ${currentLetterData!.strokePaths.length} strokes');
      print('- ViewBox: ${currentLetterData!.viewBox}');
    } else {
      completedStrokes = [];
      print('Failed to load SVG data for letter: $letter');
    }

    _updateController.add({
      'letterInitialized': true,
      'letter': letter,
      'hasData': currentLetterData != null,
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

    bool strokeCompleted = await _validateCurrentStroke();
    if (strokeCompleted) {
      completedStrokes[currentStrokeIndex] = true;
      currentStrokeIndex++;

      // Check if all strokes are completed
      if (_isLetterCompleted()) {
        await _playSuccessSound(currentLetter);
        _updateController.add({
          'letterCompleted': true,
          'allStrokesCompleted': true,
        });
      } else {
        _updateController.add({
          'strokeCompleted': true,
          'currentStrokeIndex': currentStrokeIndex,
          'totalStrokes': completedStrokes.length,
        });
      }
    } else {
      // Provide more specific error messages
      String errorMessage = 'Trace tidak valid. ';
      if (currentTrace.length < 10) {
        errorMessage += 'Trace terlalu pendek.';
      } else {
        errorMessage += 'Ikuti jalur dengan lebih teliti.';
      }

      _updateController.add({'strokeInvalid': true, 'message': errorMessage});
    }

    // Clear trace
    currentTrace.clear();

    // Hide feedback after 2 seconds
    Future.delayed(Duration(seconds: 2), () {
      _updateController.add({'feedbackHidden': true});
    });
  }

  Future<bool> _validateCurrentStroke() async {
    if (currentLetterData == null ||
        canvasSize == null ||
        currentTrace.length < 2) {
      return false;
    }

    // Get target points for current stroke
    final currentStroke = currentStrokeIndex + 1; // SVG strokes are 1-indexed
    final targetPoints =
        currentLetterData!.pathPoints
            .where((point) => point.strokeOrder == currentStroke)
            .toList();

    if (targetPoints.isEmpty) return false;

    // Convert normalized coordinates to canvas coordinates
    final canvasTargetPoints =
        targetPoints
            .map(
              (point) => Offset(
                point.position.dx * canvasSize!.width,
                point.position.dy * canvasSize!.height,
              ),
            )
            .toList();

    // For single path tracing, use more flexible validation
    // Check if it's a dot (single point)
    if (targetPoints.length == 1) {
      return _validateDot(canvasTargetPoints.first);
    }

    // Validate path tracing
    return _validatePath(canvasTargetPoints);
  }

  bool _validateDot(Offset targetDot) {
    // For dots, check if user touched near the target position
    for (Offset tracePoint in currentTrace) {
      double distance = (tracePoint - targetDot).distance;
      if (distance <= dotTolerance) {
        return true;
      }
    }
    return false;
  }

  bool _validatePath(List<Offset> targetPath) {
    if (targetPath.length < 2 || currentTrace.length < 10)
      return false; // Minimum 10 points

    // Calculate expected trace length
    double targetPathLength = _calculatePathLength(targetPath);
    double userTraceLength = _calculatePathLength(currentTrace);

    print('Target path length: ${targetPathLength.toStringAsFixed(1)}');
    print('User trace length: ${userTraceLength.toStringAsFixed(1)}');

    // 1. Check trace length - must be at least 60% of target path length
    double lengthRatio = userTraceLength / targetPathLength;
    if (lengthRatio < 0.6) {
      print(
        'Trace too short: ${(lengthRatio * 100).toStringAsFixed(1)}% of target',
      );
      return false;
    }

    // 2. Check start and end positions (stricter)
    double startDistance = (currentTrace.first - targetPath.first).distance;
    double endDistance = (currentTrace.last - targetPath.last).distance;

    if (startDistance > pathTolerance || endDistance > pathTolerance) {
      print(
        'Start/end position validation failed: start=$startDistance, end=$endDistance',
      );
      return false;
    }

    // 3. Check path coverage - more comprehensive
    int matchedPoints = 0;
    int sampleCount = (currentTrace.length / 3).round().clamp(10, 30);

    for (int i = 0; i < sampleCount; i++) {
      int traceIndex = (i * currentTrace.length / sampleCount).round();
      if (traceIndex >= currentTrace.length) continue;

      Offset tracePoint = currentTrace[traceIndex];

      // Find closest point in target path
      double minDistance = double.infinity;
      for (Offset targetPoint in targetPath) {
        double distance = (tracePoint - targetPoint).distance;
        if (distance < minDistance) {
          minDistance = distance;
        }
      }

      // Stricter tolerance
      if (minDistance <= pathTolerance * 1.2) {
        matchedPoints++;
      }
    }

    // Require at least 75% of points to match (stricter)
    double matchRatio = matchedPoints / sampleCount;
    print(
      'Path validation: $matchedPoints/$sampleCount matched (${(matchRatio * 100).toStringAsFixed(1)}%)',
    );

    return matchRatio >= 0.75; // 75% match required (stricter)
  }

  bool _isLetterCompleted() {
    return completedStrokes.every((completed) => completed);
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

    final currentStroke = currentStrokeIndex + 1;
    final targetPoints =
        currentLetterData!.pathPoints
            .where((point) => point.strokeOrder == currentStroke)
            .toList();

    return targetPoints
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
    currentStrokeIndex = 0;
    isTracing = false;
    completedStrokes = List.filled(
      currentLetterData?.strokeOrder.length ?? 0,
      false,
    );
    _updateController.add({'tracingReset': true});
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
    if (_isLetterCompleted()) {
      await _playSuccessSound(letter);
    }
  }

  // Methods for canvas rendering
  List<Offset> getCurrentStrokePoints() {
    if (currentLetterData == null || canvasSize == null) return [];

    final currentStroke = currentStrokeIndex + 1;
    final targetPoints =
        currentLetterData!.pathPoints
            .where((point) => point.strokeOrder == currentStroke)
            .toList();

    // Convert to canvas coordinates
    return targetPoints
        .map(
          (point) => Offset(
            point.position.dx * canvasSize!.width,
            point.position.dy * canvasSize!.height,
          ),
        )
        .toList();
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
    if (currentLetterData == null || canvasSize == null) return [];

    List<Offset> completed = [];

    for (int i = 0; i < currentStrokeIndex; i++) {
      final strokeOrder = i + 1;
      final points =
          currentLetterData!.pathPoints
              .where((point) => point.strokeOrder == strokeOrder)
              .toList();

      completed.addAll(
        points.map(
          (point) => Offset(
            point.position.dx * canvasSize!.width,
            point.position.dy * canvasSize!.height,
          ),
        ),
      );
    }

    return completed;
  }

  // Helper method to calculate path length
  double _calculatePathLength(List<Offset> path) {
    if (path.length < 2) return 0.0;

    double totalLength = 0.0;
    for (int i = 1; i < path.length; i++) {
      totalLength += (path[i] - path[i - 1]).distance;
    }

    return totalLength;
  }

  void dispose() {
    _updateController.close();
    _audioPlayer.dispose();
  }
}
