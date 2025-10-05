// lib/screens/reading_page.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import '../services/quran_service.dart';
import '../services/last_read_service.dart';
import '../services/surat_activity_service.dart';
import '../constants/app_colors.dart';

class ReadingPage extends StatefulWidget {
  final String type;
  final int number;
  final String name;
  final int? initialAyah;
  final int? initialWord;

  const ReadingPage({
    Key? key,
    required this.type,
    required this.number,
    required this.name,
    this.initialAyah,
    this.initialWord,
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
  double jarakKata = 50.0;
  int currentActiveAyah = 0;
  int currentActiveWord = 0;
  bool autoHighlight = false;
  final ScrollController _scrollController = ScrollController();
  List<GlobalKey> _ayahKeys = [];
  final AudioPlayer _audioPlayer = AudioPlayer();
  StreamSubscription? _positionSubscription;
  StreamSubscription? _completionSubscription;

  // Activity tracking
  final Set<int> _highlightedAyahs =
      {}; // Track unique highlighted ayahs in current session
  String? _currentSessionId; // Unique session ID
  Timer? _activityDebounceTimer; // Debounce timer

  // sizing getters
  double get ayahNumberSize => (fontSize * 0.65).clamp(14.0, 32.0);
  double get wordPadding => (fontSize * 0.35).clamp(6.0, 18.0);
  double get wordSpacing =>
      jarakKata.clamp(10.0, 70.0); // Use jarakKata (slider) for word spacing

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
    _activityDebounceTimer?.cancel();
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

        // Set initial position jika ada parameter dari lastRead
        if (widget.initialAyah != null) {
          // Cari index ayah berdasarkan nomor ayah
          final ayahIndex = ayahs.indexWhere(
            (ayah) => ayah['number'] == widget.initialAyah,
          );
          if (ayahIndex != -1) {
            currentActiveAyah = ayahIndex;
            currentActiveWord = widget.initialWord ?? 0;
            // Scroll ke ayah setelah widget build selesai
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _scrollToAyah(currentActiveAyah);
            });
          }
        }
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
            final idx1Based = segment[0] as int;
            final wordIndex = idx1Based - 1; // convert to 0-based
            if (ms >= startMs &&
                ms < endMs &&
                wordIndex >= 0 &&
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
    _trackHighlightedAyah(ayahIndex); // Track activity
    _saveLastReadProgress(); // Simpan progress
    _playCurrentAyahAudio();
  }

  void _nextAyah() {
    if (currentActiveAyah < ayahs.length - 1) {
      setState(() {
        currentActiveAyah++;
        currentActiveWord = 0;
      });
      _scrollToAyah(currentActiveAyah);
      _trackHighlightedAyah(currentActiveAyah); // Track activity
      _saveLastReadProgress(); // Simpan progress
      if (autoHighlight) {
        _playCurrentAyahAudio();
      }
    } else {
      _stopAutoHighlight();
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

  // Simpan progress terakhir dibaca
  Future<void> _saveLastReadProgress() async {
    if (ayahs.isEmpty || currentActiveAyah >= ayahs.length) return;

    final currentAyah = ayahs[currentActiveAyah];
    final ayahNumber = currentAyah['number'] ?? (currentActiveAyah + 1);

    print(
      'Saving progress: ${widget.name}, Ayah: $ayahNumber, Word: $currentActiveWord',
    );

    await LastReadService.saveLastRead(
      type: widget.type, // 'surah' atau 'juz'
      surahNumber: widget.number,
      surahName: widget.name,
      ayahNumber: ayahNumber,
      wordNumber: currentActiveWord,
    );

    print('Progress saved successfully');
  }

  /// Track highlighted ayah and record activity when 5+ unique ayahs are highlighted
  void _trackHighlightedAyah(int ayahIndex) {
    // Initialize session ID on first highlight
    _currentSessionId ??= DateTime.now().millisecondsSinceEpoch.toString();

    // Check if we already recorded for this session (marked with -1 sentinel)
    if (_highlightedAyahs.contains(-1)) {
      return; // Already recorded this session
    }

    // Add to set (automatically handles duplicates)
    _highlightedAyahs.add(ayahIndex);

    print(
      '[ReadingPage] 📊 Highlighted ayahs: ${_highlightedAyahs.length}/5 (${_highlightedAyahs.join(", ")})',
    );

    // Check if we've reached the threshold
    if (_highlightedAyahs.length >= 5 && !_highlightedAyahs.contains(-1)) {
      _recordActivity();
    }
  }

  /// Record activity with debouncing to avoid spam
  void _recordActivity() {
    // Cancel previous timer if exists
    _activityDebounceTimer?.cancel();

    // Set new timer with 2 second delay
    _activityDebounceTimer = Timer(const Duration(seconds: 2), () async {
      // Check if already recorded (marked with -1 sentinel value)
      if (_highlightedAyahs.contains(-1)) return;

      print('[ReadingPage] 🎯 Recording activity for Surat ${widget.number}');

      final success = await SuratActivityService.recordSuratActivity(
        widget.number,
      );

      if (success) {
        setState(() {
          // Mark as recorded by adding sentinel value
          _highlightedAyahs.add(-1);
        });
        print('[ReadingPage] ✅ Activity recorded successfully');

        // Show subtle feedback to user
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Progres bacaan tersimpan! 🎉',
                      style: TextStyle(fontFamily: 'OpenDyslexic'),
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
      }
    });
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
        _trackHighlightedAyah(currentActiveAyah); // Track activity
        _saveLastReadProgress(); // Simpan progress
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
            left: jarakKata * 0.5,
          ), // Slightly larger margin
          decoration: BoxDecoration(
            color: AppColors.tertiary,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            getArabicNumber(ayahNumber),
            style: TextStyle(
              fontSize: ayahNumberSize,
              color: AppColors.whiteSoft,
              //
              fontFamily: 'Maqroo',
              height: 1.1,
            ),
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
          _trackHighlightedAyah(ayahIndex); // Track activity
          _saveLastReadProgress(); // Simpan progress
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
        margin: EdgeInsets.only(right: jarakKata * 0.3, left: 0),
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
          style: TextStyle(
            fontSize: fontSize,
            color: textColor,
            fontFamily: 'Maqroo',
            height: 1.4,
            letterSpacing: 0.4,
          ),
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
        _trackHighlightedAyah(ayahIndex); // Track activity
        _saveLastReadProgress(); // Simpan progress
      },
      child: Opacity(
        opacity: isActiveAyah ? 1.0 : 0.6,
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
              // Play button for each ayah (positioned at top-left)
              Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.tertiary.withOpacity(0.4),
                      shape: BoxShape.circle,
                    ),
                    width: 36,
                    height: 36,
                    child: IconButton(
                      iconSize: 20,
                      padding: EdgeInsets.zero,
                      icon: Icon(
                        currentActiveAyah == ayahIndex && autoHighlight
                            ? Icons.pause
                            : Icons.play_arrow,
                        color: AppColors.tertiary,
                      ),
                      onPressed: () => _playAyahAudio(ayahIndex),
                    ),
                  ),
                  const Spacer(),
                ],
              ),
              const SizedBox(height: 8),

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
                            // Arabic text with ayah number that wraps responsively
                            RichText(
                              textAlign: TextAlign.right,
                              text: TextSpan(
                                children: [
                                  TextSpan(
                                    text: ayah['text'] ?? '',
                                    style: TextStyle(
                                      fontSize: fontSize,
                                      color: Colors.black,
                                      fontFamily: 'Maqroo',
                                      height: 1.8,
                                      wordSpacing: jarakKata,
                                    ),
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
              if (showMeaning) const SizedBox(height: 8),
              if (showMeaning)
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
                                    fontSize: (fontSize * 0.5).clamp(
                                      12.0,
                                      24.0,
                                    ),
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
                SizedBox(width: jarakKata * 0.3),
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
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.75,
              decoration: const BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Column(
                children: [
                  // Header dengan tombol close
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    decoration: const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: Colors.grey, width: 0.2),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Pengaturan Bacaan',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'OpenDyslexic',
                            color: Colors.black87,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.of(context).pop(),
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: const BoxDecoration(
                              color: Color(0xFFFFE5E5),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              color: Color(0xFFFF6B6B),
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Content
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Ukuran teks Arab
                          const Text(
                            'Ukuran teks Arab',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              fontFamily: 'OpenDyslexic',
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Preview teks Arab
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8F9FA),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Text(
                                'بِسْمِ',
                                style: TextStyle(
                                  fontSize: fontSize,
                                  fontFamily: 'Maqroo',
                                  color: Colors.black87,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Slider untuk ukuran font
                          Row(
                            children: [
                              const Text(
                                'بِسْمِ',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontFamily: 'Maqroo',
                                  color: Colors.grey,
                                ),
                              ),
                              Expanded(
                                child: SliderTheme(
                                  data: SliderTheme.of(context).copyWith(
                                    activeTrackColor: const Color(0xFFFF8A00),
                                    inactiveTrackColor: Colors.grey.shade300,
                                    thumbColor: const Color(0xFFB8660A),
                                    overlayColor: const Color(
                                      0xFFFF8A00,
                                    ).withOpacity(0.2),
                                    thumbShape: const RoundSliderThumbShape(
                                      enabledThumbRadius: 12,
                                    ),
                                  ),
                                  child: Slider(
                                    value: fontSize,
                                    min: 16.0,
                                    max: 60.0,
                                    onChanged: (value) {
                                      setStateDialog(() => fontSize = value);
                                      setState(() => fontSize = value);
                                    },
                                  ),
                                ),
                              ),
                              const Text(
                                'بِسْمِ',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontFamily: 'Maqroo',
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 32),

                          // Jarak antar kata
                          const Text(
                            'Jarak antar kata',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              fontFamily: 'OpenDyslexic',
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Preview jarak kata
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8F9FA),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text(
                                    'بِسْمِ',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontFamily: 'Maqroo',
                                      color: Colors.black87,
                                    ),
                                  ),
                                  SizedBox(width: jarakKata),
                                  const Text(
                                    'اللَّهِ',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontFamily: 'Maqroo',
                                      color: Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Slider untuk jarak kata
                          Row(
                            children: [
                              const Text(
                                'بِسْمِاللَّهِ',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontFamily: 'Maqroo',
                                  color: Colors.grey,
                                ),
                              ),
                              Expanded(
                                child: SliderTheme(
                                  data: SliderTheme.of(context).copyWith(
                                    activeTrackColor: const Color(0xFFFF8A00),
                                    inactiveTrackColor: Colors.grey.shade300,
                                    thumbColor: const Color(0xFFB8660A),
                                    overlayColor: const Color(
                                      0xFFFF8A00,
                                    ).withOpacity(0.2),
                                    thumbShape: const RoundSliderThumbShape(
                                      enabledThumbRadius: 12,
                                    ),
                                  ),
                                  child: Slider(
                                    value: jarakKata,
                                    min: 10.0,
                                    max: 70.0,
                                    onChanged: (value) {
                                      setStateDialog(() => jarakKata = value);
                                      setState(() => jarakKata = value);
                                    },
                                  ),
                                ),
                              ),
                              const Text(
                                'بِسْمِ   اللَّهِ',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontFamily: 'Maqroo',
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 32),

                          // Pilih fitur tampilan
                          const Text(
                            'Pilih fitur tampilan',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              fontFamily: 'OpenDyslexic',
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Fitur toggle buttons
                          Row(
                            children: [
                              Expanded(
                                child: GestureDetector(
                                  onTap: () {
                                    final newValue = !showMeaning;
                                    setStateDialog(
                                      () => showMeaning = newValue,
                                    );
                                    setState(() => showMeaning = newValue);
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color:
                                          showMeaning
                                              ? const Color(0xFFFFE5CC)
                                              : const Color(0xFFF8F9FA),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color:
                                            showMeaning
                                                ? const Color(0xFFFF8A00)
                                                : Colors.grey.shade300,
                                      ),
                                    ),
                                    child: Column(
                                      children: [
                                        Container(
                                          width: 48,
                                          height: 48,
                                          decoration: BoxDecoration(
                                            color:
                                                showMeaning
                                                    ? const Color(0xFFFF8A00)
                                                    : Colors.grey.shade400,
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.text_fields,
                                            color: Colors.white,
                                            size: 24,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        const Text(
                                          'Arti\nbacaan',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontFamily: 'OpenDyslexic',
                                            color: Colors.black87,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: GestureDetector(
                                  onTap: () {
                                    final newValue = !autoHighlight;
                                    setStateDialog(
                                      () => autoHighlight = newValue,
                                    );
                                    setState(() => autoHighlight = newValue);
                                    if (newValue) {
                                      _startAutoHighlight();
                                    } else {
                                      _stopAutoHighlight();
                                    }
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color:
                                          autoHighlight
                                              ? const Color(0xFFFFE5CC)
                                              : const Color(0xFFF8F9FA),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color:
                                            autoHighlight
                                                ? const Color(0xFFFF8A00)
                                                : Colors.grey.shade300,
                                      ),
                                    ),
                                    child: Column(
                                      children: [
                                        Container(
                                          width: 48,
                                          height: 48,
                                          decoration: BoxDecoration(
                                            color:
                                                autoHighlight
                                                    ? const Color(0xFFFF8A00)
                                                    : Colors.grey.shade400,
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.volume_up,
                                            color: Colors.white,
                                            size: 24,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        const Text(
                                          'Suara\notomatis',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontFamily: 'OpenDyslexic',
                                            color: Colors.black87,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

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
            width: 40,
            height: 40,
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
                      itemCount: ayahs.length + 1, // +1 untuk bismillah
                      itemBuilder: (context, index) {
                        if (index == 0 &&
                            widget.number != 1 &&
                            widget.number != 9) {
                          // Item pertama adalah container Bismillah
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 20),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                vertical: 20,
                                horizontal: 16,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: const Color(0xFFD4A574),
                                  width: 3,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 12,
                                    offset: Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: Text(
                                'بِسْمِ ٱللّٰهِ الرَّحْمٰنِ الرَّحِيْمِ',
                                style: TextStyle(
                                  fontFamily: 'Maqroo',
                                  fontSize: fontSize,
                                  color: Colors.black,
                                  wordSpacing: jarakKata,
                                ),
                                textAlign: TextAlign.right,
                              ),
                            ),
                          );
                        } else {
                          final ayahIndex =
                              widget.number == 1 || widget.number == 9
                                  ? index
                                  : index - 1;
                          return _buildAyahWidget(ayahIndex);
                        }
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
