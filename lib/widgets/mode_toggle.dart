import 'package:afdyl/constants/app_colors.dart';
import 'package:flutter/material.dart';

class ModeToggle extends StatelessWidget {
  final bool isPracticeMode;
  final VoidCallback onToggle;

  const ModeToggle({required this.isPracticeMode, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                if (!isPracticeMode) onToggle();
              },
              child: Opacity(
                opacity: isPracticeMode ? 1.0 : 0.5,
                child: Container(
                  height: 45,
                  decoration: BoxDecoration(
                    color: AppColors.secondary,
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Center(
                    child: Text(
                      'Latihan',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                        fontFamily: 'OpenDyslexic',
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: GestureDetector(
              onTap: () {
                if (isPracticeMode) onToggle();
              },
              child: Opacity(
                opacity: !isPracticeMode ? 1.0 : 0.5,
                child: Container(
                  height: 45,
                  decoration: BoxDecoration(
                    color: AppColors.secondary,
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Center(
                    child: Text(
                      'Uji',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                        fontFamily: 'OpenDyslexic',
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
