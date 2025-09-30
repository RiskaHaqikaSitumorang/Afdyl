import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import '../services/game_controller.dart';
import '../widgets/flashcard_widget.dart';
import '../widgets/dashed_border_painter.dart';
import '../constants/app_colors.dart';

class HijaiyahRecognitionGame extends StatefulWidget {
  @override
  HijaiyahRecognitionGameState createState() => HijaiyahRecognitionGameState();
}

class HijaiyahRecognitionGameState extends State<HijaiyahRecognitionGame>
    with TickerProviderStateMixin {
  // Constants
  static const double cardSize = 140.0;

  late GameController _gameController;
  late AnimationController _feedbackController;
  late AnimationController _returnController; // For snap-back animation
  late Animation<double> _feedbackAnimation;
  Animation<Offset>? _returnAnimation; // Active offset tween
  late PageController _pageController;

  // For drag overlay management
  int? _draggedCardIndex;
  Offset _draggedCardPosition = Offset.zero;

  int? _returningIndex; // Which index is currently animating back

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

    _returnController = AnimationController(
      duration: const Duration(milliseconds: 220),
      vsync: this,
    );

    _returnController.addStatusListener((status) {
      if (status == AnimationStatus.completed && _returningIndex != null) {
        // Reset drag state after animation finishes
        setState(() {
          _gameController.cardDragPositions.remove(_returningIndex);
          _gameController.isDragging.remove(_returningIndex);
          _returningIndex = null;
        });
      }
    });

    _feedbackAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _feedbackController, curve: Curves.elasticOut),
    );
  }

  @override
  void dispose() {
    _gameController.audioPlayer.dispose();
    _feedbackController.dispose();
    _returnController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _onPanStart(int index) {
    _draggedCardIndex = index;
    _draggedCardPosition = Offset(0, -cardSize);
    _gameController.isDragging[index] = true;
    setState(() {});
  }

  void _onPanUpdate(int index, DragUpdateDetails details) {
    if (_draggedCardIndex == index) {
      _draggedCardPosition += details.delta;
      setState(() {});
    }
  }

  void _onPanEnd(int index, DragEndDetails details) {
    // Check if dragged up enough to validate
    if (_draggedCardPosition.dy < -_gameController.validationThreshold * 0.3) {
      _gameController.validateAnswer(index, setState, context);
      _feedbackController.forward().then((_) => _feedbackController.reverse());
    } else {
      // Snap back animation for incorrect drop
      _snapBackCard(index);
    }

    // Reset drag overlay
    _draggedCardIndex = null;
    _draggedCardPosition = Offset.zero;
  }

  void _snapBackCard(int index) {
    _returningIndex = index;

    final startOffset = _draggedCardPosition;
    final endOffset = Offset.zero;

    _returnAnimation = Tween<Offset>(
      begin: startOffset,
      end: endOffset,
    ).animate(
      CurvedAnimation(parent: _returnController, curve: Curves.elasticOut),
    );

    _returnController.reset();
    _returnController.forward();

    _returnController.addListener(() {
      if (_returningIndex == index) {
        _draggedCardPosition = _returnAnimation!.value;
        setState(() {});
      }
    });
  }

  bool _isCardInDropZone() {
    if (_draggedCardIndex == null) return false;

    final screenHeight = MediaQuery.of(context).size.height;
    final baseY = screenHeight - 200 + 30;
    final currentY = baseY + _draggedCardPosition.dy;

    return currentY < _gameController.validationThreshold * 0.7;
  }

  Widget _buildDraggedCardOverlay() {
    if (_draggedCardIndex == null) return const SizedBox.shrink();

    final index = _draggedCardIndex!;
    final letter = _gameController.shuffledLetters[index]['letter']!;
    final name = _gameController.shuffledLetters[index]['name']!;

    // Calculate position - we need to find where the card would be in PageView
    // and then apply the drag offset
    final screenWidth = MediaQuery.of(context).size.width;

    // Calculate center position based on PageView layout
    double baseX = (screenWidth - cardSize) / 2;
    double baseY = MediaQuery.of(context).size.height - 200 + 30;

    // Check if card is in drop zone
    final currentY = baseY + _draggedCardPosition.dy;
    final isInDropZone = currentY < _gameController.validationThreshold * 0.7;

    return Positioned(
      left: baseX + _draggedCardPosition.dx,
      top: currentY,
      child: Material(
        elevation: 20.0,
        shadowColor: Colors.black.withOpacity(0.4),
        borderRadius: BorderRadius.circular(15),
        color: Colors.transparent,
        child: Container(
          width: cardSize,
          height: cardSize, // Square shape
          decoration: BoxDecoration(
            color: const Color(0xFFEDD1B0),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color:
                  isInDropZone
                      ? Colors.green.withOpacity(0.8)
                      : Colors.blue.withOpacity(0.6),
              width: isInDropZone ? 3 : 2,
            ),
            boxShadow:
                isInDropZone
                    ? [
                      BoxShadow(
                        color: Colors.green.withOpacity(0.3),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ]
                    : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                letter,
                style: const TextStyle(
                  fontSize: 50,
                  fontFamily: 'Maqroo',
                  color: Colors.black87,
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '($name)',
                style: const TextStyle(
                  fontSize: 14,
                  fontFamily: 'OpenDyslexic',
                  color: Colors.black54,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    _gameController.validationThreshold =
        MediaQuery.of(context).size.height * 0.5;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        toolbarHeight: 80,
        leading: Container(
          width: 40,
          height: 40,
          margin: const EdgeInsets.only(top: 8.0, left: 16.0),
          decoration: BoxDecoration(
            color: AppColors.tertiary.withOpacity(0.4),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: const Icon(
              Icons.chevron_left,
              color: AppColors.tertiary,
              size: 25,
            ),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ),
        title: Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Text(
            'Tebak Hijaiyah',
            style: const TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.w600,
              fontSize: 18,
              fontFamily: 'OpenDyslexic',
            ),
          ),
        ),
        // actions: [
        //   Container(
        //     margin: const EdgeInsets.only(top: 8.0, right: 16.0),
        //     width: 40,
        //     height: 40,
        //     decoration: BoxDecoration(
        //       color: AppColors.tertiary.withOpacity(0.4),
        //       shape: BoxShape.circle,
        //     ),
        //     child: IconButton(
        //       icon: Image.asset(
        //         'assets/images/ic_shuffle.png',
        //         width: 20,
        //         height: 20,
        //         color: AppColors.tertiary,
        //       ),
        //       onPressed:
        //           _gameController.isGameCompleted
        //               ? null
        //               : () => _gameController.shuffleGame(setState),
        //     ),
        //   ),
        // ],
      ),
      body: SafeArea(
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Column(
              children: [
                SizedBox(height: 30),
                // PROGRESS BAR
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24.0),
                  child: Row(
                    children: [
                      Text(
                        'Mulai',
                        style: TextStyle(
                          fontSize: 14,
                          fontFamily: 'OpenDyslexic',
                          color: Color(0xFFFF8C42),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: Container(
                          height: 8,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: _gameController.progress,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Color(0xFFFF8C42),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 16),
                      Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color:
                              _gameController.progress >= 1.0
                                  ? Color(0xFFFF8C42)
                                  : Colors.grey[300],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.flag,
                          size: 20,
                          color:
                              _gameController.progress >= 1.0
                                  ? Colors.white
                                  : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 40),

                // DROP ZONE & AUDIO BUTTON
                Container(
                  width: 280,
                  height: 280,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Drop zone background
                      AnimatedContainer(
                        duration: Duration(milliseconds: 200),
                        width: 280,
                        height: 280,
                        decoration: BoxDecoration(
                          color:
                              _isCardInDropZone()
                                  ? Colors.green.withOpacity(0.1)
                                  : Colors.transparent,
                          borderRadius: BorderRadius.circular(140),
                        ),
                      ),
                      // Dashed border
                      CustomPaint(
                        size: Size(280, 280),
                        painter: DashedBorderPainter(
                          color:
                              _isCardInDropZone()
                                  ? Colors.green
                                  : AppColors.tertiary,
                          strokeWidth: _isCardInDropZone() ? 5 : 4,
                          dashWidth: 12,
                          dashSpace: 6,
                        ),
                      ),
                      // Audio button
                      GestureDetector(
                        onTap:
                            _gameController.isGameCompleted
                                ? null
                                : () {
                                  _gameController.playRandomAudio(
                                    setState,
                                    context,
                                  );
                                },
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            AnimatedContainer(
                              duration: Duration(milliseconds: 300),
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color:
                                    _gameController.isPlayingAudio
                                        ? (_isCardInDropZone()
                                            ? Colors.green.withOpacity(0.5)
                                            : AppColors.tertiary.withOpacity(
                                              0.5,
                                            ))
                                        : (_isCardInDropZone()
                                            ? Colors.green.withOpacity(0.3)
                                            : AppColors.tertiary.withOpacity(
                                              0.3,
                                            )),
                                shape: BoxShape.circle,
                                border:
                                    _gameController.isPlayingAudio
                                        ? Border.all(
                                          color:
                                              _isCardInDropZone()
                                                  ? Colors.green
                                                  : AppColors.tertiary,
                                          width: 3,
                                        )
                                        : null,
                              ),
                              child: Icon(
                                _gameController.isPlayingAudio
                                    ? Icons.volume_up
                                    : Icons.play_arrow,
                                size: _gameController.isPlayingAudio ? 52 : 48,
                                color:
                                    _isCardInDropZone()
                                        ? Colors.green
                                        : AppColors.tertiary,
                              ),
                            ),
                            SizedBox(height: 12),
                            Text(
                              _gameController.isPlayingAudio
                                  ? 'Sedang memutar audio...'
                                  : (_draggedCardIndex != null &&
                                          _isCardInDropZone()
                                      ? 'Lepaskan kartu di sini!'
                                      : 'Tap untuk dengar, lalu drag kartu hijaiyah ke area ini'),
                              style: TextStyle(
                                fontSize: 16,
                                color:
                                    _gameController.isPlayingAudio
                                        ? Colors.orange
                                        : (_draggedCardIndex != null &&
                                                _isCardInDropZone()
                                            ? Colors.green
                                            : Color(0xFFFF8C42)),
                                fontFamily: 'OpenDyslexic',
                                fontWeight: FontWeight.w600,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
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
                          padding: EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 10,
                          ),
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

                // SPACER - pushes flashcards to bottom
                Spacer(),

                // FLASHCARDS SECTION
                Column(
                  children: [
                    Container(
                      height: cardSize + 10,
                      child: PageView.builder(
                        controller: _pageController,
                        physics:
                            (_gameController.isDragging[_gameController
                                        .centerCardIndex] ??
                                    false)
                                ? const NeverScrollableScrollPhysics()
                                : const BouncingScrollPhysics(),
                        onPageChanged:
                            (index) => _gameController.updateCenterCardIndex(
                              index,
                              setState,
                            ),
                        itemCount: _gameController.shuffledLetters.length,
                        itemBuilder: (context, index) {
                          return _buildTightSpacingFlashcard(index);
                        },
                      ),
                    ),
                    SizedBox(height: 24),
                    Column(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.tertiary.withOpacity(0.4),
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: Image.asset(
                              'assets/images/ic_shuffle.png',
                              width: 20,
                              height: 20,
                              color: AppColors.tertiary,
                            ),
                            onPressed:
                                _gameController.isGameCompleted
                                    ? null
                                    : () {
                                      // First shuffle the game
                                      _gameController.shuffleGame(
                                        setState,
                                        pageController: _pageController,
                                      );
                                      // Then ensure PageController syncs to new center
                                      _gameController.syncPageController(
                                        _pageController,
                                      );
                                    },
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Acak Kartu',
                          style: TextStyle(
                            fontSize: 12,
                            fontFamily: 'OpenDyslexic',
                            color: AppColors.tertiary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),

            // Dragged card overlay - appears on top of everything
            if (_draggedCardIndex != null) _buildDraggedCardOverlay(),
          ],
        ),
      ),
    );
  }

  Widget _buildTightSpacingFlashcard(int index) {
    // Hide the card if it's being dragged (show overlay instead)
    bool isBeingDragged = _draggedCardIndex == index;

    return Container(
      width: cardSize,
      height: cardSize, // Ensure square shape
      color: Colors.transparent,
      child: Opacity(
        opacity:
            isBeingDragged
                ? 0.3
                : 1.0, // Make original card semi-transparent when dragging
        child: FlashcardWidget(
          index: index,
          controller: _gameController,
          onPanStart: () => _onPanStart(index),
          onPanUpdate: (details) => _onPanUpdate(index, details),
          onPanEnd: (details) => _onPanEnd(index, details),
          // Disable drag position for the original card when dragging
          disableDragTransform: isBeingDragged,
        ),
      ),
    );
  }
}
