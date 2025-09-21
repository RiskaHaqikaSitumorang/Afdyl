import 'package:flutter/material.dart';

class ModeToggle extends StatelessWidget {
  final bool isPracticeMode;
  final VoidCallback onToggle;

  const ModeToggle({
    required this.isPracticeMode,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 40),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                if (!isPracticeMode) onToggle();
              },
              child: Container(
                height: 45,
                decoration: BoxDecoration(
                  color: isPracticeMode
                      ? Color(0xFFD4C785)
                      : Color(0xFFE8D4A3),
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
          SizedBox(width: 16),
          Expanded(
            child: GestureDetector(
              onTap: () {
                if (isPracticeMode) onToggle();
              },
              child: Container(
                height: 45,
                decoration: BoxDecoration(
                  color: !isPracticeMode
                      ? Color(0xFFD4C785)
                      : Color(0xFFE8D4A3),
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
        ],
      ),
    );
  }
}