// lib/screens/hijaiyah_recognition_game.dart
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import '../services/game_controller.dart';
import '../widgets/flashcard_widget.dart';
import '../widgets/dashed_border_painter.dart';

class HijaiyahRecognitionGame extends StatefulWidget {
  @override
  HijaiyahRecognitionGameState createState() => HijaiyahRecognitionGameState();
}

class HijaiyahRecognitionGameState extends State<HijaiyahRecognitionGame>
    with TickerProviderStateMixin {
  late GameController _gameController;
  late AnimationController _feedbackController;
  late AnimationController _pulseController;
  late Animation<double> _feedbackAnimation;
  late Animation<double> _pulseAnimation;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _gameController = GameController(AudioPlayer());
    _setupAnimations();

    _pageController = PageController(
      viewportFraction: 0.3,
      initialPage: _gameController.centerCardIndex,
    );
  }

  void _setupAnimations() {
    _feedbackController = AnimationController(
      duration: Duration(milliseconds: 1500),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: Duration(milliseconds: 1000),
      vsync: this,
    );

    _feedbackAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _feedbackController,
      curve: Curves.elasticOut,
    ));

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.25,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _pulseController.addStatusListener((status) {
      if (status == AnimationStatus.completed &&
          _gameController.isPlayingAudio) {
        _pulseController.reverse();
      } else if (status == AnimationStatus.dismissed &&
          _gameController.isPlayingAudio) {
        _pulseController.forward();
      }
    });
  }

  @override
  void dispose() {
    _gameController.audioPlayer.dispose();
    _feedbackController.dispose();
    _pulseController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _onPanStart(int index) {
    setState(() {
      _gameController.isDragging[index] = true;
    });
  }

  void _onPanUpdate(int index, DragUpdateDetails details) {
    setState(() {
      _gameController.cardDragPositions[index] =
          (_gameController.cardDragPositions[index] ?? Offset.zero) +
              details.delta;
    });
  }

  void _onPanEnd(int index, DragEndDetails details) {
    Offset currentPosition =
        _gameController.cardDragPositions[index] ?? Offset.zero;

    if (currentPosition.dy < -_gameController.validationThreshold * 0.3) {
      _gameController.validateAnswer(index, setState, context);
      _feedbackController.forward().then((_) => _feedbackController.reverse());
    } else {
      setState(() {
        _gameController.cardDragPositions.remove(index);
        _gameController.isDragging.remove(index);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    _gameController.validationThreshold =
        MediaQuery.of(context).size.height * 0.5;

    return Scaffold(
      backgroundColor: Color(0xFFF5F5DC),
      body: SafeArea(
        child: Column(
          children: [
            // HEADER
            Padding(
              padding: EdgeInsets.all(4.0),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Color(0xFFDEB887),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: Icon(Icons.arrow_back, color: Colors.black, size: 20),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'Tebak Hijaiyah',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                        fontFamily: 'OpenDyslexic',
                      ),
                    ),
                  ),
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Color(0xFFFF8C42),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: IconButton(
                      icon: Icon(Icons.shuffle, color: Colors.white, size: 20),
                      onPressed: () => _gameController.shuffleGame(setState),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 30),

            // AUDIO BUTTON
            Container(
              width: 280,
              height: 280,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CustomPaint(
                    size: Size(280, 280),
                    painter: DashedBorderPainter(
                      color: Color(0xFFFF8C42),
                      strokeWidth: 4,
                      dashWidth: 12,
                      dashSpace: 6,
                    ),
                  ),
                  Container(
                    width: 260,
                    height: 260,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Color(0xFFFF8C42).withOpacity(0.3),
                          blurRadius: 30,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                  ),
                  AnimatedBuilder(
                    animation: _pulseAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale:
                            _gameController.isPlayingAudio ? _pulseAnimation.value : 1.0,
                        child: GestureDetector(
                          onTap: () {
                            _pulseController.forward();
                            _gameController.playRandomAudio(setState, context);
                          },
                          child: Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Color(0xFFFED7AA),
                                  Color(0xFFDEB887),
                                  Color(0xFFC9A96E),
                                ],
                              ),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.3),
                                  blurRadius: 15,
                                  offset: Offset(0, 8),
                                  spreadRadius: 2,
                                ),
                                BoxShadow(
                                  color: Colors.white.withOpacity(0.4),
                                  blurRadius: 8,
                                  offset: Offset(-2, -2),
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                            child: Icon(
                              _gameController.isPlayingAudio
                                  ? Icons.volume_up
                                  : Icons.play_arrow,
                              size: 48,
                              color: Color(0xFFFF8C42),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            SizedBox(height: 40),

            // FEEDBACK
            if (_gameController.showFeedback)
              AnimatedBuilder(
                animation: _feedbackAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _feedbackAnimation.value,
                    child: Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                        color: _gameController.feedbackColor,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _gameController.feedbackMessage,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontFamily: 'OpenDyslexic',
                        ),
                      ),
                    ),
                  );
                },
              ),

            SizedBox(height: 20),

            // FLASHCARDS SECTION
            Expanded(
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // PageView cards
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Container(
                      height: 180,
                      child: PageView.builder(
                        controller: _pageController,
                        onPageChanged: (index) => _gameController
                            .updateCenterCardIndex(index, setState),
                        itemCount: _gameController.shuffledLetters.length,
                        itemBuilder: (context, index) {
                          return _buildTightSpacingFlashcard(index);
                        },
                      ),
                    ),
                  ),

                  // Card yang sedang di-drag selalu di atas (tanpa bayangan)
                  ..._gameController.isDragging.entries.map((entry) {
                    final index = entry.key;
                    final pos =
                        _gameController.cardDragPositions[index] ?? Offset.zero;

                    return Positioned(
                      top: pos.dy + 400, // sesuaikan posisi awal
                      left: pos.dx +
                          MediaQuery.of(context).size.width * 0.35, // biar center
                      child: Material(
                        elevation: 0, // <-- flat
                        shadowColor: Colors.transparent, // <-- no shadow
                        borderRadius: BorderRadius.circular(20),
                        color: Colors.transparent,
                        child: FlashcardWidget(
                          index: index,
                          controller: _gameController,
                          onPanStart: () => _onPanStart(index),
                          onPanUpdate: (details) => _onPanUpdate(index, details),
                          onPanEnd: (details) => _onPanEnd(index, details),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),

            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildTightSpacingFlashcard(int index) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 2.0),
      child: Container(
        width: 140,
        height: 120,
        color: Colors.transparent,
        child: FlashcardWidget(
          index: index,
          controller: _gameController,
          onPanStart: () => _onPanStart(index),
          onPanUpdate: (details) => _onPanUpdate(index, details),
          onPanEnd: (details) => _onPanEnd(index, details),
        ),
      ),
    );
  }
}
