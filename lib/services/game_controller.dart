// lib/services/game_controller.dart
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math';
import '../models/hijaiyah_data.dart';

class GameController {
  final AudioPlayer audioPlayer;
  List<Map<String, String>> shuffledLetters = List.from(hijaiyahLetters);
  int currentAudioIndex = 0;
  int centerCardIndex = 0;
  bool isPlayingAudio = false;
  String feedbackMessage = '';
  Color feedbackColor = Colors.transparent;
  bool showFeedback = false;
  Map<int, Offset> cardDragPositions = {};
  Map<int, bool> isDragging = {};
  double validationThreshold = 0.0;

  GameController(this.audioPlayer) {
    _shuffleGame();
  }

  void _shuffleGame() {
    shuffledLetters.shuffle(Random());
    currentAudioIndex = Random().nextInt(hijaiyahLetters.length);
    centerCardIndex = shuffledLetters.length ~/ 2;
    cardDragPositions.clear();
    isDragging.clear();
    showFeedback = false;
  }

  Future<void> playRandomAudio(void Function(VoidCallback) setState, BuildContext context) async {
    if (isPlayingAudio) return;

    setState(() {
      isPlayingAudio = true;
      showFeedback = false;
    });

    try {
      String audioPath = 'audio/${hijaiyahLetters[currentAudioIndex]['audio']}';
      await audioPlayer.play(AssetSource(audioPath));
      HapticFeedback.mediumImpact();
    } catch (e) {
      print('Error playing audio: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Playing: ${hijaiyahLetters[currentAudioIndex]['name']}'),
          duration: Duration(milliseconds: 800),
        ),
      );
    }

    Future.delayed(Duration(seconds: 2), () {
      setState(() {
        isPlayingAudio = false;
      });
    });
  }

  void validateAnswer(int cardIndex, void Function(VoidCallback) setState, BuildContext context) async {
    String selectedLetter = shuffledLetters[cardIndex]['name']!;
    String correctLetter = hijaiyahLetters[currentAudioIndex]['name']!;
    bool isCorrect = selectedLetter == correctLetter;

    setState(() {
      showFeedback = true;
      feedbackMessage = isCorrect ? 'Benar!' : 'Salah!';
      feedbackColor = isCorrect ? Colors.green : Colors.red;
    });

    try {
      String feedbackAudio = isCorrect ? 'audio/benar.m4a' : 'audio/salah.m4a';
      await audioPlayer.play(AssetSource(feedbackAudio));
    } catch (e) {
      print('Error playing feedback audio: $e');
    }

    if (isCorrect) {
      HapticFeedback.heavyImpact();
    } else {
      HapticFeedback.vibrate();
    }

    setState(() {
      cardDragPositions.remove(cardIndex);
      isDragging.remove(cardIndex);
    });

    Future.delayed(Duration(seconds: 2), () {
      if (context.mounted) {
        setState(_generateNewQuestion);
      }
    });
  }

  void _generateNewQuestion() {
    currentAudioIndex = Random().nextInt(hijaiyahLetters.length);
    showFeedback = false;
    cardDragPositions.clear();
    isDragging.clear();
  }

  void shuffleGame(void Function(VoidCallback) setState) {
    setState(_shuffleGame);
  }

  void updateCenterCardIndex(int index, void Function(VoidCallback) setState) {
    setState(() {
      centerCardIndex = index;
    });
  }
}