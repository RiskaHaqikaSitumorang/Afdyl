// lib/screens/reading_page.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import '../services/quran_service.dart';
import '../constants/arabic_text_styles.dart';
import '../constants/app_colors.dart';

class ReadingPage extends StatefulWidget {
  final String type;
  final int number;
  final String name;

  const ReadingPage({
    Key? key,
    required this.type,
    required this.number,
    required this.name,
  }) : super(key: key);

  @override
  _ReadingPageState createState() => _ReadingPageState();
}

class _ReadingPageState extends State<ReadingPage> {
  final QuranService _quranService = QuranService();
  List<Map<String, dynamic>> ayahs = [];
  List<Map<String, dynamic>> timings = [];
  bool isLoading = true;
  String errorMessage = '';
  bool showMeaning = false;
  double fontSize = 36.0;
  double ayahSpacing = 16.0;
  int currentActiveAyah = 0;
  int currentActiveWord = 0;
  bool autoHighlight = false;
  final ScrollController _scrollController = ScrollController();
  List<GlobalKey> _ayahKeys = [];
  final AudioPlayer _audioPlayer = AudioPlayer();
  StreamSubscription? _positionSubscription;
  StreamSubscription? _completionSubscription;

  // sizing getters
  double get ayahNumberSize => (fontSize * 0.65).clamp(14.0, 32.0);
  double get wordPadding => (fontSize * 0.35).clamp(6.0, 18.0);
  double get wordSpacing => (fontSize * 0.4).clamp(
    10.0,
    30.0,
  ); // Increased spacing for better readability

  @override
  void initState() {
    super.initState();
    _loadAyahs();
    // Listen for audio completion to move to next ayah
    _completionSubscription = _audioPlayer.onPlayerStateChanged.listen((state) {
      if (state == PlayerState.completed && autoHighlight) {
        _nextAyah();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _audioPlayer.dispose();
    _positionSubscription?.cancel();
    _completionSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadAyahs() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });
    try {
      final data = await _quranService.fetchAyahs(widget.type, widget.number);
      final timingData = await _quranService.fetchTimings();
      setState(() {
        ayahs = data;
        timings = timingData;
        isLoading = false;
        _ayahKeys = List.generate(ayahs.length, (_) => GlobalKey());
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Gagal memuat ayat: ${e.toString()}';
        isLoading = false;
      });
    }
  }

  // Get timings for a specific ayah
  List<dynamic> _getAyahTimings(int surah, int ayah) {
    final ayahTiming = timings.firstWhere(
      (t) => t['surah'] == surah && t['ayah'] == ayah,
      orElse: () => {'segments': []},
    );
    return ayahTiming['segments'] as List<dynamic>;
  }

  // Auto highlight control with audio sync
  void _startAutoHighlight() {
    _stopAutoHighlight();
    setState(() => autoHighlight = true);
    _playCurrentAyahAudio();
  }

  void _stopAutoHighlight() {
    _audioPlayer.stop();
    _positionSubscription?.cancel();
    setState(() => autoHighlight = false);
  }

  void _toggleAuto() {
    setState(() {
      autoHighlight = !autoHighlight;
    });
    if (autoHighlight) {
      _startAutoHighlight();
    } else {
      _stopAutoHighlight();
    }
  }

  void _playCurrentAyahAudio() {
    if (ayahs.isEmpty || currentActiveAyah >= ayahs.length) return;
    final ayah = ayahs[currentActiveAyah];
    final audioUrl = ayah['audio'] as String?;
    if (audioUrl == null || audioUrl.isEmpty) {
      setState(() {
        errorMessage = 'Audio tidak tersedia untuk ayat ini';
      });
      return;
    }

    _audioPlayer.play(UrlSource(audioUrl));

    // Listen to position for word sync
    _positionSubscription?.cancel();
    _positionSubscription = _audioPlayer.onPositionChanged.listen((position) {
      final ms = position.inMilliseconds;
      final segments = _getAyahTimings(widget.number, ayah['number']);
      final currentWords =
          (ayahs[currentActiveAyah]['words'] as List<dynamic>?) ?? [];

      if (segments.isNotEmpty && currentWords.isNotEmpty) {
        for (final segment in segments) {
          if (segment.length >= 4) {
            final startMs = segment[2] as int;
            final endMs = segment[3] as int;
            final wordIndex = segment[0] as int;
            -1; // 1-based to 0-based index
            if (ms >= startMs &&
                ms < endMs &&
                wordIndex < currentWords.length) {
              setState(() {
                currentActiveWord = wordIndex;
              });
              _scrollToAyah(currentActiveAyah);
              break;
            }
          }
        }
      }
    });
  }

  // Play audio for a specific ayah
  void _playAyahAudio(int ayahIndex) {
    if (ayahs.isEmpty || ayahIndex >= ayahs.length) return;

    final ayah = ayahs[ayahIndex];
    final audioUrl = ayah['audio'] as String?;

    if (audioUrl == null || audioUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Audio tidak tersedia untuk ayat ini'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // If same ayah is playing and auto mode is on, pause it
    if (currentActiveAyah == ayahIndex && autoHighlight) {
      _stopAutoHighlight();
      return;
    }

    // Set current ayah and play audio
    setState(() {
      currentActiveAyah = ayahIndex;
      currentActiveWord = 0;
      autoHighlight = true;
    });

    _scrollToAyah(ayahIndex);
    _playCurrentAyahAudio();
  }

  void _nextAyah() {
    if (currentActiveAyah < ayahs.length - 1) {
      setState(() {
        currentActiveAyah++;
        currentActiveWord = 0;
      });
      _scrollToAyah(currentActiveAyah);
      if (autoHighlight) {
        _playCurrentAyahAudio();
      }
    } else {
      _stopAutoHighlight();
    }
  }

  void _previousAyah() {
    if (currentActiveAyah > 0) {
      setState(() {
        currentActiveAyah--;
        currentActiveWord = 0;
      });
      _scrollToAyah(currentActiveAyah);
      if (autoHighlight) {
        _playCurrentAyahAudio();
      }
    }
  }

  void _nextWord() {
    if (ayahs.isEmpty) return;
    final currentWords =
        (ayahs[currentActiveAyah]['words'] as List<dynamic>?) ?? [];
    if (currentWords.isNotEmpty) {
      if (currentActiveWord < currentWords.length - 1) {
        setState(() => currentActiveWord++);
      } else {
        _nextAyah();
      }
    } else {
      _nextAyah();
    }
  }

  void _previousWord() {
    if (ayahs.isEmpty) return;
    final currentWords =
        (ayahs[currentActiveAyah]['words'] as List<dynamic>?) ?? [];
    if (currentWords.isNotEmpty) {
      if (currentActiveWord > 0) {
        setState(() => currentActiveWord--);
      } else {
        _previousAyah();
      }
    } else {
      _previousAyah();
    }
  }

  void _scrollToAyah(int index) {
    if (index < 0 || index >= _ayahKeys.length) return;
    final key = _ayahKeys[index];
    if (key.currentContext != null) {
      Scrollable.ensureVisible(
        key.currentContext!,
        duration: const Duration(milliseconds: 300),
        alignment: 0.1,
      );
    } else {
      // fallback: estimate position
      final position = index * (120.0 + ayahSpacing);
      _scrollController.animateTo(
        position.clamp(0.0, _scrollController.position.maxScrollExtent),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  // Convert to Arabic numerals (simple)
  String getArabicNumber(int number) {
    const arabicDigits = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    return number
        .toString()
        .split('')
        .map((d) => arabicDigits[int.parse(d)])
        .join('');
  }

  // Widget for the numbered badge with expanded touch area
  Widget _buildAyahNumberWidget(int ayahNumber, bool isActiveAyah) {
    return GestureDetector(
      onTap: () {
        setState(() {
          currentActiveAyah = ayahs.indexWhere(
            (ayah) => ayah['number'] == ayahNumber,
          );
          currentActiveWord = 0;
        });
        _scrollToAyah(currentActiveAyah);
        if (autoHighlight) {
          _playCurrentAyahAudio();
        }
      },
      child: Padding(
        padding: const EdgeInsets.all(8.0), // Expanded touch area
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: wordPadding * 0.45,
            vertical: wordPadding * 0.28,
          ),
          margin: EdgeInsets.only(
            left: wordSpacing * 0.5,
          ), // Slightly larger margin
          decoration: BoxDecoration(
            color: AppColors.tertiary.withOpacity(0.4),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            getArabicNumber(ayahNumber),
            style: ArabicTextStyles.custom(
              fontSize: ayahNumberSize,
              color: AppColors.tertiary,
              fontWeight: FontWeight.bold,
            ).copyWith(height: 1.1),
          ),
        ),
      ),
    );
  }

  // Word visual used inside WidgetSpan
  Widget _wordWidget(
    Map<String, dynamic> word,
    bool isActive,
    bool isRead,
    bool isActiveAyah,
    int ayahIndex,
    int wordIndex,
  ) {
    final arabicText = word['text'] ?? '';
    Color backgroundColor;
    Color textColor;

    if (isActive) {
      backgroundColor = const Color(0xFFFFE082);
      textColor = Colors.black87;
    } else if (isRead) {
      backgroundColor = const Color(0xFFE8F5E8);
      textColor = Colors.black54;
    } else if (isActiveAyah) {
      backgroundColor = Colors.white;
      textColor = Colors.black87;
    } else {
      backgroundColor = Colors.grey.withOpacity(0.05); // Almost transparent
      textColor = Colors.black.withOpacity(0.05); // Almost transparent
    }

    return GestureDetector(
      onTap: () {
        if (!autoHighlight) {
          setState(() {
            currentActiveAyah = ayahIndex;
            currentActiveWord = wordIndex;
          });
          _scrollToAyah(ayahIndex);
          if (autoHighlight) {
            _playCurrentAyahAudio();
          }
        }
      },
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: wordPadding,
          vertical: wordPadding * 0.7,
        ),
        margin: EdgeInsets.only(right: wordSpacing * 0.15, left: 0),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(
            (fontSize * 0.25).clamp(6.0, 14.0),
          ),
          border:
              isActive
                  ? Border.all(color: const Color(0xFFD4A574), width: 2)
                  : null,
          boxShadow:
              isActive
                  ? [
                    BoxShadow(
                      color: const Color(0xFFD4A574).withOpacity(0.25),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ]
                  : null,
        ),
        child: Text(
          arabicText,
          style: ArabicTextStyles.custom(
            fontSize: fontSize,
            color: textColor,
            fontWeight: FontWeight.bold,
          ).copyWith(height: 1.4, letterSpacing: 0.4),
        ),
      ),
    );
  }

  Widget _buildAyahWidget(int ayahIndex) {
    final ayah = ayahs[ayahIndex];
    final ayahNumber = ayah['number'] ?? ayahIndex + 1;
    final words = ayah['words'] as List<dynamic>? ?? [];
    final isActiveAyah = ayahIndex == currentActiveAyah;

    return GestureDetector(
      onTap: () {
        // Make this ayah the current highlighted ayah when tapped
        setState(() {
          currentActiveAyah = ayahIndex;
          currentActiveWord = 0;
        });
        _scrollToAyah(ayahIndex);
      },
      child: Container(
        key:
            _ayahKeys.isNotEmpty && ayahIndex < _ayahKeys.length
                ? _ayahKeys[ayahIndex]
                : null,
        margin: EdgeInsets.only(bottom: ayahSpacing),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color:
              isActiveAyah
                  ? AppColors.primary
                  : AppColors.primary.withOpacity(0.3),
          borderRadius: BorderRadius.circular(14),
          border:
              isActiveAyah
                  ? Border.all(color: const Color(0xFFD4A574), width: 3)
                  : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isActiveAyah ? 0.2 : 0.05),
              blurRadius: isActiveAyah ? 12 : 4,
              offset: Offset(0, isActiveAyah ? 6 : 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Arabic line(s) with inline words and the number attached to the last word
            Directionality(
              textDirection: TextDirection.rtl,
              child:
                  words.isNotEmpty
                      ? RichText(
                        text: TextSpan(
                          children: _buildInlineWordSpans(
                            words,
                            ayahIndex,
                            ayahNumber,
                          ),
                        ),
                      )
                      : Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Play button
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Container(
                              decoration: BoxDecoration(
                                color: AppColors.tertiary.withOpacity(0.4),
                                shape: BoxShape.circle,
                              ),
                              width: 40,
                              height: 40,
                              child: IconButton(
                                icon: Icon(
                                  currentActiveAyah == ayahIndex &&
                                          autoHighlight
                                      ? Icons.pause
                                      : Icons.play_arrow,
                                  color: AppColors.tertiary,
                                  size: 24,
                                ),
                                onPressed: () => _playAyahAudio(ayahIndex),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          // Arabic text with ayah number that wraps responsively
                          RichText(
                            textAlign: TextAlign.right,
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: ayah['text'] ?? '',
                                  style: ArabicTextStyles.custom(
                                    fontSize: fontSize,
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold,
                                  ).copyWith(height: 1.8, wordSpacing: 50.0),
                                ),
                                const TextSpan(text: ' '), // Small space
                                WidgetSpan(
                                  alignment: PlaceholderAlignment.middle,
                                  child: _buildAyahNumberWidget(
                                    ayahNumber,
                                    isActiveAyah,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
            ),

            // Play button for each ayah
            // const SizedBox(height: 12),

            // Translations / meanings (optional)
            if (showMeaning && isActiveAyah) const SizedBox(height: 8),
            if (showMeaning && isActiveAyah)
              Wrap(
                alignment: WrapAlignment.end,
                spacing: 8,
                runSpacing: 6,
                children:
                    (words.isNotEmpty
                        ? words.map<Widget>((w) {
                          final idx = words.indexOf(w);
                          final isActiveWord =
                              isActiveAyah && idx == currentActiveWord;
                          return ConstrainedBox(
                            constraints: BoxConstraints(
                              maxWidth: fontSize * 4.0,
                            ),
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    isActiveWord
                                        ? Colors.amber.shade100
                                        : Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.black12),
                              ),
                              child: Text(
                                w['translation'] ?? '',
                                style: TextStyle(
                                  fontSize: (fontSize * 0.5).clamp(12.0, 24.0),
                                  fontFamily: 'OpenDyslexic',
                                  color: Colors.black87,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          );
                        }).toList()
                        : [
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.black12),
                            ),
                            child: Text(
                              ayah['translation'] ?? '',
                              style: TextStyle(
                                fontSize: (fontSize * 0.5).clamp(12.0, 24.0),
                                fontFamily: 'OpenDyslexic',
                                color: Colors.black87,
                              ),
                            ),
                          ),
                        ]),
              ),
          ],
        ),
      ),
    );
  }

  // Build InlineSpans for words where the last word is combined with the ayah-number widget
  List<InlineSpan> _buildInlineWordSpans(
    List<dynamic> words,
    int ayahIndex,
    int ayahNumber,
  ) {
    final List<InlineSpan> spans = [];
    for (int i = 0; i < words.length; i++) {
      final word = Map<String, dynamic>.from(words[i]);
      final isActiveAyah = ayahIndex == currentActiveAyah;
      final isActiveWord = isActiveAyah && (i == currentActiveWord);
      final isReadWord =
          ayahIndex < currentActiveAyah ||
          (isActiveAyah && i < currentActiveWord);

      final Widget wordWidget = _wordWidget(
        word,
        isActiveWord,
        isReadWord,
        isActiveAyah,
        ayahIndex,
        i,
      );

      if (i == words.length - 1) {
        spans.add(
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                wordWidget,
                SizedBox(width: wordSpacing * 0.3),
                _buildAyahNumberWidget(ayahNumber, isActiveAyah),
              ],
            ),
          ),
        );
      } else {
        spans.add(
          WidgetSpan(alignment: PlaceholderAlignment.middle, child: wordWidget),
        );
        spans.add(const TextSpan(text: ' '));
      }
    }
    return spans;
  }

  void _showSettings() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              backgroundColor: const Color(0xFFF5F0E8),
              title: const Text(
                'Pengaturan',
                style: TextStyle(fontFamily: 'OpenDyslexic'),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Ukuran Font',
                      style: TextStyle(fontFamily: 'OpenDyslexic'),
                    ),
                    Slider(
                      value: fontSize,
                      min: 16.0,
                      max: 60.0,
                      divisions: 22,
                      label: fontSize.round().toString(),
                      activeColor: const Color(0xFFD4A574),
                      onChanged: (value) {
                        setStateDialog(() => fontSize = value);
                        setState(() => fontSize = value);
                      },
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Jarak Antar Ayat',
                      style: TextStyle(fontFamily: 'OpenDyslexic'),
                    ),
                    Slider(
                      value: ayahSpacing,
                      min: 6.0,
                      max: 48.0,
                      divisions: 21,
                      label: ayahSpacing.round().toString(),
                      activeColor: const Color(0xFFD4A574),
                      onChanged: (value) {
                        setStateDialog(() => ayahSpacing = value);
                        setState(() => ayahSpacing = value);
                      },
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Tampilkan Terjemahan',
                          style: TextStyle(fontFamily: 'OpenDyslexic'),
                        ),
                        Switch(
                          value: showMeaning,
                          activeColor: const Color(0xFFD4A574),
                          onChanged: (value) {
                            setStateDialog(() => showMeaning = value);
                            setState(() => showMeaning = value);
                          },
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Mode Otomatis (Audio)',
                          style: TextStyle(fontFamily: 'OpenDyslexic'),
                        ),
                        Switch(
                          value: autoHighlight,
                          activeColor: const Color(0xFFD4A574),
                          onChanged: (value) {
                            setStateDialog(() => autoHighlight = value);
                            setState(() => autoHighlight = value);
                            if (value) {
                              _startAutoHighlight();
                            } else {
                              _stopAutoHighlight();
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text(
                    'Tutup',
                    style: TextStyle(color: Color(0xFFD4A574)),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F0E8),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F0E8),
        elevation: 0,
        centerTitle: true,
        toolbarHeight: 90, // Increased height to accommodate the extra spacing
        leading: Container(
          margin: const EdgeInsets.only(top: 8.0, left: 16.0),
          decoration: BoxDecoration(
            color: AppColors.tertiary.withOpacity(0.4),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: const Icon(
              Icons.arrow_back,
              color: AppColors.black,
              size: 20,
            ),
            onPressed: () {
              _stopAutoHighlight();
              Navigator.pop(context);
            },
          ),
        ),
        title: Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Text(
            widget.name,
            style: const TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.w600,
              fontSize: 18,
              fontFamily: 'OpenDyslexic',
            ),
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(top: 8.0, right: 16.0),
            decoration: BoxDecoration(
              color: AppColors.tertiary.withOpacity(0.4),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: Image.asset(
                'assets/images/ic_tuning.png',
                width: 20,
                height: 20,
                color: AppColors.tertiary,
              ),
              onPressed: _showSettings,
            ),
          ),
        ],
      ),
      body:
          isLoading
              ? const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFD4A574)),
                ),
              )
              : errorMessage.isNotEmpty
              ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    errorMessage,
                    style: const TextStyle(
                      fontFamily: 'OpenDyslexic',
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              )
              : Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(20),
                      itemCount: ayahs.length,
                      itemBuilder: (context, index) {
                        return _buildAyahWidget(index);
                      },
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: const BoxDecoration(color: Color(0xFFE8DCC6)),
                    child: Text(
                      'Ayat ${currentActiveAyah + 1} dari ${ayahs.length}',
                      style: const TextStyle(
                        fontFamily: 'OpenDyslexic',
                        fontSize: 14,
                        color: Colors.black54,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
    );
  }
}
