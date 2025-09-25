// lib/widgets/flashcard_widget.dart
import 'package:flutter/material.dart';
import '../services/game_controller.dart';

class FlashcardWidget extends StatelessWidget {
  final int index;
  final GameController controller;
  final VoidCallback onPanStart;
  final Function(DragUpdateDetails) onPanUpdate;
  final Function(DragEndDetails) onPanEnd;

  const FlashcardWidget({
    Key? key,
    required this.index,
    required this.controller,
    required this.onPanStart,
    required this.onPanUpdate,
    required this.onPanEnd,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    bool isCenter = index == controller.centerCardIndex;
    double scale = isCenter ? 1.0 : 0.78;
    double opacity = isCenter ? 1.0 : 0.5;
    Offset dragPosition = controller.cardDragPositions[index] ?? Offset.zero;

    return Transform.translate(
      offset: dragPosition,
      child: Transform.scale(
        scale: scale,
        child: Opacity(
          opacity: opacity,
          child: GestureDetector(
            onPanStart: isCenter ? (_) => onPanStart() : null,
            onPanUpdate: isCenter ? onPanUpdate : null,
            onPanEnd: isCenter ? onPanEnd : null,
            child: Material(
              elevation: isCenter ? 8.0 : 4.0, // Add elevation for floating effect
              borderRadius: BorderRadius.circular(20),
              color: Colors.transparent,
              child: Container(
                width: 140,
                height: 120,
                decoration: BoxDecoration(
                  color: const Color(0xFFEDD1B0),
                  borderRadius: BorderRadius.circular(20),
                  border: controller.showFeedback && isCenter
                      ? Border.all(color: controller.feedbackColor, width: 3)
                      : Border.all(color: Colors.grey[300]!, width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(isCenter ? 0.25 : 0.1),
                      blurRadius: isCenter ? 15 : 8,
                      offset: Offset(0, isCenter ? 6 : 3),
                      spreadRadius: isCenter ? 1.0 : 0.5,
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    controller.shuffledLetters[index]['letter']!,
                    style: TextStyle(
                      fontSize: isCenter ? 55 : 36,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}