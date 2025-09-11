import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class TracingService {
  List<Offset> tracingPoints = [];
  bool isTracing = false;
  bool showFeedback = false;
  bool isCorrect = false;
  bool isProcessing = false;

  // Interpreter? _interpreter;
  // FlutterTts? _flutterTts;

  void initialize() async {
    // TODO: Load CNN model
    // try {
    //   _interpreter = await Interpreter.fromAsset('assets/models/best_model.keras');
    //   print('Model loaded successfully');
    // } catch (e) {
    //   print('Failed to load model: $e');
    // }

    // TODO: Initialize Text-to-Speech
    // _flutterTts = FlutterTts();
    // await _flutterTts?.setLanguage('ar');
    // await _flutterTts?.setPitch(1.0);
    // await _flutterTts?.setSpeechRate(0.5);
  }

  void dispose() {
    // _interpreter?.close();
    // _flutterTts?.stop();
    // _flutterTts?.release();
  }

  void startTracing(DragStartDetails details) {
    RenderBox? renderBox = details.globalPosition & Size.zero as RenderBox?;
    if (renderBox == null) return;
    Offset localPosition = renderBox.globalToLocal(details.globalPosition);
    tracingPoints.clear();
    showFeedback = false;
    tracingPoints.add(localPosition);
    isTracing = true;
  }

  void updateTracing(DragUpdateDetails details) {
    if (isTracing) {
      RenderBox? renderBox = details.globalPosition & Size.zero as RenderBox?;
      if (renderBox == null) return;
      Offset localPosition = renderBox.globalToLocal(details.globalPosition);
      tracingPoints.add(localPosition);
    }
  }

  void endTracing(DragEndDetails details) {
    isTracing = false;
  }

  void playSound() {
    // TODO: Play letter pronunciation
    // await _flutterTts?.speak(widget.letter);

    // Placeholder with haptic feedback
    HapticFeedback.lightImpact();
    // Show temporary visual feedback
    // Assuming context is available via a callback or widget
  }

  Future<void> checkTracing() async {
    if (tracingPoints.isEmpty) {
      _showFeedback(false, 'Please trace the letter first');
      return;
    }

    isProcessing = true;
    // TODO: Preprocess tracing data and run CNN prediction
    // bool result = await _validateWithCNN();

    // For demo purposes, simulate validation
    bool result = await _simulateValidation();

    _showFeedback(result, result ? 'Great job!' : 'Try again!');
    isProcessing = false;
  }

  Future<bool> _simulateValidation() async {
    await Future.delayed(Duration(milliseconds: 800));
    return tracingPoints.length > 10;
  }

  void _showFeedback(bool correct, String message) {
    showFeedback = true;
    isCorrect = correct;
    if (correct) {
      HapticFeedback.heavyImpact();
    } else {
      HapticFeedback.vibrate();
    }
    // Hide feedback after 2 seconds
    Future.delayed(Duration(seconds: 2), () {
      showFeedback = false;
    });
  }

  void clearTracing() {
    tracingPoints.clear();
    showFeedback = false;
  }
}