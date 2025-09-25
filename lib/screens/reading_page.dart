import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import '../services/quran_service.dart';
import '../routes/app_routes.dart';

class ReadingPage extends StatefulWidget {
  final String type;
  final int number;
  final String name;
  final int? ayahNumber;

  const ReadingPage({
    super.key,
    required this.type,
    required this.number,
    required this.name,
    this.ayahNumber,
  });

  @override
  ReadingPageState createState() => ReadingPageState();
}

class ReadingPageState extends State<ReadingPage> {
  final QuranService _quranService = QuranService();
  List<Map<String, dynamic>> ayahs = [];
  List<Map<String, dynamic>> timings = [];
  List<Map<String, dynamic>> bookmarks = [];
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

  double get ayahNumberSize => (fontSize * 0.65).clamp(14.0, 32.0);
  double get wordPadding => (fontSize * 0.35).clamp(6.0, 18.0);
  double get wordSpacing => (fontSize * 0.25).clamp(6.0, 20.0);

  @override
  void initState() {
    super.initState();
    _loadAyahs();
    _loadBookmarks();
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
      final lastRead = await _quranService.fetchLastRead();
      if (mounted) {
        setState(() {
          ayahs = data;
          timings = timingData;
          isLoading = false;
          _ayahKeys = List.generate(ayahs.length, (_) => GlobalKey());
          if (widget.ayahNumber != null) {
            currentActiveAyah = ayahs.indexWhere((ayah) => ayah['numberInSurah'] == widget.ayahNumber);
            if (currentActiveAyah == -1) currentActiveAyah = 0;
          } else if (lastRead.isNotEmpty) {
            if (widget.type == 'surah' && lastRead['surah_number'] == widget.number) {
              currentActiveAyah = ayahs.indexWhere((ayah) => ayah['numberInSurah'] == lastRead['ayah_number']);
            } else if (widget.type == 'juz') {
              currentActiveAyah = ayahs.indexWhere((ayah) =>
                  ayah['surah']['number'] == lastRead['surah_number'] &&
                  ayah['numberInSurah'] == lastRead['ayah_number']);
            }
            if (currentActiveAyah == -1) currentActiveAyah = 0;
          }
        });
        if (ayahs.isNotEmpty && mounted) {
          _scrollToAyahWithRetry(currentActiveAyah);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          errorMessage = 'Gagal memuat ayat: ${e.toString()}';
          isLoading = false;
        });
      }
      developer.log('Error in _loadAyahs: $e', name: 'ReadingPage');
    }
  }

  Future<void> _loadBookmarks() async {
    try {
      final bookmarkData = await _quranService.fetchLocalBookmarks();
      if (mounted) {
        setState(() {
          bookmarks = bookmarkData;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          errorMessage = 'Gagal memuat bookmark: ${e.toString()}';
        });
      }
      developer.log('Error in _loadBookmarks: $e', name: 'ReadingPage');
    }
  }

  Future<void> _toggleBookmark(int ayahNumber) async {
    final existingBookmark = bookmarks.firstWhere(
      (bookmark) => bookmark['surah_number'] == widget.number && bookmark['ayah_number'] == ayahNumber,
      orElse: () => {},
    );

    if (existingBookmark.isNotEmpty) {
      final success = await _quranService.deleteLocalBookmark(existingBookmark['id']);
      if (success && mounted) {
        setState(() {
          bookmarks.removeWhere((b) => b['id'] == existingBookmark['id']);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Bookmark dihapus untuk ayat $ayahNumber')),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menghapus bookmark')),
        );
      }
    } else {
      final success = await _quranService.addLocalBookmark(widget.number, ayahNumber);
      if (success && mounted) {
        setState(() {
          bookmarks.add({
            'id': 'local_${widget.number}_${ayahNumber}_${DateTime.now().millisecondsSinceEpoch}',
            'surah_number': widget.number,
            'ayah_number': ayahNumber,
          });
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Bookmark ditambahkan untuk ayat $ayahNumber')),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ayat ini sudah di-bookmark')),
        );
      }
    }
  }

  List<dynamic> _getAyahTimings(int surah, int ayah) {
    final ayahTiming = timings.firstWhere(
      (t) => t['surah'] == surah && t['ayah'] == ayah,
      orElse: () => {'segments': []},
    );
    return ayahTiming['segments'] as List<dynamic>;
  }

  void _startAutoHighlight() {
    _stopAutoHighlight();
    if (mounted) {
      setState(() => autoHighlight = true);
      _playCurrentAyahAudio();
    }
  }

  void _stopAutoHighlight() {
    _audioPlayer.stop();
    _positionSubscription?.cancel();
    if (mounted) {
      setState(() => autoHighlight = false);
    }
  }

  void _toggleAuto() {
    if (mounted) {
      setState(() {
        autoHighlight = !autoHighlight;
      });
      if (autoHighlight) {
        _startAutoHighlight();
      } else {
        _stopAutoHighlight();
      }
    }
  }

  void _playCurrentAyahAudio() {
    if (ayahs.isEmpty || currentActiveAyah >= ayahs.length || !mounted) return;
    final ayah = ayahs[currentActiveAyah];
    final audioUrl = ayah['audio'] as String?;
    if (audioUrl == null || audioUrl.isEmpty) {
      if (mounted) {
        setState(() {
          errorMessage = 'Audio tidak tersedia untuk ayat ini';
        });
      }
      return;
    }
    _audioPlayer.play(UrlSource(audioUrl));
    _positionSubscription?.cancel();
    _positionSubscription = _audioPlayer.onPositionChanged.listen((position) {
      final ms = position.inMilliseconds;
      final segments = _getAyahTimings(ayah['surah']['number'], ayah['numberInSurah']);
      final currentWords = (ayahs[currentActiveAyah]['words'] as List<dynamic>?) ?? [];
      if (segments.isNotEmpty && currentWords.isNotEmpty) {
        for (final segment in segments) {
          if (segment.length >= 4) {
            final startMs = segment[2] as int;
            final endMs = segment[3] as int;
            final wordIndex = (segment[0] as int) - 1;
            if (ms >= startMs && ms < endMs && wordIndex < currentWords.length) {
              if (mounted) {
                setState(() {
                  currentActiveWord = wordIndex;
                });
                _scrollToAyah(currentActiveAyah);
              }
              break;
            }
          }
        }
      }
    });
  }

  Future<void> _nextAyah() async {
    if (currentActiveAyah < ayahs.length - 1 && mounted) {
      setState(() {
        currentActiveAyah++;
        currentActiveWord = 0;
      });
      _scrollToAyah(currentActiveAyah);
      if (ayahs.isNotEmpty && mounted) {
        final surahName = await _quranService.getSurahName(ayahs[currentActiveAyah]['surah']['number']);
        final success = await _quranService.saveLastRead(
          ayahs[currentActiveAyah]['surah']['number'],
          ayahs[currentActiveAyah]['numberInSurah'] ?? currentActiveAyah + 1,
          surahName,
        );
        if (!success) {
          developer.log('Failed to save last read in _nextAyah', name: 'ReadingPage');
        }
      }
      if (autoHighlight) {
        _playCurrentAyahAudio();
      }
    } else {
      _stopAutoHighlight();
    }
  }

  Future<void> _previousAyah() async {
    if (currentActiveAyah > 0 && mounted) {
      setState(() {
        currentActiveAyah--;
        currentActiveWord = 0;
      });
      _scrollToAyah(currentActiveAyah);
      if (ayahs.isNotEmpty && mounted) {
        final surahName = await _quranService.getSurahName(ayahs[currentActiveAyah]['surah']['number']);
        final success = await _quranService.saveLastRead(
          ayahs[currentActiveAyah]['surah']['number'],
          ayahs[currentActiveAyah]['numberInSurah'] ?? currentActiveAyah + 1,
          surahName,
        );
        if (!success) {
          developer.log('Failed to save last read in _previousAyah', name: 'ReadingPage');
        }
      }
      if (autoHighlight) {
        _playCurrentAyahAudio();
      }
    }
  }

  Future<void> _nextWord() async {
    if (ayahs.isEmpty || !mounted) return;
    final currentWords = (ayahs[currentActiveAyah]['words'] as List<dynamic>?) ?? [];
    if (currentWords.isNotEmpty) {
      if (currentActiveWord < currentWords.length - 1) {
        setState(() => currentActiveWord++);
        _scrollToAyah(currentActiveAyah);
      } else {
        await _nextAyah();
      }
    } else {
      await _nextAyah();
    }
    if (ayahs.isNotEmpty && mounted) {
      final surahName = await _quranService.getSurahName(ayahs[currentActiveAyah]['surah']['number']);
      final success = await _quranService.saveLastRead(
        ayahs[currentActiveAyah]['surah']['number'],
        ayahs[currentActiveAyah]['numberInSurah'] ?? currentActiveAyah + 1,
        surahName,
      );
      if (!success) {
        developer.log('Failed to save last read in _nextWord', name: 'ReadingPage');
      }
    }
  }

  Future<void> _previousWord() async {
    if (ayahs.isEmpty || !mounted) return;
    final currentWords = (ayahs[currentActiveAyah]['words'] as List<dynamic>?) ?? [];
    if (currentWords.isNotEmpty) {
      if (currentActiveWord > 0) {
        setState(() => currentActiveWord--);
        _scrollToAyah(currentActiveAyah);
      } else {
        await _previousAyah();
      }
    } else {
      await _previousAyah();
    }
    if (ayahs.isNotEmpty && mounted) {
      final surahName = await _quranService.getSurahName(ayahs[currentActiveAyah]['surah']['number']);
      final success = await _quranService.saveLastRead(
        ayahs[currentActiveAyah]['surah']['number'],
        ayahs[currentActiveAyah]['numberInSurah'] ?? currentActiveAyah + 1,
        surahName,
      );
      if (!success) {
        developer.log('Failed to save last read in _previousWord', name: 'ReadingPage');
      }
    }
  }

  void _scrollToAyah(int index) {
    if (index < 0 || index >= _ayahKeys.length || !mounted) {
      developer.log('Invalid scroll index: $index, _ayahKeys length: ${_ayahKeys.length}', name: 'ReadingPage');
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _ayahKeys[index].currentContext != null) {
        Scrollable.ensureVisible(
          _ayahKeys[index].currentContext!,
          duration: const Duration(milliseconds: 500),
          alignment: 0.0,
          curve: Curves.easeInOut,
        );
      } else {
        final estimatedPosition = index * (120.0 + ayahSpacing);
        _scrollController.animateTo(
          estimatedPosition.clamp(0.0, _scrollController.position.maxScrollExtent),
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  void _scrollToAyahWithRetry(int index, {int retries = 5, int delayMs = 200}) {
    if (index < 0 || index >= _ayahKeys.length || !mounted) {
      developer.log('Invalid scroll index: $index, _ayahKeys length: ${_ayahKeys.length}', name: 'ReadingPage');
      return;
    }
    void tryScroll(int attempt) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (_ayahKeys[index].currentContext != null) {
          Scrollable.ensureVisible(
            _ayahKeys[index].currentContext!,
            duration: const Duration(milliseconds: 500),
            alignment: 0.0,
            curve: Curves.easeInOut,
          );
        } else if (attempt < retries) {
          Future.delayed(Duration(milliseconds: delayMs), () => tryScroll(attempt + 1));
        } else {
          final estimatedPosition = index * (120.0 + ayahSpacing);
          _scrollController.animateTo(
            estimatedPosition.clamp(0.0, _scrollController.position.maxScrollExtent),
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
          );
        }
      });
    }
    tryScroll(1);
  }

  String getArabicNumber(int number) {
    const arabicDigits = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    return number.toString().split('').map((d) => arabicDigits[int.parse(d)]).join('');
  }

  Widget _buildAyahNumberWidget(int ayahNumber, bool isActiveAyah) {
    final isBookmarked = bookmarks.any(
      (bookmark) => bookmark['surah_number'] == widget.number && bookmark['ayah_number'] == ayahNumber,
    );

    return GestureDetector(
      onTap: () async {
        if (mounted) {
          setState(() {
            currentActiveAyah = ayahs.indexWhere((ayah) => ayah['numberInSurah'] == ayahNumber);
            currentActiveWord = 0;
          });
          _scrollToAyah(currentActiveAyah);
          if (ayahs.isNotEmpty && mounted) {
            final surahName = await _quranService.getSurahName(ayahs[currentActiveAyah]['surah']['number']);
            final success = await _quranService.saveLastRead(
              ayahs[currentActiveAyah]['surah']['number'],
              ayahs[currentActiveAyah]['numberInSurah'] ?? currentActiveAyah + 1,
              surahName,
            );
            if (!success) {
              developer.log('Failed to save last read in _buildAyahNumberWidget', name: 'ReadingPage');
            }
          }
          if (autoHighlight) {
            _playCurrentAyahAudio();
          }
        }
      },
      onLongPress: () => _toggleBookmark(ayahNumber),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Stack(
          children: [
            Container(
              padding: EdgeInsets.symmetric(horizontal: wordPadding * 0.45, vertical: wordPadding * 0.28),
              margin: EdgeInsets.only(left: wordSpacing * 0.5),
              decoration: BoxDecoration(
                color: isActiveAyah ? const Color(0xFFD4A574) : const Color(0xFFD4A574).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isActiveAyah ? const Color(0xFFB8860B) : const Color(0xFFB8860B).withOpacity(0.1),
                  width: 1,
                ),
              ),
              child: Text(
                getArabicNumber(ayahNumber),
                style: TextStyle(
                  color: isActiveAyah ? Colors.white : Colors.black.withOpacity(0.05),
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Amiri',
                  fontSize: ayahNumberSize,
                  height: 1.1,
                ),
              ),
            ),
            if (isBookmarked)
              Positioned(
                top: 0,
                right: 0,
                child: Icon(
                  Icons.bookmark,
                  size: ayahNumberSize * 0.8,
                  color: Colors.redAccent,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _wordWidget(Map<String, dynamic> word, bool isActive, bool isRead, bool isActiveAyah, int ayahIndex, int wordIndex) {
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
      backgroundColor = Colors.grey.withOpacity(0.05);
      textColor = Colors.black.withOpacity(0.05);
    }
    return GestureDetector(
      onTap: () async {
        if (!autoHighlight && mounted) {
          setState(() {
            currentActiveAyah = ayahIndex;
            currentActiveWord = wordIndex;
          });
          _scrollToAyah(ayahIndex);
          if (ayahs.isNotEmpty && mounted) {
            final surahName = await _quranService.getSurahName(ayahs[currentActiveAyah]['surah']['number']);
            final success = await _quranService.saveLastRead(
              ayahs[currentActiveAyah]['surah']['number'],
              ayahs[currentActiveAyah]['numberInSurah'] ?? currentActiveAyah + 1,
              surahName,
            );
            if (!success) {
              developer.log('Failed to save last read in _wordWidget', name: 'ReadingPage');
            }
          }
          if (autoHighlight) {
            _playCurrentAyahAudio();
          }
        }
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: wordPadding, vertical: wordPadding * 0.7),
        margin: EdgeInsets.only(right: wordSpacing * 0.15, left: 0),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular((fontSize * 0.25).clamp(6.0, 14.0)),
          border: isActive
              ? Border.all(color: const Color(0xFFD4A574), width: 2)
              : null,
          boxShadow: isActive
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
            fontFamily: 'Amiri',
            fontWeight: FontWeight.bold,
            height: 1.4,
            color: textColor,
            letterSpacing: 0.4,
          ),
        ),
      ),
    );
  }

  Widget _buildBismillahWidget() {
    return Container(
      margin: EdgeInsets.only(bottom: ayahSpacing),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.3),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Directionality(
            textDirection: TextDirection.rtl,
            child: Text(
              'بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: fontSize,
                fontFamily: 'Amiri',
                fontWeight: FontWeight.bold,
                height: 1.8,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAyahWidget(int ayahIndex) {
    final ayah = ayahs[ayahIndex];
    final ayahNumberInSurah = ayah['numberInSurah'] ?? (ayahIndex + 1);
    final ayahSurahNumber = ayah['surah']['number'] ?? 1;
    final words = (ayah['words'] as List<dynamic>?) ?? [];
    final isActiveAyah = ayahIndex == currentActiveAyah;

    // Filter Bismillah from ayah 1 of surahs (except Al-Fatihah)
    List<dynamic> filteredWords = words;
    String ayahText = ayah['text'] ?? '';
    if (ayahNumberInSurah == 1 && ayahSurahNumber != 1 && ayahSurahNumber != 9) {
      const bismillahWords = ['بِسْمِ', 'ٱللَّهِ', 'ٱلرَّحْمَٰنِ', 'ٱلرَّحِيمِ'];
      ayahText = ayahText.replaceAllMapped(
        RegExp(
          r'بِسْمِ[\s\u200B-\u200F\uFEFF]*ٱللَّهِ[\s\u200B-\u200F\uFEFF]*ٱلرَّحْمَٰنِ[\s\u200B-\u200F\uFEFF]*ٱلرَّحِيمِ[\s\u200B-\u200F\uFEFF]*',
          unicode: true,
        ),
        (match) => '',
      ).trim();
      filteredWords = words.where((word) {
        final wordText = (word['text']?.toString() ?? '').replaceAll(RegExp(r'[\u200B-\u200F\uFEFF]', unicode: true), '').trim();
        return !bismillahWords.any((bw) => wordText == bw);
      }).toList();
      if (ayahText.isEmpty && filteredWords.isEmpty) {
        ayahText = ayahSurahNumber == 2 ? 'الم' : '';
      }
    }

    return GestureDetector(
      key: _ayahKeys.isNotEmpty && ayahIndex < _ayahKeys.length ? _ayahKeys[ayahIndex] : null,
      onTap: () async {
        if (!autoHighlight && mounted) {
          setState(() {
            currentActiveAyah = ayahIndex;
            currentActiveWord = 0;
          });
          _scrollToAyah(ayahIndex);
          if (ayahs.isNotEmpty && mounted) {
            final surahName = await _quranService.getSurahName(ayahs[currentActiveAyah]['surah']['number']);
            final success = await _quranService.saveLastRead(
              ayahs[currentActiveAyah]['surah']['number'],
              ayahs[currentActiveAyah]['numberInSurah'] ?? currentActiveAyah + 1,
              surahName,
            );
            if (!success) {
              developer.log('Failed to save last read in _buildAyahWidget', name: 'ReadingPage');
            }
          }
          if (autoHighlight) {
            _playCurrentAyahAudio();
          }
        }
      },
      child: Container(
        margin: EdgeInsets.only(bottom: ayahSpacing),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isActiveAyah ? Colors.white : Colors.white.withOpacity(0.3),
          borderRadius: BorderRadius.circular(14),
          boxShadow: isActiveAyah
              ? [
                  const BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4)),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Directionality(
              textDirection: TextDirection.rtl,
              child: filteredWords.isNotEmpty
                  ? RichText(
                      text: TextSpan(
                        children: _buildInlineWordSpans(filteredWords, ayahIndex, ayahNumberInSurah),
                      ),
                    )
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            ayahText.isEmpty ? ' ' : ayahText,
                            textAlign: TextAlign.right,
                            style: TextStyle(
                              fontSize: fontSize,
                              fontFamily: 'Amiri',
                              fontWeight: FontWeight.bold,
                              height: 1.8,
                              color: isActiveAyah ? Colors.black87 : Colors.black.withOpacity(0.05),
                            ),
                          ),
                        ),
                        _buildAyahNumberWidget(ayahNumberInSurah, isActiveAyah),
                      ],
                    ),
            ),
            if (showMeaning && isActiveAyah)
              const SizedBox(height: 8),
            if (showMeaning && isActiveAyah)
              Wrap(
                alignment: WrapAlignment.end,
                spacing: 8,
                runSpacing: 6,
                children: (filteredWords.isNotEmpty
                        ? filteredWords.map<Widget>((w) {
                            final idx = filteredWords.indexOf(w);
                            final isActiveWord = isActiveAyah && idx == currentActiveWord;
                            return ConstrainedBox(
                              constraints: BoxConstraints(maxWidth: fontSize * 4.0),
                              child: Container(
                                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                decoration: BoxDecoration(
                                  color: isActiveWord ? Colors.amber.shade100 : Colors.white,
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
                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
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
                            )
                          ]),
              ),
          ],
        ),
      ),
    );
  }

  List<InlineSpan> _buildInlineWordSpans(List<dynamic> words, int ayahIndex, int ayahNumber) {
    final List<InlineSpan> spans = [];
    for (int i = 0; i < words.length; i++) {
      final word = Map<String, dynamic>.from(words[i]);
      final isActiveAyah = ayahIndex == currentActiveAyah;
      final isActiveWord = isActiveAyah && (i == currentActiveWord);
      final isReadWord = ayahIndex < currentActiveAyah || (isActiveAyah && i < currentActiveWord);
      final Widget wordWidget = _wordWidget(word, isActiveWord, isReadWord, isActiveAyah, ayahIndex, i);
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
        spans.add(WidgetSpan(alignment: PlaceholderAlignment.middle, child: wordWidget));
        spans.add(const TextSpan(text: ' '));
      }
    }
    return spans;
  }

  List<Widget> _buildContentList() {
    final List<Widget> content = [];
    if (widget.type == 'surah') {
      final surahNum = widget.number;
      if (surahNum != 1 && surahNum != 9) {
        content.add(_buildBismillahWidget());
      }
      for (int i = 0; i < ayahs.length; i++) {
        content.add(_buildAyahWidget(i));
      }
    } else {
      int prevSurah = -1;
      for (int i = 0; i < ayahs.length; i++) {
        final ayah = ayahs[i];
        final currentSurah = ayah['surah']['number'] ?? 1;
        final numberInSurah = ayah['numberInSurah'] ?? (i + 1);
        if (i == 0 && numberInSurah == 1 && currentSurah != 1 && currentSurah != 9) {
          content.add(_buildBismillahWidget());
        } else if (currentSurah != prevSurah && numberInSurah == 1 && currentSurah != 1 && currentSurah != 9) {
          content.add(_buildBismillahWidget());
        }
        prevSurah = currentSurah;
        content.add(_buildAyahWidget(i));
      }
    }
    return content;
  }

  void _showSettings() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              backgroundColor: const Color(0xFFF5F0E8),
              title: const Text('Pengaturan', style: TextStyle(fontFamily: 'OpenDyslexic')),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Ukuran Font', style: TextStyle(fontFamily: 'OpenDyslexic')),
                    Slider(
                      value: fontSize,
                      min: 16.0,
                      max: 60.0,
                      divisions: 22,
                      label: fontSize.round().toString(),
                      activeColor: const Color(0xFFD4A574),
                      onChanged: (value) {
                        setStateDialog(() => fontSize = value);
                        if (mounted) {
                          setState(() => fontSize = value);
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    const Text('Jarak Antar Ayat', style: TextStyle(fontFamily: 'OpenDyslexic')),
                    Slider(
                      value: ayahSpacing,
                      min: 6.0,
                      max: 48.0,
                      divisions: 21,
                      label: ayahSpacing.round().toString(),
                      activeColor: const Color(0xFFD4A574),
                      onChanged: (value) {
                        setStateDialog(() => ayahSpacing = value);
                        if (mounted) {
                          setState(() => ayahSpacing = value);
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Tampilkan Terjemahan', style: TextStyle(fontFamily: 'OpenDyslexic')),
                        Switch(
                          value: showMeaning,
                          activeColor: const Color(0xFFD4A574),
                          onChanged: (value) {
                            setStateDialog(() => showMeaning = value);
                            if (mounted) {
                              setState(() => showMeaning = value);
                            }
                          },
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Mode Otomatis (Audio)', style: TextStyle(fontFamily: 'OpenDyslexic')),
                        Switch(
                          value: autoHighlight,
                          activeColor: const Color(0xFFD4A574),
                          onChanged: (value) {
                            setStateDialog(() => autoHighlight = value);
                            if (mounted) {
                              setState(() => autoHighlight = value);
                              if (value) {
                                _startAutoHighlight();
                              } else {
                                _stopAutoHighlight();
                              }
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        _showBookmarks();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFD4A574),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                      child: const Text(
                        'Lihat Bookmark',
                        style: TextStyle(color: Colors.white, fontFamily: 'OpenDyslexic'),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Tutup', style: TextStyle(color: Color(0xFFD4A574))),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showBookmarks() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFFF5F0E8),
          title: const Text('Bookmark', style: TextStyle(fontFamily: 'OpenDyslexic')),
          content: SingleChildScrollView(
            child: bookmarks.isEmpty
                ? const Text(
                    'Belum ada bookmark',
                    style: TextStyle(fontFamily: 'OpenDyslexic', color: Colors.black87),
                  )
                : Column(
                    children: bookmarks.map((bookmark) {
                      final surahNumber = bookmark['surah_number'];
                      final ayahNumber = bookmark['ayah_number'];
                      return ListTile(
                        title: Text(
                          'Surah $surahNumber, Ayat $ayahNumber',
                          style: const TextStyle(fontFamily: 'OpenDyslexic'),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.redAccent),
                          onPressed: () async {
                            final success = await _quranService.deleteLocalBookmark(bookmark['id']);
                            if (success && mounted) {
                              setState(() {
                                bookmarks.removeWhere((b) => b['id'] == bookmark['id']);
                              });
                              Navigator.of(context).pop();
                              _showBookmarks();
                            } else if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Gagal menghapus bookmark')),
                              );
                            }
                          },
                        ),
                        onTap: () async {
                          Navigator.of(context).pop();
                          if (mounted) {
                            final surahName = await _quranService.getSurahName(surahNumber);
                            Navigator.pushNamed(
                              context,
                              AppRoutes.reading,
                              arguments: {
                                'type': 'surah',
                                'number': surahNumber,
                                'name': surahName,
                                'ayah_number': ayahNumber,
                              },
                            ).then((_) async {
                              if (mounted) {
                                setState(() {
                                  currentActiveAyah = ayahs.indexWhere((ayah) => ayah['numberInSurah'] == ayahNumber);
                                  currentActiveWord = 0;
                                });
                                final success = await _quranService.saveLastRead(
                                  surahNumber,
                                  ayahNumber,
                                  surahName,
                                );
                                if (!success) {
                                  developer.log('Failed to save last read in _showBookmarks', name: 'ReadingPage');
                                }
                                _scrollToAyahWithRetry(currentActiveAyah);
                                if (autoHighlight) {
                                  _playCurrentAyahAudio();
                                }
                              }
                            });
                          }
                        },
                      );
                    }).toList(),
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Tutup', style: TextStyle(color: Color(0xFFD4A574))),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F0E8),
      appBar: AppBar(
        backgroundColor: const Color(0xFFE8DCC6),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () {
            _stopAutoHighlight();
            Navigator.pop(context);
          },
        ),
        title: Text(
          widget.name,
          style: const TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontFamily: 'OpenDyslexic',
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.black87),
            onPressed: _showSettings,
          ),
        ],
      ),
      body: isLoading
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
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: const BoxDecoration(
                        color: Color(0xFFE8DCC6),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 2,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.skip_previous, size: 32),
                            color: const Color(0xFFD4A574),
                            onPressed: () async {
                              await _previousWord();
                            },
                          ),
                          const SizedBox(width: 18),
                          Container(
                            decoration: const BoxDecoration(
                              color: Color(0xFFD4A574),
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              icon: Icon(
                                autoHighlight ? Icons.pause : Icons.play_arrow,
                                size: 36,
                                color: Colors.white,
                              ),
                              onPressed: _toggleAuto,
                            ),
                          ),
                          const SizedBox(width: 18),
                          IconButton(
                            icon: const Icon(Icons.skip_next, size: 32),
                            color: const Color(0xFFD4A574),
                            onPressed: () async {
                              await _nextWord();
                            },
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(20),
                        itemCount: _buildContentList().length,
                        itemBuilder: (context, index) {
                          return _buildContentList()[index];
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