import 'package:flutter/material.dart';
import '../models/hijaiyah_model.dart';
import '../widgets/hijaiyah_flashcard.dart';
import 'hijaiyah_tracing_detail_page.dart';
import '../constants/app_colors.dart';

class HijaiyahTracingPage extends StatefulWidget {
  @override
  HijaiyahTracingPageState createState() => HijaiyahTracingPageState();
}

class HijaiyahTracingPageState extends State<HijaiyahTracingPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                    margin: const EdgeInsets.only(top: 8.0),
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
                  Expanded(
                    child: Text(
                      'Jejak Hijaiyah',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
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
            SizedBox(height: 24),
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.0),
                child: GridView.builder(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.85,
                  ),
                  itemCount: hijaiyahLetters.length, // Hanya 28 huruf
                  itemBuilder: (context, index) {
                    return HijaiyahFlashcard(
                      index: index,
                      isHurufMode: true, // Selalu huruf mode
                      onTap: () => _navigateToTracingDetail(index),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToTracingDetail(int index) {
    if (index >= hijaiyahLetters.length) {
      print('Warning: Index $index exceeds hijaiyahLetters length');
      return;
    }
    
    final letterData = hijaiyahLetters[index];
    final displayText = letterData.arabic;
    final pronunciationText = '(${letterData.latin})';

    print(
      'Navigating to: letter=$displayText, pronunciation=$pronunciationText',
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HijaiyahTracingDetailPage(
          letter: displayText,
          pronunciation: pronunciationText,
        ),
      ),
    );
  }
}
