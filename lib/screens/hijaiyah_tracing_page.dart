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
  bool isHurufMode = true;

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
                      'Tracing Hijaiyah',
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
            SizedBox(height: 20),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.0),
              child: Row(
                children: [
                  Expanded(
                    child: Opacity(
                      opacity: isHurufMode ? 1.0 : 0.6,
                      child: GestureDetector(
                        onTap: () => setState(() => isHurufMode = true),
                        child: Container(
                          height: 45,
                          decoration: BoxDecoration(
                            color: AppColors.secondary,
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
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Opacity(
                      opacity: !isHurufMode ? 1.0 : 0.6,
                      child: GestureDetector(
                        onTap: () => setState(() => isHurufMode = false),
                        child: Container(
                          height: 45,
                          decoration: BoxDecoration(
                            color: AppColors.secondary,
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
                  ),
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
                  itemCount:
                      isHurufMode
                          ? hijaiyahLetters
                              .length // 28 huruf
                          : hijaiyahLetters.length *
                              3, // 28 huruf x 3 variasi = 84 item
                  itemBuilder: (context, index) {
                    if (index >= hijaiyahLetters.length && isHurufMode) {
                      print('Index out of bounds: $index');
                      return Container(); // Placeholder untuk menghindari error
                    }
                    return HijaiyahFlashcard(
                      index: index,
                      isHurufMode: isHurufMode,
                      onTap: () => _navigateToTracingDetail(index, isHurufMode),
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

  void _navigateToTracingDetail(int index, bool isHurufMode) {
    if (index >= hijaiyahLetters.length && isHurufMode) {
      print('Warning: Index $index exceeds hijaiyahLetters length');
      return;
    }
    final letterData =
        isHurufMode
            ? hijaiyahLetters[index]
            : hijaiyahLetters[index ~/
                3]; // Ambil huruf berdasarkan indeks utama
    final variationIndex = index % 3;
    final displayText =
        isHurufMode
            ? letterData.arabic
            : [
              letterData.fatha,
              letterData.kasra,
              letterData.damma,
            ][variationIndex];
    final pronunciationText =
        isHurufMode
            ? '(${letterData.latin})'
            : harakatPronunciations[index]; // Gunakan indeks langsung untuk 84 item

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
