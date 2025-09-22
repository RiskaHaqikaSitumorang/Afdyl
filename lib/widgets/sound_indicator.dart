import 'package:flutter/material.dart';

class SoundIndicator extends StatelessWidget {
  final bool isActive;

  const SoundIndicator({Key? key, required this.isActive}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (!isActive) return SizedBox.shrink();
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: Color(0xFFB8D4B8),
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.volume_up,
        color: Colors.black,
        size: 20,
      ),
    );
  }
}