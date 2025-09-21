import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart' as tfl;
import 'package:audioplayers/audioplayers.dart';
import 'dart:typed_data';
import 'dart:async';
import 'dart:math' as math;

class TracingService {
  List<List<Offset>> strokes = [];
  int currentStrokeIndex = 0;
  bool isTracing = false;
  bool showFeedback = false;
  bool isCorrect = false;
  bool isProcessing = false;
  Size? canvasSize;

  tfl.Interpreter? _interpreter;
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _modelLoaded = false;
  Timer? _feedbackTimer;

  final StreamController<Map<String, dynamic>> _feedbackController = StreamController.broadcast();
  Stream<Map<String, dynamic>> get feedbackStream => _feedbackController.stream;

  // Mapping antara huruf dan nama file audio untuk memastikan konsistensi
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

  // Template untuk setiap huruf: List stroke, setiap stroke adalah List koordinat [x,y]
  static const Map<String, List<List<List<double>>>> _templates = {
    'ا': [
      [[0.5, 0.0], [0.5, 1.0]], // Alif: Garis vertikal
    ],
    'ب': [
      [[0.0, 0.5], [1.0, 0.5]], // Ba: Garis horizontal
      [[0.7, 0.7], [0.7, 0.7]], // Titik di bawah
    ],
    'ج': [
      [[0.2, 0.8], [0.5, 0.2], [0.8, 0.8]], // Jim: Kurva
      [[0.5, 0.9], [0.5, 0.9]], // Titik di bawah
    ],
    'د': [
      [[0.5, 0.0], [0.5, 0.8]], // Dal: Garis vertikal pendek
    ],
    'ذ': [
      [[0.5, 0.0], [0.5, 0.8]], // Dzal: Garis vertikal pendek
      [[0.5, 0.1], [0.5, 0.1]], // Titik di atas
    ],
    'ر': [
      [[0.5, 0.2], [0.5, 0.8], [0.7, 0.9]], // Ra: Garis vertikal dengan ekor
    ],
    'ز': [
      [[0.5, 0.2], [0.5, 0.8], [0.7, 0.9]], // Zai: Garis vertikal dengan ekor
      [[0.5, 0.1], [0.5, 0.1]], // Titik di atas
    ],
    'س': [
      [[0.2, 0.5], [0.5, 0.3], [0.8, 0.5]], // Sin: Tiga kurva
      [[0.3, 0.4], [0.5, 0.2], [0.7, 0.4]],
      [[0.3, 0.6], [0.5, 0.8], [0.7, 0.6]],
    ],
    'ش': [
      [[0.2, 0.5], [0.5, 0.3], [0.8, 0.5]], // Syin: Tiga kurva
      [[0.3, 0.4], [0.5, 0.2], [0.7, 0.4]],
      [[0.3, 0.6], [0.5, 0.8], [0.7, 0.6]],
      [[0.5, 0.1], [0.5, 0.1]], // Tiga titik di atas
    ],
    'ص': [
      [[0.2, 0.5], [0.5, 0.3], [0.8, 0.5]], // Shad: Kurva lebar
      [[0.3, 0.4], [0.5, 0.6]],
    ],
    'ض': [
      [[0.2, 0.5], [0.5, 0.3], [0.8, 0.5]], // Dhad: Kurva lebar
      [[0.3, 0.4], [0.5, 0.6]],
      [[0.5, 0.1], [0.5, 0.1]], // Titik di atas
    ],
    'ط': [
      [[0.2, 0.5], [0.5, 0.2], [0.8, 0.5]], // Tha: Kurva dengan ekor
    ],
    'ظ': [
      [[0.2, 0.5], [0.5, 0.2], [0.8, 0.5]], // Zho: Kurva dengan ekor
      [[0.5, 0.1], [0.5, 0.1]], // Titik di atas
    ],
    'ع': [
      [[0.5, 0.2], [0.5, 0.8], [0.3, 0.9]], // Ain: Kurva terbuka
    ],
    'غ': [
      [[0.5, 0.2], [0.5, 0.8], [0.3, 0.9]], // Ghain: Kurva terbuka
      [[0.5, 0.1], [0.5, 0.1]], // Titik di atas
    ],
    'ف': [
      [[0.5, 0.5], [0.7, 0.3], [0.5, 0.1]], // Fa: Lingkaran dengan ekor
      [[0.5, 0.1], [0.5, 0.1]], // Titik di atas
    ],
    'ق': [
      [[0.5, 0.5], [0.7, 0.3], [0.5, 0.1]], // Qaf: Lingkaran dengan ekor
      [[0.5, 0.1], [0.5, 0.1]], // Dua titik di atas
    ],
    'ك': [
      [[0.5, 0.0], [0.5, 0.8]], // Kaf: Garis vertikal
      [[0.6, 0.4], [0.7, 0.3]], // Garis kecil diagonal
    ],
    'ل': [
      [[0.5, 0.0], [0.5, 1.0]], // Lam: Garis vertikal panjang
    ],
    'م': [
      [[0.3, 0.5], [0.5, 0.3], [0.7, 0.5]], // Mim: Lingkaran kecil
    ],
    'ن': [
      [[0.5, 0.2], [0.5, 0.8]], // Nun: Garis vertikal pendek
      [[0.5, 0.1], [0.5, 0.1]], // Titik di atas
    ],
    'ه': [
      [[0.3, 0.5], [0.5, 0.3], [0.7, 0.5]], // Ha: Lingkaran
    ],
    'ح': [
      [[0.3, 0.5], [0.5, 0.3], [0.7, 0.5]], // HHA: Dua lingkaran
      [[0.4, 0.4], [0.6, 0.4]],
    ],
    'خ': [
      [[0.3, 0.5], [0.5, 0.3], [0.7, 0.5]], // Kho: Kurva
      [[0.5, 0.1], [0.5, 0.1]], // Titik di atas
    ],
    'ت': [
      [[0.0, 0.5], [1.0, 0.5]], // Ta: Garis horizontal
      [[0.4, 0.1], [0.4, 0.1], [0.6, 0.1]], // Dua titik di atas
    ],
    'ث': [
      [[0.0, 0.5], [1.0, 0.5]], // Tsa: Garis horizontal
      [[0.3, 0.1], [0.5, 0.1], [0.7, 0.1]], // Tiga titik di atas
    ],
    'و': [
      [[0.5, 0.5], [0.7, 0.3], [0.5, 0.1]], // Waw: Lingkaran kecil
    ],
    'ي': [
      [[0.5, 0.2], [0.5, 0.8], [0.3, 0.9]], // Ya: Garis dengan ekor
      [[0.5, 0.9], [0.5, 0.9]], // Dua titik di bawah
    ],
  };

  // Mapping huruf ke index kelas model (sesuaikan dengan urutan training: 'ا'=0, 'ب'=1, dst.)
  static const Map<String, int> _letterToClassIndex = {
    'ا': 0, 'ب': 1, 'ج': 2, 'د': 3, 'ذ': 4, 'ر': 5, 'ز': 6, 'س': 7, 'ش': 8,
    'ص': 9, 'ض': 10, 'ط': 11, 'ظ': 12, 'ع': 13, 'غ': 14, 'ف': 15, 'ق': 16,
    'ك': 17, 'ل': 18, 'م': 19, 'ن': 20, 'ه': 21, 'ح': 22, 'خ': 23, 'ت': 24,
    'ث': 25, 'و': 26, 'ي': 27,
  };

  void initialize(String letter) {
    _loadModel();
    if (!_modelLoaded && _templates.containsKey(letter)) {
      print('Using template for $letter in simulate mode');
    }
  }

  Future<void> _loadModel() async {
    try {
      _interpreter = await tfl.Interpreter.fromAsset('assets/models/best_model.tflite');
      _modelLoaded = true;
      print('Model loaded successfully');
      
      // Debug model details
      print('Input tensors: ${_interpreter!.getInputTensors()}');
      print('Output tensors: ${_interpreter!.getOutputTensors()}');
      
      // Test the model with a sample input
      await _testModelWithSample();
    } catch (e, stackTrace) {
      _modelLoaded = false;
      print('Failed to load model: $e');
      print('Stack trace: $stackTrace');
    }
  }

  void dispose() {
    _interpreter?.close();
    _audioPlayer.dispose();
    _feedbackController.close();
    _feedbackTimer?.cancel();
  }

  void startTracing(Offset localPosition) {
    if (showFeedback) {
      hideFeedback();
    }
    if (!isTracing) {
      strokes.add([localPosition]);
      currentStrokeIndex = strokes.length - 1;
      isTracing = true;
    } else {
      strokes[currentStrokeIndex].add(localPosition);
    }
    _feedbackController.add({'pointsUpdated': true});
  }

  void updateTracing(Offset localPosition) {
    if (isTracing && strokes.isNotEmpty) {
      strokes[currentStrokeIndex].add(localPosition);
      _feedbackController.add({'pointsUpdated': true});
    }
  }

  void endTracing() {
    isTracing = false;
    _feedbackController.add({'endStroke': true});
  }

  Future<void> playSound(String pronunciation) async {
    try {
      String cleanedPronunciation = pronunciation.replaceAll(RegExp(r'[^\w]'), '');
      String? audioFileName = _audioMapping.values.firstWhere(
        (value) => value.toLowerCase() == cleanedPronunciation.toLowerCase(),
        orElse: () => cleanedPronunciation,
      );
      final String audioPath = 'audio/$audioFileName.m4a';
      print('Attempting to play audio: $audioPath');
      await _audioPlayer.play(AssetSource(audioPath));
    } catch (e) {
      print('Failed to play sound: $e');
      HapticFeedback.lightImpact();
    }
  }

  Future<void> checkTracing(String letter) async {
    if (strokes.isEmpty || strokes.every((stroke) => stroke.isEmpty)) {
      _showFeedback(false, 'Please trace the letter first');
      return;
    }

    isProcessing = true;
    _feedbackController.add({'processing': true});

    await Future.delayed(Duration(milliseconds: 300));

    bool result = false;
    
    if (_modelLoaded) {
      result = await _validateWithCNN(strokes, letter);
      // If CNN fails, try template matching as fallback
      if (!result) {
        result = await _simulateValidation(strokes, letter);
      }
    } else {
      result = await _simulateValidation(strokes, letter);
    }
    
    _showFeedback(result, result ? 'Great job!' : 'Try again!');

    isProcessing = false;
  }

  Future<bool> _validateWithCNN(List<List<Offset>> allStrokes, String letter) async {
    try {
      if (canvasSize == null) {
        print('Error: canvasSize is null');
        return false;
      }

      const int imageSize = 32;
      const int channels = 1;
      
      // Create a proper stroke rendering with thickness
      List<List<double>> image = List.generate(imageSize, (_) => List.filled(imageSize, 0.0));

      // Render strokes with thickness
      for (var stroke in allStrokes) {
        if (stroke.length < 2) continue;
        
        for (int i = 1; i < stroke.length; i++) {
          Offset p1 = stroke[i-1];
          Offset p2 = stroke[i];
          
          // Convert to normalized coordinates
          double x1 = p1.dx / canvasSize!.width;
          double y1 = p1.dy / canvasSize!.height;
          double x2 = p2.dx / canvasSize!.width;
          double y2 = p2.dy / canvasSize!.height;
          
          // Draw line with thickness
          _drawLine(image, x1, y1, x2, y2, imageSize);
        }
      }

      // Normalize and prepare input
      List<double> flattened = _normalizeImage(image, imageSize);
      
      var input = _reshapeTo4D(flattened, 1, imageSize, imageSize, channels);
      List<List<double>> output = [List.filled(28, 0.0)];

      if (_interpreter != null) {
        print('Running CNN for $letter with input shape: [1, $imageSize, $imageSize, $channels]');
        print('Sample input[0][0][0]: ${input[0][0][0][0]}');
        _interpreter!.run(input, output);

        int classIndex = _letterToClassIndex[letter] ?? 0;
        double confidence = output[0][classIndex];
        print('CNN output for $letter (class $classIndex): $confidence');
        
        // Also print the top 3 predictions for debugging
        List<double> predictions = List.from(output[0]);
        predictions.asMap().forEach((index, value) {
          if (value > 0.1) {
            String predictedLetter = _letterToClassIndex.entries.firstWhere(
              (entry) => entry.value == index,
              orElse: () => MapEntry('?', -1)
            ).key;
            print('  Class $index ($predictedLetter): $value');
          }
        });
        
        return confidence > 0.5;
      }
      print('Error: Interpreter is null');
      return false;
    } catch (e, stackTrace) {
      print('CNN error for $letter: $e');
      print('Stack trace: $stackTrace');
      return false;
    }
  }

  void _drawLine(List<List<double>> image, double x1, double y1, double x2, double y2, int size) {
    int steps = 20; // Increased steps for smoother lines
    for (int i = 0; i <= steps; i++) {
      double t = i / steps;
      double x = x1 + t * (x2 - x1);
      double y = y1 + t * (y2 - y1);
      
      int px = (x * (size - 1)).round().clamp(0, size - 1);
      int py = (y * (size - 1)).round().clamp(0, size - 1);
      
      // Set pixel and neighbors for thickness (3x3 brush)
      for (int dy = -1; dy <= 1; dy++) {
        for (int dx = -1; dx <= 1; dx++) {
          int nx = (px + dx).clamp(0, size - 1);
          int ny = (py + dy).clamp(0, size - 1);
          image[ny][nx] = 1.0;
        }
      }
    }
  }

  List<double> _normalizeImage(List<List<double>> image, int size) {
    List<double> flattened = [];
    for (int y = 0; y < size; y++) {
      for (int x = 0; x < size; x++) {
        flattened.add(image[y][x]);
      }
    }
    return flattened;
  }

  // Helper to reshape flattened list to 4D [batch, height, width, channels]
  List<List<List<List<double>>>> _reshapeTo4D(List<double> flattened, int batch, int height, int width, int channels) {
    if (flattened.length != batch * height * width * channels) {
      print('Warning: Flattened length (${flattened.length}) does not match expected (${batch * height * width * channels})');
      // Pad or truncate to match expected length
      while (flattened.length < batch * height * width * channels) {
        flattened.add(0.0);
      }
      flattened = flattened.sublist(0, batch * height * width * channels);
    }

    List<List<List<List<double>>>> result = [];
    int index = 0;
    for (int b = 0; b < batch; b++) {
      List<List<List<double>>> batchData = [];
      for (int h = 0; h < height; h++) {
        List<List<double>> heightData = [];
        for (int w = 0; w < width; w++) {
          List<double> channelData = [];
          for (int c = 0; c < channels; c++) {
            channelData.add(flattened[index++]);
          }
          heightData.add(channelData);
        }
        batchData.add(heightData);
      }
      result.add(batchData);
    }
    return result;
  }

  Future<void> _testModelWithSample() async {
    if (_interpreter == null) return;
    
    const int imageSize = 32;
    const int channels = 1;
    
    // Create a simple test pattern (horizontal line)
    List<List<double>> testImage = List.generate(imageSize, (_) => List.filled(imageSize, 0.0));
    for (int x = 5; x < imageSize - 5; x++) {
      for (int dy = -1; dy <= 1; dy++) {
        testImage[imageSize ~/ 2 + dy][x] = 1.0;
      }
    }
    
    List<double> flattened = _normalizeImage(testImage, imageSize);
    var input = _reshapeTo4D(flattened, 1, imageSize, imageSize, channels);
    List<List<double>> output = [List.filled(28, 0.0)];
    
    _interpreter!.run(input, output);
    
    print('Sample test output:');
    // Find top 3 predictions
    List<MapEntry<int, double>> predictions = [];
    for (int i = 0; i < output[0].length; i++) {
      predictions.add(MapEntry(i, output[0][i]));
    }
    
    predictions.sort((a, b) => b.value.compareTo(a.value));
    
    for (int i = 0; i < math.min(3, predictions.length); i++) {
      int classIndex = predictions[i].key;
      double confidence = predictions[i].value;
      String letter = _letterToClassIndex.entries.firstWhere(
        (entry) => entry.value == classIndex,
        orElse: () => MapEntry('?', -1)
      ).key;
      print('  Class $classIndex ($letter): $confidence');
    }
  }

  Future<bool> _simulateValidation(List<List<Offset>> allStrokes, String letter) async {
    await Future.delayed(Duration(milliseconds: 500));
    if (!_templates.containsKey(letter)) {
      print('No template for $letter, fallback to length check');
      double totalLength = 0;
      for (var stroke in allStrokes) {
        for (int i = 1; i < stroke.length; i++) {
          totalLength += (stroke[i] - stroke[i - 1]).distance;
        }
      }
      bool result = totalLength > 100;
      print('Length check for $letter: $totalLength > 100? $result');
      return result;
    }

    final template = _templates[letter]!;
    double bestMatch = 0.0;
    if (allStrokes.length != template.length) {
      print('Stroke count mismatch for $letter: ${allStrokes.length} vs ${template.length}');
      return false;
    }

    for (int i = 0; i < allStrokes.length; i++) {
      double similarity = _calculateStrokeSimilarity(allStrokes[i], template[i], canvasSize!);
      bestMatch = math.max(bestMatch, similarity);
    }
    bool result = bestMatch > 0.8;
    print('Simulate for $letter: Best match $bestMatch > 0.8? $result');
    return result;
  }

  double _calculateStrokeSimilarity(List<Offset> userStroke, List<List<double>> template, Size canvasSize) {
    if (userStroke.length < 2 || template.length < 2) return 0.0;
    double totalDistance = 0.0;
    int sampleCount = math.min(userStroke.length, template.length);

    for (int i = 0; i < sampleCount; i++) {
      final userNorm = Offset(
        userStroke[i * userStroke.length ~/ sampleCount].dx / canvasSize.width,
        userStroke[i * userStroke.length ~/ sampleCount].dy / canvasSize.height,
      );
      final tempPoint = Offset(template[i][0], template[i][1]);
      totalDistance += (userNorm - tempPoint).distance;
    }

    double avgDistance = totalDistance / sampleCount;
    return math.max(0.0, 1.0 - (avgDistance / math.sqrt(2.0)));
  }

  void _showFeedback(bool correct, String message) {
    _feedbackTimer?.cancel();
    showFeedback = true;
    isCorrect = correct;
    if (correct) {
      HapticFeedback.heavyImpact();
    } else {
      HapticFeedback.mediumImpact();
    }
    print('Feedback for letter: $message (correct: $correct)');
    _feedbackController.add({'showFeedback': true, 'isCorrect': correct});
    _feedbackTimer = Timer(Duration(milliseconds: 2500), () {
      hideFeedback();
    });
  }

  void hideFeedback() {
    if (showFeedback) {
      showFeedback = false;
      _feedbackController.add({'showFeedback': false});
    }
  }

  void clearTracing() {
    strokes.clear();
    currentStrokeIndex = 0;
    hideFeedback();
    _feedbackController.add({'clear': true});
  }

  void setCanvasSize(Size size) {
    canvasSize = size;
  }

  List<List<Offset>> get allStrokes => strokes;
  bool get hasStrokes => strokes.any((stroke) => stroke.isNotEmpty);
}