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
  Set<String> correctlyAnsweredLetters = {};
  bool isGameCompleted = false;
  List<int> availableAudioIndices = List.generate(
    hijaiyahLetters.length,
    (index) => index,
  );

  GameController(this.audioPlayer) {
    _shuffleGame();
  }

  void _shuffleGame() {
    if (isGameCompleted) return;
    shuffledLetters.shuffle(Random());
    _updateCurrentAudioIndex();
    centerCardIndex = shuffledLetters.length ~/ 2;
    cardDragPositions.clear();
    isDragging.clear();
    showFeedback = false;
  }

  void _updateCurrentAudioIndex() {
    if (availableAudioIndices.isNotEmpty) {
      currentAudioIndex =
          availableAudioIndices[Random().nextInt(availableAudioIndices.length)];
    } else {
      isGameCompleted = true;
    }
  }

  Future<void> playRandomAudio(
    void Function(VoidCallback) setState,
    BuildContext context,
  ) async {
    if (isPlayingAudio || isGameCompleted) return;

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
          content: Text(
            'Playing: ${hijaiyahLetters[currentAudioIndex]['name']}',
          ),
          duration: Duration(milliseconds: 800),
        ),
      );
    }

    Future.delayed(Duration(seconds: 2), () {
      if (context.mounted) {
        setState(() {
          isPlayingAudio = false;
        });
      }
    });
  }

  void validateAnswer(
    int cardIndex,
    void Function(VoidCallback) setState,
    BuildContext context,
  ) async {
    if (isGameCompleted) return;

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
      correctlyAnsweredLetters.add(correctLetter);
      availableAudioIndices.remove(currentAudioIndex);
      if (correctlyAnsweredLetters.length == hijaiyahLetters.length) {
        isGameCompleted = true;
        _showCompletionDialog(context);
      }
    } else {
      HapticFeedback.vibrate();
    }

    // Hanya clear drag state tanpa remove kartu
    setState(() {
      cardDragPositions.remove(cardIndex);
      isDragging.remove(cardIndex);
    });

    // Jika benar, hapus kartu dari list dengan animasi
    if (isCorrect) {
      Future.delayed(Duration(milliseconds: 1500), () {
        if (context.mounted && !isGameCompleted) {
          setState(() {
            // Remove correct card from shuffledLetters
            shuffledLetters.removeAt(cardIndex);
            // Adjust centerCardIndex if needed
            if (centerCardIndex >= shuffledLetters.length &&
                shuffledLetters.isNotEmpty) {
              centerCardIndex = shuffledLetters.length - 1;
            }
            if (shuffledLetters.isEmpty) {
              centerCardIndex = 0;
            }
          });
        }
      });
    }

    // Generate question baru setelah feedback selesai
    Future.delayed(Duration(seconds: 2), () {
      if (context.mounted && !isGameCompleted) {
        setState(_generateNewQuestion);
      }
    });
  }

  void _generateNewQuestion() {
    if (shuffledLetters.isNotEmpty) {
      _updateCurrentAudioIndex();
    }
    showFeedback = false;
    cardDragPositions.clear();
    isDragging.clear();
  }

  void _showCompletionDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Color(0xFFF5F5DC),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.celebration, color: Color(0xFFFF8C42), size: 60),
              SizedBox(height: 16),
              Text(
                'Selamat!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                  fontFamily: 'OpenDyslexic',
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Kamu berhasil mengenali semua huruf hijaiyah!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black,
                  fontFamily: 'OpenDyslexic',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              child: Text(
                'Kembali',
                style: TextStyle(
                  color: Color(0xFFFF8C42),
                  fontSize: 16,
                  fontFamily: 'OpenDyslexic',
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void shuffleGame(
    void Function(VoidCallback) setState, {
    PageController? pageController,
  }) {
    setState(() {
      _shuffleGame();
      // Notify that PageController should be updated
      if (pageController != null) {
        // Use post-frame callback to ensure the setState completes first
        WidgetsBinding.instance.addPostFrameCallback((_) {
          pageController.animateToPage(
            centerCardIndex,
            duration: Duration(milliseconds: 400),
            curve: Curves.easeInOut,
          );
        });
      }
    });
  }

  void updateCenterCardIndex(int index, void Function(VoidCallback) setState) {
    setState(() {
      centerCardIndex = index;
    });
  }

  // Method to sync PageController with centerCardIndex after shuffle
  void syncPageController(PageController pageController) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (pageController.hasClients) {
        pageController.animateToPage(
          centerCardIndex,
          duration: Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  double get progress =>
      correctlyAnsweredLetters.length / hijaiyahLetters.length;
}
