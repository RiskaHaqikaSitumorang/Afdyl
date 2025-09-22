import 'package:flutter/material.dart';

class TextDisplayArea extends StatelessWidget {
  final String lastWords;
  final String arabicText;
  final double confidence;

  const TextDisplayArea({
    Key? key,
    required this.lastWords,
    required this.arabicText,
    required this.confidence,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: 2,
      child: Container(
        width: double.infinity,
        margin: EdgeInsets.symmetric(horizontal: 20),
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (lastWords.isNotEmpty) ...[
              Text(
                lastWords,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                  fontFamily: 'OpenDyslexic',
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 20),
            ],
            if (arabicText.isNotEmpty) ...[
              Text(
                arabicText,
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
                textAlign: TextAlign.center,
                textDirection: TextDirection.rtl,
              ),
              SizedBox(height: 10),
            ],
            if (confidence > 0) ...[
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: confidence > 0.7 ? Colors.green[100] : Colors.orange[100],
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Text(
                  'Akurasi: ${(confidence * 100).toInt()}%',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.black87,
                    fontFamily: 'OpenDyslexic',
                  ),
                ),
              ),
            ],
            if (lastWords.isEmpty && arabicText.isEmpty)
              Column(
                children: [
                  Icon(
                    Icons.mic_none,
                    size: 60,
                    color: Colors.grey[400],
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Ucapkan kata bahasa Arab\ndan lihat tulisannya di sini',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                      fontFamily: 'OpenDyslexic',
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}