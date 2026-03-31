// lib/views/library.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/comic_model.dart';
import '../services/api_service.dart';
import '../utils/theme.dart';
import '../utils/constants.dart';
import 'detail.dart';

class LibraryPage extends StatefulWidget {
  const LibraryPage({super.key});

  @override
  State<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends State<LibraryPage> {
  final ApiService _apiService = ApiService();
  late Future<List<dynamic>> _futureLibrary;

  @override
  void initState() {
    super.initState();
    _futureLibrary = _loadLibrary();
  }

  Future<List<dynamic>> _loadLibrary() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId');
    if (userId != null) {
      return _apiService.fetchLibrary(userId);
    }
    return []; // Return list kosong jika tidak ada user
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: Text('Library Saya', style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.bold)),
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _futureLibrary,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          } else if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Text('Belum ada komik yang disimpan.', style: GoogleFonts.beVietnamPro(color: AppColors.textSecondary)),
            );
          }

          List<dynamic> rawData = snapshot.data!;
          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 0.55,
              crossAxisSpacing: 12,
              mainAxisSpacing: 16,
            ),
            itemCount: rawData.length,
            itemBuilder: (context, index) {
              Comic comic = Comic.fromJson(rawData[index]);
              return _buildComicCard(context, comic);
            },
          );
        },
      ),
    );
  }

  Widget _buildComicCard(BuildContext context, Comic comic) {
    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) => Detail(comicId: comic.id, comicTitle: comic.title)))
            .then((_) => setState(() { _futureLibrary = _loadLibrary(); })); // Refresh saat kembali
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
                String rawUrl = (comic.coverImage.toLowerCase() == 'default.jpg' || comic.coverImage.toLowerCase() == 'default.png')
                    ? '$baseUrlImg/assets/default.png' : '$baseUrlImg/assets/comics/${comic.coverImage}';
                return Image.network(Uri.encodeFull(rawUrl), fit: BoxFit.cover, width: double.infinity,
                  errorBuilder: (context, error, stackTrace) => Container(color: Theme.of(context).scaffoldBackgroundColor, child: const Center(child: Icon(Icons.broken_image_outlined, color: AppColors.textSecondary))),
                );
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