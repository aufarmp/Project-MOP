// lib/views/detail.dart
// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/comic_model.dart';
import '../services/api_service.dart';
import '../utils/theme.dart';
import '../utils/constants.dart';

import 'login.dart';
import 'reader.dart'; 

class Detail extends StatefulWidget {
  final String comicId;
  final String comicTitle; 

  const Detail({super.key, required this.comicId, required this.comicTitle});

  @override
  State<Detail> createState() => _DetailState();
}

class _DetailState extends State<Detail> {
  final ApiService _apiService = ApiService();
  
  late Future<Map<String, dynamic>> _futureComicDetail;

  bool _isLoggedIn = false;
  String? _userId;
  bool _isBookmarked = false; 

  @override
  void initState() {
    super.initState();
    _futureComicDetail = _initData();
  }

  // Cek sesi user, lalu panggil API dengan parameter user_id
  Future<Map<String, dynamic>> _initData() async {
    final prefs = await SharedPreferences.getInstance();
    _isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
    
    if (_isLoggedIn) {
      _userId = prefs.getString('userId');
    }

    // Panggil API
    final result = await _apiService.fetchKomikDetail(widget.comicId, userId: _userId);
    
    // Set status tombol bookmark sesuai data dari database
    if (mounted) {
      setState(() {
        _isBookmarked = result['is_bookmarked'];
      });
    }

    return result;
  }

  Future<void> _refreshSession() async {
    setState(() {
      _futureComicDetail = _initData();
    });
  }

  // Fungsi saat tombol bookmark ditekan
  void _handleBookmark() async {
    if (!_isLoggedIn || _userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Silakan masuk terlebih dahulu untuk menyimpan komik.')),
      );
      final result = await Navigator.push(context, MaterialPageRoute(builder: (context) => const Login()));
      if (result == true) _refreshSession(); 
      return;
    }

    try {
      setState(() { _isBookmarked = !_isBookmarked; });
      final response = await _apiService.toggleBookmark(_userId!, widget.comicId);
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(response['message'] ?? 'Bookmark diperbarui')),
      );
    } catch (e) {
      setState(() { _isBookmarked = !_isBookmarked; });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gagal memperbarui bookmark')));
    }
  }

  String _getImageUrl(String coverImage) {
    String baseUrlImg = ApiConstants.baseUrl.replaceAll('/api', '');
    if (coverImage.toLowerCase() == 'default.jpg' || coverImage.toLowerCase() == 'default.png') {
      return Uri.encodeFull('$baseUrlImg/assets/default.png');
    }
    return Uri.encodeFull('$baseUrlImg/assets/comics/$coverImage');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      // Tipe Data diubah menjadi Map
      body: FutureBuilder<Map<String, dynamic>>(
        future: _futureComicDetail,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Scaffold(
              appBar: AppBar(title: Text(widget.comicTitle)),
              body: const Center(child: CircularProgressIndicator(color: AppColors.primary)),
            );
          } else if (snapshot.hasError) {
            return Scaffold(
              appBar: AppBar(title: Text(widget.comicTitle)),
              body: Center(child: Text('Error: ${snapshot.error}')),
            );
          } else if (!snapshot.hasData) {
            return const Center(child: Text('Data tidak ditemukan'));
          }

          // Ekstrak model Comic dari dalam Map
          Comic comic = snapshot.data!['comic'];
          String coverUrl = _getImageUrl(comic.coverImage);

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 300.0,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  title: Text(
                    comic.title,
                    style: GoogleFonts.beVietnamPro(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      shadows: [const Shadow(color: Colors.black, blurRadius: 10)], 
                    ),
                  ),
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.network(coverUrl, fit: BoxFit.cover),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Theme.of(context).scaffoldBackgroundColor, 
                            ],
                            stops: const [0.5, 1.0],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                actions: [
                  IconButton(
                    icon: Icon(_isBookmarked ? Icons.bookmark : Icons.bookmark_add_outlined),
                    color: _isBookmarked ? AppColors.primary : null,
                    onPressed: _handleBookmark,
                  ),
                ],
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: comic.status.toLowerCase() == 'ongoing' 
                                  ? AppColors.primary.withOpacity(0.2) 
                                  : AppColors.accentPurple.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              comic.status.toUpperCase(),
                              style: GoogleFonts.beVietnamPro(
                                color: comic.status.toLowerCase() == 'ongoing' ? AppColors.primary : AppColors.accentPurple,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          if (comic.authors != null && comic.authors!.isNotEmpty)
                            Text(
                              comic.authors!.map((a) => a.name).join(', '),
                              style: GoogleFonts.beVietnamPro(
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      if (comic.genres != null && comic.genres!.isNotEmpty)
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: comic.genres!.map((genre) {
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Theme.of(context).cardColor,
                                border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                genre.name,
                                style: GoogleFonts.beVietnamPro(fontSize: 12, fontWeight: FontWeight.w500),
                              ),
                            );
                          }).toList(),
                        ),
                      
                      const SizedBox(height: 24),

                      Text(
                        'Sinopsis',
                        style: GoogleFonts.beVietnamPro(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        comic.description,
                        textAlign: TextAlign.justify,
                        style: GoogleFonts.beVietnamPro(
                          color: Theme.of(context).textTheme.bodyLarge?.color?.withOpacity(0.8),
                          height: 1.5,
                        ),
                      ),
                      
                      const SizedBox(height: 30),
                      Divider(color: isDark ? Colors.white10 : Colors.black12),
                      const SizedBox(height: 16),

                      Text(
                        'Daftar Chapter',
                        style: GoogleFonts.beVietnamPro(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),

              if (comic.chapters != null && comic.chapters!.isNotEmpty)
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      Chapter chapter = comic.chapters![index];
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        leading: Container(
                          height: 40,
                          width: 40,
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardColor,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
                          ),
                          child: const Center(child: Icon(Icons.menu_book, size: 20, color: AppColors.primary)),
                        ),
                        title: Text(
                          'Chapter ${chapter.chapterNumber}',
                          style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.bold),
                        ),
                        trailing: const Icon(Icons.chevron_right, color: AppColors.textSecondary),
                        onTap: () {
                          if (!_isLoggedIn) {
                            ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Silakan masuk untuk membaca komik.')));
                            Navigator.push(context, MaterialPageRoute(builder: (context) => const Login())).then((value) {
                              if (value == true) _refreshSession();
                            });
                            return;
                          }

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => Reader(
                                chapterId: chapter.id.toString(),
                                chapterNumber: chapter.chapterNumber.toString(),
                                comicTitle: comic.title,
                              ),
                            ),
                          );
                        },
                      );
                    },
                    childCount: comic.chapters!.length,
                  ),
                )
              else
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Center(
                      child: Text(
                        'Belum ada chapter tersedia.',
                        style: GoogleFonts.beVietnamPro(color: AppColors.textSecondary),
                      ),
                    ),
                  ),
                ),
                
              const SliverToBoxAdapter(child: SizedBox(height: 50)),
            ],
          );
        },
      ),
    );
  }
}