// lib/models/hijaiyah_model.dart
class HijaiyahLetter {
  final String arabic;
  final String latin;
  final String fatha;
  final String kasra;
  final String damma;

  HijaiyahLetter({
    required this.arabic,
    required this.latin,
    required this.fatha,
    required this.kasra,
    required this.damma,
  });

  factory HijaiyahLetter.fromMap(Map<String, dynamic> map) {
    return HijaiyahLetter(
      arabic: map['arabic'],
      latin: map['latin'],
      fatha: map['fatha'],
      kasra: map['kasra'],
      damma: map['damma'],
    );
  }
}

final List<HijaiyahLetter> hijaiyahLetters = [
  HijaiyahLetter(arabic: 'ا', latin: 'alif', fatha: 'اَ', kasra: 'اِ', damma: 'اُ'),
  HijaiyahLetter(arabic: 'ب', latin: 'ba', fatha: 'بَ', kasra: 'بِ', damma: 'بُ'),
  HijaiyahLetter(arabic: 'ت', latin: 'ta', fatha: 'تَ', kasra: 'تِ', damma: 'تُ'),
  HijaiyahLetter(arabic: 'ث', latin: 'tsa', fatha: 'ثَ', kasra: 'ثِ', damma: 'ثُ'),
  HijaiyahLetter(arabic: 'ج', latin: 'jim', fatha: 'جَ', kasra: 'جِ', damma: 'جُ'),
  HijaiyahLetter(arabic: 'ح', latin: 'ha', fatha: 'حَ', kasra: 'حِ', damma: 'حُ'),
  HijaiyahLetter(arabic: 'خ', latin: 'kha', fatha: 'خَ', kasra: 'خِ', damma: 'خُ'),
  HijaiyahLetter(arabic: 'د', latin: 'dal', fatha: 'دَ', kasra: 'دِ', damma: 'دُ'),
  HijaiyahLetter(arabic: 'ذ', latin: 'dzal', fatha: 'ذَ', kasra: 'ذِ', damma: 'ذُ'),
  HijaiyahLetter(arabic: 'ر', latin: 'ra', fatha: 'رَ', kasra: 'رِ', damma: 'رُ'),
  HijaiyahLetter(arabic: 'ز', latin: 'zai', fatha: 'زَ', kasra: 'زِ', damma: 'زُ'),
  HijaiyahLetter(arabic: 'س', latin: 'sin', fatha: 'سَ', kasra: 'سِ', damma: 'سُ'),
  HijaiyahLetter(arabic: 'ش', latin: 'syin', fatha: 'شَ', kasra: 'شِ', damma: 'شُ'),
  HijaiyahLetter(arabic: 'ص', latin: 'shad', fatha: 'صَ', kasra: 'صِ', damma: 'صُ'),
  HijaiyahLetter(arabic: 'ض', latin: 'dhad', fatha: 'ضَ', kasra: 'ضِ', damma: 'ضُ'),
  HijaiyahLetter(arabic: 'ط', latin: 'tha', fatha: 'طَ', kasra: 'طِ', damma: 'طُ'),
  HijaiyahLetter(arabic: 'ظ', latin: 'zha', fatha: 'ظَ', kasra: 'ظِ', damma: 'ظُ'),
  HijaiyahLetter(arabic: 'ع', latin: 'ain', fatha: 'عَ', kasra: 'عِ', damma: 'عُ'),
  HijaiyahLetter(arabic: 'غ', latin: 'ghain', fatha: 'غَ', kasra: 'غِ', damma: 'غُ'),
  HijaiyahLetter(arabic: 'ف', latin: 'fa', fatha: 'فَ', kasra: 'فِ', damma: 'فُ'),
  HijaiyahLetter(arabic: 'ق', latin: 'qaf', fatha: 'قَ', kasra: 'قِ', damma: 'قُ'),
  HijaiyahLetter(arabic: 'ك', latin: 'kaf', fatha: 'كَ', kasra: 'كِ', damma: 'كُ'),
  HijaiyahLetter(arabic: 'ل', latin: 'lam', fatha: 'لَ', kasra: 'لِ', damma: 'لُ'),
  HijaiyahLetter(arabic: 'م', latin: 'mim', fatha: 'مَ', kasra: 'مِ', damma: 'مُ'),
  HijaiyahLetter(arabic: 'ن', latin: 'nun', fatha: 'نَ', kasra: 'نِ', damma: 'نُ'),
  HijaiyahLetter(arabic: 'و', latin: 'waw', fatha: 'وَ', kasra: 'وِ', damma: 'وُ'),
  HijaiyahLetter(arabic: 'ه', latin: 'Hā', fatha: 'هَ', kasra: 'هِ', damma: 'هُ'),
  HijaiyahLetter(arabic: 'ي', latin: 'ya', fatha: 'يَ', kasra: 'يِ', damma: 'يُ'),
];

// Daftar pelafalan khusus untuk mode harakat (28 huruf x 3 variasi = 84 item)
final List<String> harakatPronunciations = [
  'a', 'i', 'u',    // Alif
  'ba', 'bi', 'bu',  // Ba
  'ta', 'ti', 'tu',  // Ta
  'tsa', 'tsi', 'tsu', // Tsa
  'ja', 'ji', 'ju',  // Jim
  'ha', 'hi', 'hu',  // Ha
  'kha', 'khi', 'khu', // Kha
  'da', 'di', 'du',  // Dal
  'dza', 'dzi', 'dzu', // Dzal
  'ra', 'ri', 'ru',  // Ra
  'za', 'zi', 'zu',  // Zai
  'sa', 'si', 'su',  // Sin
  'sya', 'syi', 'syu', // Syin
  'sha', 'shi', 'shu', // Shad
  'dha', 'dhi', 'dhu', // Dhad
  'tha', 'thi', 'thu', // Tha
  'zha', 'zhi', 'zhu', // Zha
  'a\'', 'i\'', 'u\'', // Ain (dengan tanda petik untuk membedakan)
  'gha', 'ghi', 'ghu', // Ghain
  'fa', 'fi', 'fu',  // Fa
  'qa', 'qi', 'qu',  // Qaf
  'ka', 'ki', 'ku',  // Kaf
  'la', 'li', 'lu',  // Lam
  'ma', 'mi', 'mu',  // Mim
  'na', 'ni', 'nu',  // Nun
  'wa', 'wi', 'wu',  // Waw
  'ha', 'hi', 'hu',  // Ha
  'ya', 'yi', 'yu',  // Ya
];