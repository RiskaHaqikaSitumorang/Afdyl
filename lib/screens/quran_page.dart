// lib/screens/quran_page.dart
import 'package:afdyl/constants/app_colors.dart';
import 'package:flutter/material.dart';
import '../services/quran_service.dart';
import '../routes/app_routes.dart';
import '../constants/arabic_text_styles.dart';

class QuranPage extends StatefulWidget {
  @override
  State<QuranPage> createState() => QuranPageState();
}

class QuranPageState extends State<QuranPage>
    with SingleTickerProviderStateMixin {
  bool isSurahSelected = true;
  List<dynamic> surahs = [];
  List<dynamic> juzs = [];
  List<dynamic> filteredSurahs = [];
  List<dynamic> filteredJuzs = [];
  bool isLoading = false;
  String errorMessage = '';
  String searchQuery = '';
  final QuranService _quranService = QuranService();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _loadSurahs();
    _loadJuzs();
  }

  Future<void> _loadSurahs() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      final data = await _quranService.fetchSurahs();
      setState(() {
        surahs = data;
        filteredSurahs = List.from(data);
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Gagal memuat data surah: ${e.toString()}';
        isLoading = false;
        // Clear surahs list to show empty state when error occurs
        surahs = [];
      });
    }
  }

  void _loadJuzs() {
    setState(() {
      juzs = _quranService.generateJuzList();
      filteredJuzs = List.from(juzs);
    });
  }

  void _performSearch(String query) {
    setState(() {
      searchQuery = query.toLowerCase().trim();

      if (searchQuery.isEmpty) {
        // If search is empty, show all items
        filteredSurahs = List.from(surahs);
        filteredJuzs = List.from(juzs);
      } else {
        // Filter surahs
        filteredSurahs =
            surahs.where((surah) {
              final englishName = (surah['englishName'] ?? '').toLowerCase();
              final arabicName = surah['name'] ?? '';
              final number = surah['number'].toString();

              return englishName.contains(searchQuery) ||
                  arabicName.contains(searchQuery) ||
                  number.contains(searchQuery);
            }).toList();

        // Filter juzs
        filteredJuzs =
            juzs.where((juz) {
              final name = (juz['name'] ?? '').toLowerCase();
              final arabicName = juz['arabicName'] ?? '';
              final number = juz['number'].toString();

              return name.contains(searchQuery) ||
                  arabicName.contains(searchQuery) ||
                  number.contains(searchQuery);
            }).toList();
      }
    });
  }

  void _clearSearch() {
    _searchController.clear();
    _searchFocusNode.unfocus();
    _performSearch('');
  }

  Widget _buildHighlightedText(String text, TextStyle style) {
    if (searchQuery.isEmpty || !text.toLowerCase().contains(searchQuery)) {
      return Text(text, style: style);
    }

    final List<TextSpan> spans = [];
    final lowerText = text.toLowerCase();
    int start = 0;

    while (true) {
      final index = lowerText.indexOf(searchQuery, start);
      if (index == -1) {
        // Add remaining text
        if (start < text.length) {
          spans.add(TextSpan(text: text.substring(start), style: style));
        }
        break;
      }

      // Add text before match
      if (index > start) {
        spans.add(TextSpan(text: text.substring(start, index), style: style));
      }

      // Add highlighted match
      spans.add(
        TextSpan(
          text: text.substring(index, index + searchQuery.length),
          style: style.copyWith(
            backgroundColor: const Color(0xFFFFE082),
            fontWeight: FontWeight.bold,
          ),
        ),
      );

      start = index + searchQuery.length;
    }

    return RichText(text: TextSpan(children: spans));
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _useOfflineMode() {
    setState(() {
      errorMessage = '';
      if (isSurahSelected) {
        surahs = _quranService.getStaticSurahs();
        filteredSurahs = List.from(surahs);
      }
    });

    // Show snackbar to inform user about offline mode
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Mode offline: Menampilkan data terbatas',
          style: TextStyle(fontFamily: 'OpenDyslexic'),
        ),
        backgroundColor: Color(0xFFB8D4B8),
        duration: Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
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
                      'Al-Quran',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                        fontFamily: 'OpenDyslexic',
                      ),
                    ),
                  ),
                  const SizedBox(width: 40),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          isSurahSelected = true;
                        });
                        _clearSearch(); // Reset search when switching tabs
                        if (surahs.isEmpty) {
                          _loadSurahs();
                        }
                      },
                      child: Opacity(
                        opacity: isSurahSelected ? 1.0 : 0.6,
                        child: Container(
                          height: 45,
                          decoration: BoxDecoration(
                            color: AppColors.secondary,
                            borderRadius: BorderRadius.circular(25),
                          ),
                          child: Center(
                            child: Text(
                              'Surah',
                              style: const TextStyle(
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
                  const SizedBox(width: 16),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          isSurahSelected = false;
                        });
                        _clearSearch(); // Reset search when switching tabs
                        if (juzs.isEmpty) {
                          _loadJuzs();
                        }
                      },
                      child: Opacity(
                        opacity: !isSurahSelected ? 1.0 : 0.6,
                        child: Container(
                          height: 45,
                          decoration: BoxDecoration(
                            color: AppColors.secondary,
                            borderRadius: BorderRadius.circular(25),
                          ),
                          child: Center(
                            child: Text(
                              'Juz',
                              style: const TextStyle(
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
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  focusNode: _searchFocusNode,
                  onChanged: _performSearch,
                  style: const TextStyle(
                    fontSize: 16,
                    fontFamily: 'OpenDyslexic',
                    color: Colors.black,
                  ),
                  cursorColor: Colors.black,
                  decoration: InputDecoration(
                    hintText: isSurahSelected ? 'Cari surah...' : 'Cari juz...',
                    hintStyle: const TextStyle(
                      color: Colors.grey,
                      fontFamily: 'OpenDyslexic',
                    ),
                    prefixIcon: const Icon(
                      Icons.search,
                      color: Colors.grey,
                      size: 20,
                    ),
                    suffixIcon:
                        searchQuery.isNotEmpty
                            ? IconButton(
                              icon: const Icon(
                                Icons.clear,
                                color: Colors.grey,
                                size: 20,
                              ),
                              onPressed: _clearSearch,
                            )
                            : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16.0),
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    Expanded(child: _buildListContent()),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListContent() {
    if (isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFD4C785)),
            ),
            const SizedBox(height: 16),
            const Text(
              'Memuat data...',
              style: TextStyle(
                fontSize: 16,
                color: Colors.black,
                fontFamily: 'OpenDyslexic',
              ),
            ),
          ],
        ),
      );
    }

    if (errorMessage.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off, size: 60, color: Colors.red),
            const SizedBox(height: 16),
            const Text(
              'Tidak dapat terhubung ke server',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black,
                fontFamily: 'OpenDyslexic',
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                errorMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                  fontFamily: 'OpenDyslexic',
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () {
                    if (isSurahSelected) {
                      _loadSurahs();
                    } else {
                      _loadJuzs();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD4C785),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: const Text(
                    'Coba Lagi',
                    style: TextStyle(
                      color: Colors.black,
                      fontFamily: 'OpenDyslexic',
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: _useOfflineMode,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFB8D4B8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: const Text(
                    'Mode Offline',
                    style: TextStyle(
                      color: Colors.black,
                      fontFamily: 'OpenDyslexic',
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    final currentList = isSurahSelected ? filteredSurahs : filteredJuzs;

    if (currentList.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              searchQuery.isEmpty ? Icons.inbox : Icons.search_off,
              size: 60,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              searchQuery.isEmpty
                  ? 'Tidak ada data'
                  : 'Tidak ditemukan hasil untuk "$searchQuery"',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black,
                fontFamily: 'OpenDyslexic',
              ),
            ),
            if (searchQuery.isNotEmpty) ...[
              const SizedBox(height: 12),
              TextButton(
                onPressed: _clearSearch,
                child: const Text(
                  'Hapus pencarian',
                  style: TextStyle(
                    color: AppColors.tertiary,
                    fontFamily: 'OpenDyslexic',
                    decoration: TextDecoration.underline,
                    decorationColor: AppColors.tertiary,
                  ),
                ),
              ),
            ],
          ],
        ),
      );
    }

    return Column(
      children: [
        // Search results counter (only show when searching)
        if (searchQuery.isNotEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFD4C785).withOpacity(0.3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${currentList.length} hasil ditemukan untuk "$searchQuery"',
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black87,
                fontFamily: 'OpenDyslexic',
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        // List items
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: currentList.length,
            itemBuilder:
                (context, index) => _buildListItem(currentList[index], index),
          ),
        ),
      ],
    );
  }

  Widget _buildListItem(dynamic item, int index) {
    final title =
        isSurahSelected
            ? (item['englishName'] ?? 'Surah ${index + 1}')
            : (item['name'] ?? 'Juz ${index + 1}');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.tertiary.withOpacity(0.2),
        borderRadius: BorderRadius.circular(25),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        title: _buildHighlightedText(
          title,
          const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black,
            fontFamily: 'OpenDyslexic',
          ),
        ),
        subtitle: null,
        onTap: () => _handleItemTap(item, index),
      ),
    );
  }

  void _handleItemTap(dynamic item, int index) {
    final itemName =
        isSurahSelected
            ? (item['englishName'] ?? 'Surah ${index + 1}')
            : (item['name'] ?? 'Juz ${index + 1}');
    final number = item['number'] ?? (index + 1);

    Navigator.pushNamed(
      context,
      AppRoutes.reading,
      arguments: {
        'type': isSurahSelected ? 'surah' : 'juz',
        'number': number,
        'name': itemName,
      },
    );
  }
}
