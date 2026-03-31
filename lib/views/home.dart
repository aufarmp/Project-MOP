// lib/views/home.dart
// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/comic_model.dart';
import '../services/api_service.dart';
import '../utils/theme.dart';
import '../utils/constants.dart';

import 'login.dart';
import 'history.dart'; // Import halaman history
import 'reader.dart';  // Import halaman reader
import 'detail.dart';

class Home extends StatefulWidget {
  final VoidCallback? onNavigateToPopular; 

  const Home({super.key, this.onNavigateToPopular});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final ApiService _apiService = ApiService();
  
  late Future<List<dynamic>> _futurePopular;
  late Future<List<dynamic>> _futureForYou;
  
  // State untuk Lanjut Baca (History)
  bool _isLoggedIn = false;
  String? _userId;
  Future<List<dynamic>>? _futureHistory;

  @override
  void initState() {
    super.initState();
    _futurePopular = _apiService.fetchKomik(query: 'type=popular');
    _futureForYou = _apiService.fetchKomik(); 
    _loadUserSession();
  }

  // Mengecek apakah user login dan mengambil history
  Future<void> _loadUserSession() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
      if (_isLoggedIn) {
        _userId = prefs.getString('userId');
        _futureHistory = _apiService.fetchHistory(_userId!);
      } else {
        _futureHistory = null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: Text(
          'Comi.id',
          style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.bold, fontSize: 22),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            
            // --- SECTION 1: LANJUT BACA ---
            _buildSectionHeader(context, 'Lanjut Baca', onTapSeeAll: () {
              if (_isLoggedIn) {
                // Jika login, arahkan ke halaman History
                Navigator.push(context, MaterialPageRoute(builder: (context) => const HistoryPage()))
                    .then((_) => _loadUserSession()); // Refresh saat kembali
              } else {
                // Jika belum, arahkan ke Login
                Navigator.push(context, MaterialPageRoute(builder: (context) => const Login()))
                    .then((value) { if (value == true) _loadUserSession(); });
              }
            }),
            
            // Bagian Konten "Lanjut Baca"
            _buildHistorySection(isDark),
            
            const SizedBox(height: 24),

            // --- SECTION 2: TERPOPULER ---
            _buildSectionHeader(context, 'Terpopuler', onTapSeeAll: widget.onNavigateToPopular),
            SizedBox(
              height: 200,
              child: FutureBuilder<List<dynamic>>(
                future: _futurePopular,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: AppColors.primary));
                  } else if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: Text('Tidak ada data populer.', style: TextStyle(color: AppColors.textSecondary)));
                  }

                  List<dynamic> rawData = snapshot.data!;
                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    scrollDirection: Axis.horizontal,
                    itemCount: rawData.length > 5 ? 5 : rawData.length,
                    itemBuilder: (context, index) {
                      Comic comic = Comic.fromJson(rawData[index]);
                      return Container(
                        width: 120,
                        margin: const EdgeInsets.only(right: 12),
                        child: _buildComicCard(context, comic, isCompact: true),
                      );
                    },
                  );
                },
              ),
            ),

            const SizedBox(height: 24),

            // --- SECTION 3: UNTUK ANDA ---
            _buildSectionHeader(context, 'Untuk Anda', showSeeAll: false),
            FutureBuilder<List<dynamic>>(
              future: _futureForYou,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(padding: EdgeInsets.all(32.0), child: Center(child: CircularProgressIndicator(color: AppColors.primary)));
                } else if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Padding(padding: EdgeInsets.all(32.0), child: Center(child: Text('Tidak ada komik.', style: TextStyle(color: AppColors.textSecondary))));
                }

                List<dynamic> rawData = snapshot.data!;
                return GridView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,      
                    childAspectRatio: 0.55, 
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: rawData.length,
                  itemBuilder: (context, index) {
                    Comic comic = Comic.fromJson(rawData[index]);
                    return _buildComicCard(context, comic, isCompact: true);
                  },
                );
              },
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  // --- WIDGET KHUSUS: Konten Riwayat (Lanjut Baca) ---
  Widget _buildHistorySection(bool isDark) {
    if (!_isLoggedIn) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(20),
        width: double.infinity,
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor, 
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isDark ? Colors.white10 : Colors.black12), 
        ),
        child: Column(
          children: [
            const Icon(Icons.lock_outline, color: AppColors.textSecondary, size: 40),
            const SizedBox(height: 12),
            Text('Masuk untuk melihat komik yang sedang dibaca.', style: GoogleFonts.beVietnamPro(color: AppColors.textSecondary, fontSize: 13)),
            const SizedBox(height: 12),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, elevation: 0),
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const Login())).then((v) { if (v == true) _loadUserSession(); });
              },
              child: const Text('Masuk'),
            )
          ],
        ),
      );
    }

    return FutureBuilder<List<dynamic>>(
      future: _futureHistory,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(padding: EdgeInsets.all(20), child: Center(child: CircularProgressIndicator(color: AppColors.primary)));
        } else if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: const EdgeInsets.all(20),
            width: double.infinity,
            decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(12), border: Border.all(color: isDark ? Colors.white10 : Colors.black12)),
            child: Column(
              children: [
                const Icon(Icons.history_edu, color: AppColors.textSecondary, size: 40),
                const SizedBox(height: 12),
                Text('Belum ada komik yang dibaca.', style: GoogleFonts.beVietnamPro(color: AppColors.textSecondary, fontSize: 13)),
              ],
            ),
          );
        }

        // Tampilkan riwayat TERATAS (indeks 0)
        var latestHistory = snapshot.data![0];
        String baseUrlImg = ApiConstants.baseUrl.replaceAll('/api', '');
        String coverImage = latestHistory['cover_image'] ?? 'default.png';
        String rawUrl = (coverImage.toLowerCase() == 'default.jpg' || coverImage.toLowerCase() == 'default.png') ? '$baseUrlImg/assets/default.png' : '$baseUrlImg/assets/comics/$coverImage';

        return GestureDetector(
          onTap: () {
            // Lanjutkan membaca chapter tersebut
            Navigator.push(context, MaterialPageRoute(
              builder: (context) => Reader(
                chapterId: latestHistory['chapter_id'].toString(),
                chapterNumber: latestHistory['chapter_number'].toString(),
                comicTitle: latestHistory['komik_title'] ?? 'Komik',
              ),
            )).then((_) => _loadUserSession()); // Refresh saat kembali dari reader
          },
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor, 
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isDark ? Colors.white10 : Colors.black12), 
            ),
            child: Row(
              children: [
                Container(
                  width: 60, height: 80,
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), color: Theme.of(context).scaffoldBackgroundColor),
                  clipBehavior: Clip.antiAlias,
                  child: Image.network(Uri.encodeFull(rawUrl), fit: BoxFit.cover, errorBuilder: (c, e, s) => const Icon(Icons.broken_image_outlined)),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(latestHistory['komik_title'] ?? 'Judul Komik', style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.bold, fontSize: 16, color: Theme.of(context).textTheme.bodyLarge?.color), maxLines: 1, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 4),
                      Text('Melanjutkan Chapter ${latestHistory['chapter_number']}', style: GoogleFonts.beVietnamPro(color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 13)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), shape: BoxShape.circle),
                  child: const Icon(Icons.play_arrow_rounded, color: AppColors.primary),
                )
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, {bool showSeeAll = true, VoidCallback? onTapSeeAll}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: GoogleFonts.beVietnamPro(color: Theme.of(context).textTheme.bodyLarge?.color, fontSize: 18, fontWeight: FontWeight.bold)),
          if (showSeeAll)
            GestureDetector(
              onTap: onTapSeeAll,
              child: Text('Lihat Semua', style: GoogleFonts.beVietnamPro(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.bold)),
            ),
        ],
      ),
    );
  }

  Widget _buildComicCard(BuildContext context, Comic comic, {bool isCompact = false}) {
    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) => Detail(comicId: comic.id, comicTitle: comic.title)))
            .then((_) => _loadUserSession()); // Refresh home in case history updated
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), color: Theme.of(context).cardColor),
              clipBehavior: Clip.antiAlias,
              child: Builder(builder: (context) {
                String baseUrlImg = ApiConstants.baseUrl.replaceAll('/api', '');
                String rawUrl = (comic.coverImage.toLowerCase() == 'default.jpg' || comic.coverImage.toLowerCase() == 'default.png') ? '$baseUrlImg/assets/default.png' : '$baseUrlImg/assets/comics/${comic.coverImage}';
                return Image.network(Uri.encodeFull(rawUrl), fit: BoxFit.cover, width: double.infinity, errorBuilder: (c, e, s) => Container(color: Theme.of(context).scaffoldBackgroundColor, child: const Center(child: Icon(Icons.broken_image_outlined, color: AppColors.textSecondary))));
              }),
            ),
          ),
          const SizedBox(height: 6),
          Text(comic.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: GoogleFonts.beVietnamPro(color: Theme.of(context).textTheme.bodyLarge?.color, fontSize: 12, fontWeight: FontWeight.w600, height: 1.2)),
        ],
      ),
    );
  }
}