import 'package:flutter/material.dart';
import '../services/quran_service.dart';
import '../routes/app_routes.dart';

class QuranPage extends StatefulWidget {
  @override
  State<QuranPage> createState() => QuranPageState();
}

class QuranPageState extends State<QuranPage> with SingleTickerProviderStateMixin {
  int _selectedTab = 0; // 0: Surah, 1: Juz, 2: Bookmarks
  List<dynamic> surahs = [];
  List<dynamic> juzs = [];
  List<dynamic> bookmarks = [];
  bool isLoading = false;
  String errorMessage = '';
  final QuranService _quranService = QuranService();

  @override
  void initState() {
    super.initState();
    _loadSurahs();
    _loadJuzs();
    _loadBookmarks();
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
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Failed to load surahs: ${e.toString()}';
        isLoading = false;
      });
    }
  }

  void _loadJuzs() {
    setState(() {
      juzs = _quranService.generateJuzList();
    });
  }

  Future<void> _loadBookmarks() async {
    try {
      final data = await _quranService.fetchLocalBookmarks();
      setState(() {
        bookmarks = data;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Failed to load bookmarks: ${e.toString()}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5DC),
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
                    decoration: const BoxDecoration(
                      color: Color(0xFFB8D4B8),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.black, size: 20),
                      onPressed: () => Navigator.pop(context),
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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() => _selectedTab = 0);
                        if (surahs.isEmpty) _loadSurahs();
                      },
                      child: Container(
                        height: 45,
                        decoration: BoxDecoration(
                          color: _selectedTab == 0 ? const Color(0xFFD4C785) : const Color(0xFFE8D4A3),
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
                  const SizedBox(width: 16),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() => _selectedTab = 1);
                        if (juzs.isEmpty) _loadJuzs();
                      },
                      child: Container(
                        height: 45,
                        decoration: BoxDecoration(
                          color: _selectedTab == 1 ? const Color(0xFFD4C785) : const Color(0xFFE8D4A3),
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
                  const SizedBox(width: 16),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() => _selectedTab = 2);
                        _loadBookmarks();
                      },
                      child: Container(
                        height: 45,
                        decoration: BoxDecoration(
                          color: _selectedTab == 2 ? const Color(0xFFD4C785) : const Color(0xFFE8D4A3),
                          borderRadius: BorderRadius.circular(25),
                        ),
                        child: Center(
                          child: Text(
                            'Bookmark',
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
                ],
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16.0),
                decoration: const BoxDecoration(
                  color: Color(0xFFE8C5C5),
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
            const CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFD4C785))),
            const SizedBox(height: 16),
            const Text(
              'Memuat data...',
              style: TextStyle(fontSize: 16, color: Colors.black, fontFamily: 'OpenDyslexic'),
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
            const Icon(Icons.error_outline, size: 60, color: Colors.red),
            const SizedBox(height: 16),
            const Text(
              'Terjadi kesalahan',
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
                style: const TextStyle(fontSize: 14, color: Colors.black87, fontFamily: 'OpenDyslexic'),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                if (_selectedTab == 0) {
                  _loadSurahs();
                } else if (_selectedTab == 1) {
                  _loadJuzs();
                } else {
                  _loadBookmarks();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD4C785),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              child: const Text(
                'Coba Lagi',
                style: TextStyle(color: Colors.black, fontFamily: 'OpenDyslexic'),
              ),
            ),
          ],
        ),
      );
    }

    final currentList = _selectedTab == 0 ? surahs : _selectedTab == 1 ? juzs : bookmarks;

    if (currentList.isEmpty) {
      return const Center(
        child: Text(
          'Tidak ada data',
          style: TextStyle(fontSize: 16, color: Colors.black, fontFamily: 'OpenDyslexic'),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: currentList.length,
      itemBuilder: (context, index) => _buildListItem(currentList[index], index),
    );
  }

  Widget _buildListItem(dynamic item, int index) {
    String title;
    String? subtitle;

    if (_selectedTab == 0) {
      title = item['englishName'] ?? 'Surah ${index + 1}';
      subtitle = item['name'];
    } else if (_selectedTab == 1) {
      title = item['name'] ?? 'Juz ${index + 1}';
      subtitle = item['arabicName'];
    } else {
      final surahNumber = item['surah_number'];
      final ayahNumber = item['ayah_number'];
      final surah = surahs.firstWhere(
        (s) => s['number'] == surahNumber,
        orElse: () => {'englishName': 'Surah $surahNumber'},
      );
      title = '${surah['englishName']}, Ayat $ayahNumber';
      subtitle = null;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFD4A5A5),
        borderRadius: BorderRadius.circular(25),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black,
            fontFamily: 'OpenDyslexic',
          ),
        ),
        subtitle: subtitle != null
            ? Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                  fontFamily: 'OpenDyslexic',
                ),
              )
            : null,
        trailing: _selectedTab == 2
            ? IconButton(
                icon: const Icon(Icons.delete, color: Colors.redAccent),
                onPressed: () async {
                  final success = await _quranService.deleteLocalBookmark(item['id']);
                  if (success) {
                    setState(() {
                      bookmarks.removeAt(index);
                    });
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Gagal menghapus bookmark')),
                    );
                  }
                },
              )
            : null,
        onTap: () => _handleItemTap(item, index),
      ),
    );
  }

  void _handleItemTap(dynamic item, int index) {
    String itemName;
    int number;

    if (_selectedTab == 0) {
      itemName = item['englishName'] ?? 'Surah ${index + 1}';
      number = item['number'] ?? (index + 1);
      Navigator.pushNamed(
        context,
        AppRoutes.reading,
        arguments: {
          'type': 'surah',
          'number': number,
          'name': itemName,
        },
      );
    } else if (_selectedTab == 1) {
      itemName = item['name'] ?? 'Juz ${index + 1}';
      number = item['number'] ?? (index + 1);
      Navigator.pushNamed(
        context,
        AppRoutes.reading,
        arguments: {
          'type': 'juz',
          'number': number,
          'name': itemName,
        },
      );
    } else {
      itemName = surahs.firstWhere(
        (s) => s['number'] == item['surah_number'],
        orElse: () => {'englishName': 'Surah ${item['surah_number']}'},
      )['englishName'];
      number = item['surah_number'];
      Navigator.pushNamed(
        context,
        AppRoutes.reading,
        arguments: {
          'type': 'surah',
          'number': number,
          'name': itemName,
        },
      );
    }
  }
}