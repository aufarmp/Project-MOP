// lib/views/reader.dart
// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../utils/theme.dart';
import '../utils/constants.dart';

class Reader extends StatefulWidget {
  final String chapterId;
  final String chapterNumber;
  final String comicTitle;

  const Reader({
    super.key,
    required this.chapterId,
    required this.chapterNumber,
    required this.comicTitle,
  });

  @override
  State<Reader> createState() => _ReaderState();
}

class _ReaderState extends State<Reader> {
  final ApiService _apiService = ApiService();
  late Future<Map<String, dynamic>> _futureChapterData;
  bool _showAppBar = true; 

  @override
  void initState() {
    super.initState();
    // Memuat data API setelah mendapatkan User ID dari lokal
    _futureChapterData = _loadDataWithHistory();
  }

  // Mengambil User ID (jika ada) lalu fetch API
  Future<Map<String, dynamic>> _loadDataWithHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId'); // Akan null jika tamu
    
    // API ini otomatis akan mencatat history di CI4 jika userId tidak null
    return _apiService.fetchChapterPages(widget.chapterId, userId: userId);
  }

  void _toggleAppBar() {
    setState(() {
      _showAppBar = !_showAppBar;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Background hitam sangat nyaman untuk membaca
      extendBodyBehindAppBar: true, 
      appBar: _showAppBar
          ? AppBar(
              backgroundColor: Colors.black.withOpacity(0.85),
              elevation: 0,
              iconTheme: const IconThemeData(color: Colors.white),
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.comicTitle,
                    style: GoogleFonts.beVietnamPro(fontSize: 14, color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Chapter ${widget.chapterNumber}',
                    style: GoogleFonts.beVietnamPro(fontSize: 12, color: AppColors.textSecondary),
                  ),
                ],
              ),
            )
          : null, 
      body: GestureDetector(
        onTap: _toggleAppBar, 
        child: FutureBuilder<Map<String, dynamic>>(
          future: _futureChapterData,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: AppColors.primary));
            } else if (snapshot.hasError) {
              // Jika gagal, error aslinya akan tercetak di sini
              return Padding(
                padding: const EdgeInsets.all(24.0),
                child: Center(child: Text('Gagal memuat halaman:\n\n${snapshot.error}', style: const TextStyle(color: Colors.white), textAlign: TextAlign.center)),
              );
            } else if (!snapshot.hasData || snapshot.data!['pages'] == null) {
              return const Center(child: Text('Chapter ini belum memiliki halaman.', style: TextStyle(color: Colors.white)));
            }

            // Ekstrak data dari format API CI4
            Map<String, dynamic> data = snapshot.data!;
            List<dynamic> pages = data['pages'];
            var prevChapter = data['prevChapter'];
            var nextChapter = data['nextChapter'];

            // [UPDATE] Kita menghapus logika sorting di sini. 
            // Flutter akan menampilkan halaman murni sesuai urutan yang dikirim dari CI4.

            return ListView.builder(
              padding: EdgeInsets.zero,
              itemCount: pages.isEmpty ? 0 : pages.length + 1,
              itemBuilder: (context, index) {
                
                // Menampilkan tombol navigasi di bagian paling bawah
                if (index == pages.length) {
                  return _buildBottomNavigation(prevChapter, nextChapter);
                }

                // Render Gambar Komik
                var page = pages[index];
                String baseUrlImg = ApiConstants.baseUrl.replaceAll('/api', '');
                
                // Menggabungkan path gambar sesuai folder (contoh: shangri-la-frontier/chapter-1/...)
                String rawUrl = '$baseUrlImg/assets/comics/${page['image_url']}';
                
                return Image.network(
                  Uri.encodeFull(rawUrl),
                  fit: BoxFit.fitWidth, 
                  width: double.infinity,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return SizedBox(
                      height: 300,
                      child: Center(
                        child: CircularProgressIndicator(
                          color: Colors.white24,
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                              : null,
                        ),
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 200,
                    color: Colors.grey[900],
                    child: const Center(child: Icon(Icons.broken_image, color: Colors.white54, size: 50)),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  // Widget Tambahan untuk Navigasi Antar Chapter
  Widget _buildBottomNavigation(dynamic prevChapter, dynamic nextChapter) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 16),
      color: Colors.black,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Tombol Prev
          if (prevChapter != null)
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white10,
                foregroundColor: Colors.white,
                elevation: 0,
              ),
              icon: const Icon(Icons.arrow_back_ios, size: 14),
              label: const Text('Prev Chapter'),
              onPressed: () {
                // Navigasi menggantikan halaman saat ini
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => Reader(
                    chapterId: prevChapter['chapter_id'].toString(),
                    chapterNumber: prevChapter['chapter_number'].toString(),
                    comicTitle: widget.comicTitle,
                  )),
                );
              },
            )
          else
            const SizedBox(), // Spacer kosong jika tidak ada prev

          // Tombol Next
          if (nextChapter != null)
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
              ),
              onPressed: () {
                // Navigasi menggantikan halaman saat ini
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => Reader(
                    chapterId: nextChapter['chapter_id'].toString(),
                    chapterNumber: nextChapter['chapter_number'].toString(),
                    comicTitle: widget.comicTitle,
                  )),
                );
              },
              child: const Row(
                children: [
                  Text('Next Chapter'),
                  SizedBox(width: 8),
                  Icon(Icons.arrow_forward_ios, size: 14),
                ],
              ),
            )
          else
            const SizedBox(), // Spacer kosong jika tidak ada next
        ],
      ),
    );
  }
}