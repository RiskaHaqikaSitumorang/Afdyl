import 'package:flutter/material.dart';
import '../models/hijaiyah_model.dart';
import '../widgets/hijaiyah_flashcard.dart';
import '../widgets/hijaiyah_dialog.dart';

class HijaiyahTracingPage extends StatefulWidget {
  @override
  HijaiyahTracingPageState createState() => HijaiyahTracingPageState();
}

class HijaiyahTracingPageState extends State<HijaiyahTracingPage> {
  bool isHurufMode = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F5DC),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Color(0xFFB8D4B8),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: Icon(
                        Icons.arrow_back,
                        color: Colors.black,
                        size: 20,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'Tracing Hijaiyah',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                        fontFamily: 'OpenDyslexic',
                      ),
                    ),
                  ),
                  SizedBox(width: 40),
                ],
              ),
            ),
            SizedBox(height: 20),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.0),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => isHurufMode = true),
                      child: Container(
                        height: 45,
                        decoration: BoxDecoration(
                          color: isHurufMode
                              ? Color(0xFFD4C785)
                              : Color(0xFFE8D4A3),
                          borderRadius: BorderRadius.circular(25),
                        ),
                        child: Center(
                          child: Text(
                            'Huruf',
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
                      onTap: () => setState(() => isHurufMode = false),
                      child: Container(
                        height: 45,
                        decoration: BoxDecoration(
                          color: !isHurufMode
                              ? Color(0xFFD4C785)
                              : Color(0xFFE8D4A3),
                          borderRadius: BorderRadius.circular(25),
                        ),
                        child: Center(
                          child: Text(
                            'Harakat',
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
            ),
            SizedBox(height: 24),
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: GridView.builder(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.85,
                  ),
                  itemCount: isHurufMode
                      ? hijaiyahLetters.length  // 28 huruf
                      : 30,  // 10 baris x 3 variasi = 30 item
                  itemBuilder: (context, index) => HijaiyahFlashcard(
                    index: index,
                    isHurufMode: isHurufMode,
                    onTap: () => _showTracingDialog(index, isHurufMode),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showTracingDialog(int index, bool isHurufMode) {
    final letterData = isHurufMode
        ? hijaiyahLetters[index]
        : hijaiyahLetters[index ~/ 3];
    final variationIndex = index % 3;
    final displayText = isHurufMode
        ? letterData.arabic
        : [letterData.fatha, letterData.kasra, letterData.damma][variationIndex];
    final pronunciationText = isHurufMode
        ? '(${letterData.latin})'
        : harakatPronunciations[index];  // Ambil dari daftar khusus

    showDialog(
      context: context,
      builder: (BuildContext context) => HijaiyahTracingDialog(
        letter: displayText,
        pronunciation: pronunciationText,
        onClose: () => Navigator.of(context).pop(),
      ),
    );
  }
}