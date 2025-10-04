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
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        toolbarHeight: 80, // Increased height to accommodate the extra spacing
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
            "Jejak Hijaiyah",
            style: const TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.w600,
              fontSize: 18,
              fontFamily: 'OpenDyslexic',
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
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
            SizedBox(height: 20.0),
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
        builder:
            (context) => HijaiyahTracingDetailPage(
              letter: displayText,
              pronunciation: pronunciationText,
            ),
      ),
    );
  }
}
