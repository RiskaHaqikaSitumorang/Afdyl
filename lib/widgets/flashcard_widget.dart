// lib/widgets/flashcard_widget.dart
import 'package:afdyl/constants/app_colors.dart';
import 'package:flutter/material.dart';
import '../services/game_controller.dart';

class FlashcardWidget extends StatelessWidget {
  static const double cardSize = 140.0;

  final int index;
  final GameController controller;
  final VoidCallback onPanStart;
  final Function(DragUpdateDetails) onPanUpdate;
  final Function(DragEndDetails) onPanEnd;
  final bool disableDragTransform;

  const FlashcardWidget({
    Key? key,
    required this.index,
    required this.controller,
    required this.onPanStart,
    required this.onPanUpdate,
    required this.onPanEnd,
    this.disableDragTransform = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    bool isCenter = index == controller.centerCardIndex;
    double scale = isCenter ? 1.0 : 0.78;
    double opacity = isCenter ? 1.0 : 0.5;
    Offset dragPosition =
        disableDragTransform
            ? Offset.zero
            : (controller.cardDragPositions[index] ?? Offset.zero);
    bool isDragging = controller.isDragging[index] ?? false;

    // Enhanced visual effects for dragging
    double dragScale = 1.0;

    return Transform.translate(
      offset: dragPosition,
      child: Transform.scale(
        scale: scale * dragScale,
        child: Opacity(
          opacity: opacity,
          child: GestureDetector(
            onPanStart: isCenter ? (_) => onPanStart() : null,
            onPanUpdate: isCenter ? onPanUpdate : null,
            onPanEnd: isCenter ? onPanEnd : null,
            child: Material(
              borderRadius: BorderRadius.circular(15),
              color: Colors.transparent,
              child: Padding(
                padding: EdgeInsetsGeometry.only(bottom: 20),
                child: Container(
                  width: cardSize,
                  height: cardSize, // Consistent square size
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(15),
                    border:
                        (isDragging && !disableDragTransform)
                            ? Border.all(
                              color: Colors.blue.withOpacity(0.6),
                              width: 2,
                            )
                            : (controller.showFeedback && isCenter
                                ? Border.all(
                                  color: controller.feedbackColor,
                                  width: 3,
                                )
                                : null),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Huruf Hijaiyah dengan font Maqroo
                      Text(
                        controller.shuffledLetters[index]['letter']!,
                        style: TextStyle(
                          fontSize: isCenter ? 50 : 40,
                          fontFamily: 'Maqroo', // Font Maqroo untuk hijaiyah
                          color: Colors.black87,
                          fontWeight: FontWeight.bold,
                        ),
                        semanticsLabel:
                            'Huruf ${controller.shuffledLetters[index]['name']!}',
                      ),
                      SizedBox(height: 8),
                    ],
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
