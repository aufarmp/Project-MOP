// lib/views/popular.dart
// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/comic_model.dart';
import '../services/api_service.dart';
import '../utils/theme.dart';
import '../utils/constants.dart';

import 'detail.dart';

class Popular extends StatelessWidget {
  const Popular({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return DefaultTabController(
      length: 5,
      child: Scaffold(
        appBar: AppBar(
          elevation: 0,
          title: Text(
            'Populer',
            style: GoogleFonts.beVietnamPro(
              fontWeight: FontWeight.bold,
              // Warna otomatis mengikuti tema
            ),
          ),
          bottom: TabBar(
            isScrollable: true,
            indicatorColor: AppColors.primary,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textSecondary,
            labelStyle: GoogleFonts.beVietnamPro(fontWeight: FontWeight.bold),
            dividerColor: isDark ? Colors.white10 : Colors.black12, // Dinamis
            tabs: const [
              Tab(text: 'Semua'),
              Tab(text: 'Action'),
              Tab(text: 'Romance'),
              Tab(text: 'Fantasy'),
              Tab(text: 'Slice of Life'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            ComicTabContent(query: 'type=popular'),
            ComicTabContent(query: 'genre=action'),
            ComicTabContent(query: 'genre=romance'),
            ComicTabContent(query: 'genre=fantasy'),
            ComicTabContent(query: 'genre=slice-of-life'),
          ],
        ),
      ),
    );
  }
}

class ComicTabContent extends StatefulWidget {
  final String query;
  
  const ComicTabContent({super.key, required this.query});

  @override
  State<ComicTabContent> createState() => _ComicTabContentState();
}

class _ComicTabContentState extends State<ComicTabContent> {
  final ApiService _apiService = ApiService();
  late Future<List<dynamic>> _futureKomik;

  @override
  void initState() {
    super.initState();
    _futureKomik = _apiService.fetchKomik(query: widget.query);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<dynamic>>(
      future: _futureKomik,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primary));
        } else if (snapshot.hasError) {
          return Center(
            child: Text(
              'Gagal memuat data.\nPastikan server menyala.',
              style: const TextStyle(color: Colors.redAccent),
              textAlign: TextAlign.center,
            ),
          );
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Text(
              'Belum ada komik di kategori ini.',
              style: GoogleFonts.beVietnamPro(color: AppColors.textSecondary),
            ),
          );
        }

        List<dynamic> rawData = snapshot.data!;
        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.65,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: rawData.length,
          itemBuilder: (context, index) {
            Comic comic = Comic.fromJson(rawData[index]);
            return _buildComicCard(context, comic);
          },
        );
      },
    );
  }

  Widget _buildComicCard(BuildContext context, Comic comic) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => Detail(
              comicId: comic.id,
              comicTitle: comic.title,
            ),
          ),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Theme.of(context).cardColor, // Dinamis
              ),
              clipBehavior: Clip.antiAlias,
              child: Builder(
                builder: (context) {
                  String baseUrlImg = ApiConstants.baseUrl.replaceAll('/api', '');
                  String rawUrl = (comic.coverImage.toLowerCase() == 'default.jpg' || comic.coverImage.toLowerCase() == 'default.png')
                      ? '$baseUrlImg/assets/default.png'
                      : '$baseUrlImg/assets/comics/${comic.coverImage}';
                  
                  return Image.network(
                    Uri.encodeFull(rawUrl),
                    fit: BoxFit.cover,
                    width: double.infinity,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: Theme.of(context).scaffoldBackgroundColor, 
                      child: const Center(child: Icon(Icons.broken_image_outlined, color: AppColors.textSecondary, size: 40)),
                    ),
                  );
                }
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            comic.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.beVietnamPro(
              color: Theme.of(context).textTheme.bodyLarge?.color, 
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: comic.status.toLowerCase() == 'ongoing' 
                  ? AppColors.primary.withOpacity(0.2) 
                  : AppColors.accentPurple.withOpacity(0.2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              comic.status.toUpperCase(),
              style: GoogleFonts.beVietnamPro(
                color: comic.status.toLowerCase() == 'ongoing' ? AppColors.primary : AppColors.accentPurple,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}