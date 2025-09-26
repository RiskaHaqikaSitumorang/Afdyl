import 'package:afdyl/constants/app_colors.dart';
import 'package:flutter/material.dart';
import '../models/hijaiyah_model.dart';

class HijaiyahFlashcard extends StatelessWidget {
  final int index;
  final bool isHurufMode;
  final VoidCallback onTap;

  const HijaiyahFlashcard({
    required this.index,
    required this.isHurufMode,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final letterData =
        isHurufMode ? hijaiyahLetters[index] : hijaiyahLetters[index ~/ 3];
    final variationIndex = index % 3;
    final displayText =
        isHurufMode
            ? letterData.arabic
            : [
              letterData.fatha,
              letterData.kasra,
              letterData.damma,
            ][variationIndex];

    // Logika kustom untuk pronunciationText berdasarkan indeks huruf
    final pronunciationText =
        isHurufMode
            ? '(${letterData.latin})' // Mode huruf: (alif), (ba), (ta), dll.
            : _getHarakatPronunciation(index ~/ 3, variationIndex);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.secondary,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              flex: 3,
              child: Center(
                child: Text(
                  displayText,
                  style: TextStyle(
                    fontSize: 80,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                    fontFamily: 'Maqroo',
                    height: 1.0,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            Expanded(
              flex: 1,
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Center(
                  child: Text(
                    pronunciationText,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.black87,
                      fontFamily: 'OpenDyslexic',
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Fungsi untuk mengembalikan pronunciation berdasarkan indeks huruf dan variasi harakat
  String _getHarakatPronunciation(int letterIndex, int variationIndex) {
    const pronunciations = [
      ['(a)', '(i)', '(u)'], // 0: Alif
      ['(ba)', '(bi)', '(bu)'], // 1: Ba
      ['(ta)', '(ti)', '(tu)'], // 2: Ta
      ['(tsa)', '(tsi)', '(tsu)'], // 3: Tsa
      ['(ja)', '(ji)', '(ju)'], // 4: Jim
      ['(ha)', '(hi)', '(hu)'], // 5: Ha (ح)
      ['(kha)', '(khi)', '(khu)'], // 6: Kha
      ['(da)', '(di)', '(du)'], // 7: Dal
      ['(dza)', '(dzi)', '(dzu)'], // 8: Dzal
      ['(ra)', '(ri)', '(ru)'], // 9: Ra
      ['(za)', '(zi)', '(zu)'], // 10: Zai
      ['(sa)', '(si)', '(su)'], // 11: Sin
      ['(sya)', '(syi)', '(syu)'], // 12: Syin
      ['(sha)', '(shi)', '(shu)'], // 13: Sad
      ['(dha)', '(dhi)', '(dhu)'], // 14: Dhad
      ['(tha)', '(thi)', '(thu)'], // 15: Tha
      ['(zha)', '(zhi)', '(zhu)'], // 16: Zha
      ['(\'a)', '(\'i)', '(\'u)'], // 17: Ain (sementara, bisa disesuaikan)
      ['(gha)', '(ghi)', '(ghu)'], // 18: Ghain
      ['(fa)', '(fi)', '(fu)'], // 19: Fa
      ['(qa)', '(qi)', '(qu)'], // 20: Qaf
      ['(ka)', '(ki)', '(ku)'], // 21: Kaf
      ['(la)', '(li)', '(lu)'], // 22: Lam
      ['(ma)', '(mi)', '(mu)'], // 23: Mim
      ['(na)', '(ni)', '(nu)'], // 24 : Nun
      ['(wa)', '(wi)', '(wu)'], // 24: Waw
      ['(ha)', '(hi)', '(hu)'], // 25: Ha (ه)
      ['(ya)', '(yi)', '(yu)'], // 26: Ya
    ];

    // Pastikan indeks tidak melebihi panjang daftar
    if (letterIndex >= 0 && letterIndex < pronunciations.length) {
      return pronunciations[letterIndex][variationIndex];
    }
    return '()'; // Default jika indeks tidak valid
  }
}
