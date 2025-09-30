import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

class PathPoint {
  final Offset position;
  final bool isCompleted;
  final int order;

  PathPoint({
    required this.position,
    this.isCompleted = false,
    required this.order,
  });

  PathPoint copyWith({Offset? position, bool? isCompleted, int? order}) {
    return PathPoint(
      position: position ?? this.position,
      isCompleted: isCompleted ?? this.isCompleted,
      order: order ?? this.order,
    );
  }
}

class LetterPath {
  final List<PathPoint> points;
  final List<int> strokeOrder;

  LetterPath({required this.points, required this.strokeOrder});
}

class PathBasedTracingService {
  // Current tracing state
  List<Offset> currentTrace = [];
  bool isTracing = false;
  int currentPathIndex = 0;
  List<bool> completedPaths = [];

  // Canvas properties
  Size? canvasSize;

  // Audio
  final AudioPlayer _audioPlayer = AudioPlayer();

  // Stream for UI updates
  final StreamController<Map<String, dynamic>> _updateController =
      StreamController.broadcast();
  Stream<Map<String, dynamic>> get updateStream => _updateController.stream;

  // Tolerance for path matching (in pixels) - more lenient
  static const double pathTolerance = 35.0;

  // Mapping huruf ke nama file audio
  static const Map<String, String> _audioMapping = {
    'ا': 'alif',
    'ب': 'ba',
    'ج': 'jim',
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
    'ح': 'ha',
    'خ': 'kha',
    'ت': 'ta',
    'ث': 'tsa',
    'و': 'waw',
    'ي': 'ya',
  };

  // Helper methods untuk membuat path yang akurat berdasar kaligrafi Arab
  static List<PathPoint> _createAlif() {
    List<PathPoint> points = [];
    // Alif: garis vertikal dari atas ke bawah dengan sedikit kemiringan ke kanan
    for (int i = 0; i <= 30; i++) {
      double t = i / 30.0;
      points.add(
        PathPoint(
          position: Offset(
            0.5 + (t * 0.03), // Sedikit miring ke kanan (kaligrafi Naskh)
            0.15 + (t * 0.7), // Dari atas ke bawah
          ),
          order: 1,
        ),
      );
    }
    return points;
  }

  static List<PathPoint> _createBa() {
    List<PathPoint> points = [];

    // Stroke 1: Garis horizontal melengkung (kanan ke kiri - sesuai aturan Arab)
    for (int i = 0; i <= 25; i++) {
      double t = i / 25.0;
      double x = 0.75 - (t * 0.5); // Dari kanan ke kiri
      double y = 0.45 + math.sin(t * math.pi * 0.5) * 0.08; // Melengkung turun
      points.add(PathPoint(position: Offset(x, y), order: 1));
    }

    // Stroke 2: Titik di bawah (ditulis setelah garis utama)
    points.add(PathPoint(position: Offset(0.5, 0.65), order: 2));

    return points;
  }

  static List<PathPoint> _createTa() {
    List<PathPoint> points = [];

    // Stroke 1: Garis horizontal seperti Ba
    for (int i = 0; i <= 25; i++) {
      double t = i / 25.0;
      double x = 0.75 - (t * 0.5);
      double y = 0.45 + math.sin(t * math.pi * 0.5) * 0.08;
      points.add(PathPoint(position: Offset(x, y), order: 1));
    }

    // Stroke 2: Titik pertama di atas (kiri)
    points.add(PathPoint(position: Offset(0.45, 0.25), order: 2));

    // Stroke 3: Titik kedua di atas (kanan)
    points.add(PathPoint(position: Offset(0.55, 0.25), order: 3));

    return points;
  }

  static List<PathPoint> _createTha() {
    List<PathPoint> points = [];

    // Stroke 1: Garis horizontal seperti Ba
    for (int i = 0; i <= 25; i++) {
      double t = i / 25.0;
      double x = 0.75 - (t * 0.5);
      double y = 0.45 + math.sin(t * math.pi * 0.5) * 0.08;
      points.add(PathPoint(position: Offset(x, y), order: 1));
    }

    // Stroke 2-4: Tiga titik di atas (kiri ke kanan)
    points.add(PathPoint(position: Offset(0.4, 0.25), order: 2));
    points.add(PathPoint(position: Offset(0.5, 0.25), order: 3));
    points.add(PathPoint(position: Offset(0.6, 0.25), order: 4));

    return points;
  }

  static List<PathPoint> _createJim() {
    List<PathPoint> points = [];

    // Stroke 1: Kurva berbentuk mangkuk (dari kanan atas, turun melengkung, naik ke kiri)
    for (int i = 0; i <= 35; i++) {
      double t = i / 35.0;

      if (t <= 0.5) {
        // Bagian turun (kanan ke tengah bawah)
        double angle = t * math.pi; // 0 to π
        double x = 0.65 - (t * 0.15); // Bergerak ke kiri
        double y = 0.35 + math.sin(angle) * 0.25; // Turun melengkung
        points.add(PathPoint(position: Offset(x, y), order: 1));
      } else {
        // Bagian naik (tengah bawah ke kiri atas)
        double localT = (t - 0.5) * 2; // Normalize to 0-1
        double x = 0.5 - (localT * 0.15); // Bergerak ke kiri
        double y = 0.6 - (localT * 0.25); // Naik
        points.add(PathPoint(position: Offset(x, y), order: 1));
      }
    }

    // Stroke 2: Titik di bawah
    points.add(PathPoint(position: Offset(0.5, 0.75), order: 2));

    return points;
  }

  static List<PathPoint> _createHaa() {
    List<PathPoint> points = [];

    // Stroke 1: Seperti Jim tapi tanpa titik
    for (int i = 0; i <= 35; i++) {
      double t = i / 35.0;

      if (t <= 0.5) {
        double angle = t * math.pi;
        double x = 0.65 - (t * 0.15);
        double y = 0.35 + math.sin(angle) * 0.25;
        points.add(PathPoint(position: Offset(x, y), order: 1));
      } else {
        double localT = (t - 0.5) * 2;
        double x = 0.5 - (localT * 0.15);
        double y = 0.6 - (localT * 0.25);
        points.add(PathPoint(position: Offset(x, y), order: 1));
      }
    }

    return points;
  }

  static List<PathPoint> _createKha() {
    List<PathPoint> points = [];

    // Stroke 1: Seperti Haa
    for (int i = 0; i <= 35; i++) {
      double t = i / 35.0;

      if (t <= 0.5) {
        double angle = t * math.pi;
        double x = 0.65 - (t * 0.15);
        double y = 0.4 + math.sin(angle) * 0.25;
        points.add(PathPoint(position: Offset(x, y), order: 1));
      } else {
        double localT = (t - 0.5) * 2;
        double x = 0.5 - (localT * 0.15);
        double y = 0.65 - (localT * 0.25);
        points.add(PathPoint(position: Offset(x, y), order: 1));
      }
    }

    // Stroke 2: Titik di atas
    points.add(PathPoint(position: Offset(0.5, 0.2), order: 2));

    return points;
  }

  static List<PathPoint> _createDal() {
    List<PathPoint> points = [];

    // Stroke 1: Kurva Dal (seperti setengah lingkaran terbalik)
    for (int i = 0; i <= 20; i++) {
      double t = i / 20.0;
      double angle = t * math.pi; // Setengah lingkaran
      double x = 0.5 + math.cos(angle) * 0.2; // Dari kanan ke kiri
      double y = 0.5 - math.sin(angle) * 0.15; // Kurva ke atas
      points.add(PathPoint(position: Offset(x, y), order: 1));
    }

    return points;
  }

  static List<PathPoint> _createDzal() {
    List<PathPoint> points = [];

    // Stroke 1: Seperti Dal
    for (int i = 0; i <= 20; i++) {
      double t = i / 20.0;
      double angle = t * math.pi;
      double x = 0.5 + math.cos(angle) * 0.2;
      double y = 0.5 - math.sin(angle) * 0.15;
      points.add(PathPoint(position: Offset(x, y), order: 1));
    }

    // Stroke 2: Titik di atas
    points.add(PathPoint(position: Offset(0.5, 0.25), order: 2));

    return points;
  }

  static List<PathPoint> _createRa() {
    List<PathPoint> points = [];

    // Stroke 1: Kurva Ra (seperti setengah lingkaran kecil di atas)
    for (int i = 0; i <= 15; i++) {
      double t = i / 15.0;
      double angle = t * math.pi; // Setengah lingkaran
      double x = 0.5 + math.cos(angle) * 0.12;
      double y = 0.4 - math.sin(angle) * 0.08;
      points.add(PathPoint(position: Offset(x, y), order: 1));
    }

    return points;
  }

  static List<PathPoint> _createZai() {
    List<PathPoint> points = [];

    // Stroke 1: Seperti Ra
    for (int i = 0; i <= 15; i++) {
      double t = i / 15.0;
      double angle = t * math.pi;
      double x = 0.5 + math.cos(angle) * 0.12;
      double y = 0.4 - math.sin(angle) * 0.08;
      points.add(PathPoint(position: Offset(x, y), order: 1));
    }

    // Stroke 2: Titik di atas
    points.add(PathPoint(position: Offset(0.5, 0.25), order: 2));

    return points;
  }

  static List<PathPoint> _createSin() {
    List<PathPoint> points = [];

    // Stroke 1: Bentuk sin dengan 3 gerigi (kanan ke kiri)
    for (int i = 0; i <= 30; i++) {
      double t = i / 30.0;
      double x = 0.7 - (t * 0.4); // Dari kanan ke kiri

      // Buat 3 gerigi dengan fungsi sinus
      double wave = math.sin(t * math.pi * 3) * 0.08; // 3 gelombang
      double y = 0.45 + wave;

      points.add(PathPoint(position: Offset(x, y), order: 1));
    }

    return points;
  }

  static List<PathPoint> _createSyin() {
    List<PathPoint> points = [];

    // Stroke 1: Seperti Sin
    for (int i = 0; i <= 30; i++) {
      double t = i / 30.0;
      double x = 0.7 - (t * 0.4);
      double wave = math.sin(t * math.pi * 3) * 0.08;
      double y = 0.5 + wave;
      points.add(PathPoint(position: Offset(x, y), order: 1));
    }

    // Stroke 2-4: Tiga titik di atas
    points.add(PathPoint(position: Offset(0.4, 0.25), order: 2));
    points.add(PathPoint(position: Offset(0.5, 0.25), order: 3));
    points.add(PathPoint(position: Offset(0.6, 0.25), order: 4));

    return points;
  }

  static List<PathPoint> _createWaw() {
    List<PathPoint> points = [];

    // Stroke 1: Bentuk bulat seperti huruf O
    for (int i = 0; i <= 25; i++) {
      double t = i / 25.0;
      double angle = t * 2 * math.pi; // Lingkaran penuh
      double x = 0.5 + math.cos(angle) * 0.15;
      double y = 0.5 + math.sin(angle) * 0.2;
      points.add(PathPoint(position: Offset(x, y), order: 1));
    }

    return points;
  }

  static List<PathPoint> _createYa() {
    List<PathPoint> points = [];

    // Stroke 1: Bagian utama Ya (melengkung dari kanan turun ke kiri)
    for (int i = 0; i <= 25; i++) {
      double t = i / 25.0;
      double x = 0.7 - (t * 0.4); // Kanan ke kiri

      if (t < 0.7) {
        // Bagian horizontal
        double y = 0.45 + (t * 0.1); // Sedikit turun
        points.add(PathPoint(position: Offset(x, y), order: 1));
      } else {
        // Bagian melengkung turun
        double localT = (t - 0.7) / 0.3;
        double y = 0.52 + (localT * 0.2); // Turun lebih dalam
        points.add(PathPoint(position: Offset(x, y), order: 1));
      }
    }

    // Stroke 2: Dua titik di bawah
    points.add(PathPoint(position: Offset(0.45, 0.8), order: 2));
    points.add(PathPoint(position: Offset(0.55, 0.8), order: 3));

    return points;
  }

  // Template paths for each letter - normalized to 0.0-1.0 coordinates
  // Berdasarkan bentuk huruf Hijaiyah yang sebenarnya dengan kaligrafi Naskh
  static final Map<String, LetterPath> letterPaths = {
    // ALIF (ا) - Garis vertikal dengan sedikit kemiringan
    'ا': LetterPath(points: _createAlif(), strokeOrder: [1]),

    // BA (ب) - Garis horizontal melengkung dengan titik di bawah
    'ب': LetterPath(points: _createBa(), strokeOrder: [1, 2]),

    // TA (ت) - Seperti Ba dengan 2 titik di atas
    'ت': LetterPath(points: _createTa(), strokeOrder: [1, 2, 3]),

    // THA (ث) - Seperti Ba dengan 3 titik di atas
    'ث': LetterPath(points: _createTha(), strokeOrder: [1, 2, 3, 4]),

    // JIM (ج) - Bentuk mangkuk dengan titik di bawah
    'ج': LetterPath(points: _createJim(), strokeOrder: [1, 2]),

    // HAA (ح) - Seperti Jim tanpa titik
    'ح': LetterPath(points: _createHaa(), strokeOrder: [1]),

    // KHA (خ) - Seperti Haa dengan titik di atas
    'خ': LetterPath(points: _createKha(), strokeOrder: [1, 2]),

    // DAL (د) - Kurva setengah lingkaran
    'د': LetterPath(points: _createDal(), strokeOrder: [1]),

    // DZAL (ذ) - Seperti Dal dengan titik di atas
    'ذ': LetterPath(points: _createDzal(), strokeOrder: [1, 2]),

    // RA (ر) - Kurva kecil seperti setengah lingkaran
    'ر': LetterPath(points: _createRa(), strokeOrder: [1]),

    // ZAI (ز) - Seperti Ra dengan titik di atas
    'ز': LetterPath(points: _createZai(), strokeOrder: [1, 2]),

    // SIN (س) - Garis bergerigi 3 buah
    'س': LetterPath(points: _createSin(), strokeOrder: [1]),

    // SYIN (ش) - Seperti Sin dengan 3 titik di atas
    'ش': LetterPath(points: _createSyin(), strokeOrder: [1, 2, 3, 4]),

    // WAW (و) - Bentuk bulat seperti huruf O
    'و': LetterPath(points: _createWaw(), strokeOrder: [1]),

    // YA (ي) - Garis melengkung turun dengan 2 titik di bawah
    'ي': LetterPath(points: _createYa(), strokeOrder: [1, 2, 3]),
  };

  void setCanvasSize(Size size) {
    canvasSize = size;
  }

  void initializeLetter(String letter) {
    currentTrace.clear();
    currentPathIndex = 0;
    isTracing = false;

    final letterPath = letterPaths[letter];
    if (letterPath != null) {
      completedPaths = List.filled(letterPath.strokeOrder.length, false);
    } else {
      completedPaths = [];
    }

    _updateController.add({'letterInitialized': true, 'letter': letter});
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

  void endTracing(String letter) {
    if (!isTracing) return;
    isTracing = false;

    bool pathCompleted = _validateCurrentPath(letter);
    if (pathCompleted) {
      completedPaths[currentPathIndex] = true;
      isCorrect = true;
      showFeedback = true;

      // Play success sound for completed stroke
      _playSuccessSound(letter);

      currentPathIndex++;

      // Check if all paths are completed
      if (_isLetterCompleted()) {
        _updateController.add({
          'letterCompleted': true,
          'allPathsCompleted': true,
          'message': 'Excellent! Letter completed!',
        });
      } else {
        _updateController.add({
          'pathCompleted': true,
          'currentPathIndex': currentPathIndex,
          'message': 'Good! Now trace stroke ${currentPathIndex + 1}',
        });
      }
    } else {
      // Path tidak valid, beri feedback negatif
      isCorrect = false;
      showFeedback = true;

      _updateController.add({
        'pathInvalid': true,
        'message': 'Try again! Follow the dots and lines.',
      });
    }

    // Clear trace setelah validation
    currentTrace.clear();

    // Reset feedback setelah 2 detik
    Future.delayed(Duration(seconds: 2), () {
      showFeedback = false;
      _updateController.add({'feedbackHidden': true});
    });
  }

  bool _validateCurrentPath(String letter) {
    final letterPath = letterPaths[letter];
    if (letterPath == null || canvasSize == null) return false;

    // Get current stroke points
    final currentStrokeOrder = letterPath.strokeOrder[currentPathIndex];
    final targetPoints =
        letterPath.points
            .where((point) => point.order == currentStrokeOrder)
            .toList();

    if (targetPoints.isEmpty || currentTrace.length < 2) return false;

    // Convert normalized coordinates to actual canvas coordinates
    final actualTargetPoints =
        targetPoints
            .map(
              (point) => Offset(
                point.position.dx * canvasSize!.width,
                point.position.dy * canvasSize!.height,
              ),
            )
            .toList();

    // Check if user trace follows the target path
    return _doesTraceFollowPath(currentTrace, actualTargetPoints);
  }

  bool _doesTraceFollowPath(List<Offset> trace, List<Offset> targetPath) {
    if (trace.length < 3 || targetPath.length < 2) return false;

    // 1. Check if trace starts near the beginning of target path
    double startDistance = (trace.first - targetPath.first).distance;
    if (startDistance > pathTolerance) return false;

    // 2. Check if trace ends near the end of target path
    double endDistance = (trace.last - targetPath.last).distance;
    if (endDistance > pathTolerance) return false;

    // 3. Check direction consistency (user should follow the target path direction)
    bool directionMatches = _checkDirectionConsistency(trace, targetPath);
    if (!directionMatches) return false;

    // 4. Check if trace points follow the target path
    int matchedPoints = 0;
    int totalTracePoints = trace.length;

    for (Offset tracePoint in trace) {
      double minDistance = double.infinity;
      for (Offset targetPoint in targetPath) {
        double distance = (tracePoint - targetPoint).distance;
        if (distance < minDistance) {
          minDistance = distance;
        }
      }
      if (minDistance <= pathTolerance) {
        matchedPoints++;
      }
    }

    // More lenient: at least 65% of trace points should be within tolerance
    double matchRatio = matchedPoints / totalTracePoints;
    return matchRatio >= 0.65;
  }

  bool _checkDirectionConsistency(List<Offset> trace, List<Offset> targetPath) {
    if (trace.length < 3 || targetPath.length < 3) return true;

    // Calculate general direction of target path
    Offset targetDirection = targetPath.last - targetPath.first;

    // Calculate general direction of user trace
    Offset traceDirection = trace.last - trace.first;

    // Check if directions are roughly similar (dot product > 0 means same general direction)
    double dotProduct =
        (targetDirection.dx * traceDirection.dx) +
        (targetDirection.dy * traceDirection.dy);

    return dotProduct > 0;
  }

  bool _isLetterCompleted() {
    return completedPaths.every((completed) => completed);
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

  // Getter for current letter path points (for drawing)
  List<PathPoint> getCurrentLetterPoints(String letter) {
    final letterPath = letterPaths[letter];
    if (letterPath == null || canvasSize == null) return [];

    return letterPath.points.map((point) {
      return PathPoint(
        position: Offset(
          point.position.dx * canvasSize!.width,
          point.position.dy * canvasSize!.height,
        ),
        order: point.order,
        isCompleted: currentPathIndex >= point.order,
      );
    }).toList();
  }

  // Get current user trace for drawing
  List<List<Offset>> get allStrokes => [currentTrace];

  void resetTracing() {
    currentTrace.clear();
    currentPathIndex = 0;
    isTracing = false;
    completedPaths.clear();
    _updateController.add({'tracingReset': true});
  }

  // Additional methods for compatibility with existing UI
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
    // This is handled automatically in endTracing
    // Just play sound if completed
    if (_isLetterCompleted()) {
      await _playSuccessSound(letter);
    }
  }

  void dispose() {
    _updateController.close();
    _audioPlayer.dispose();
  }
}
