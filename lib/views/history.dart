// lib/views/history.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../utils/theme.dart';
import '../utils/constants.dart';
import 'reader.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  final ApiService _apiService = ApiService();
  late Future<List<dynamic>> _futureHistory;

  @override
  void initState() {
    super.initState();
    _futureHistory = _loadHistory();
  }

  Future<List<dynamic>> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId');
    if (userId != null) {
      return _apiService.fetchHistory(userId);
    }
    return [];
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: Text('Riwayat Bacaan', style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.bold)),
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _futureHistory,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          } else if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Text('Belum ada riwayat bacaan.', style: GoogleFonts.beVietnamPro(color: AppColors.textSecondary)),
            );
          }

          List<dynamic> historyData = snapshot.data!;
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: historyData.length,
            separatorBuilder: (context, index) => Divider(color: isDark ? Colors.white10 : Colors.black12, height: 30),
            itemBuilder: (context, index) {
              var item = historyData[index];
              // Asumsi JSON dari CI4: { 'history_id', 'komik_title', 'cover_image', 'chapter_id', 'chapter_number', 'last_read_at' }
              
              String baseUrlImg = ApiConstants.baseUrl.replaceAll('/api', '');
              String coverImage = item['cover_image'] ?? 'default.png';
              String rawUrl = (coverImage.toLowerCase() == 'default.jpg' || coverImage.toLowerCase() == 'default.png')
                  ? '$baseUrlImg/assets/default.png' : '$baseUrlImg/assets/comics/$coverImage';

              return InkWell(
                onTap: () {
                  // Lanjutkan membaca chapter tersebut
                  Navigator.push(context, MaterialPageRoute(
                    builder: (context) => Reader(
                      chapterId: item['chapter_id'].toString(),
                      chapterNumber: item['chapter_number'].toString(),
                      comicTitle: item['komik_title'] ?? 'Komik',
                    ),
                  )).then((_) => setState(() { _futureHistory = _loadHistory(); })); // Refresh saat kembali
                },
                child: Row(
                  children: [
                    // Thumbnail
                    Container(
                      width: 60,
                      height: 80,
                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), color: Theme.of(context).cardColor),
                      clipBehavior: Clip.antiAlias,
                      child: Image.network(Uri.encodeFull(rawUrl), fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(color: Theme.of(context).scaffoldBackgroundColor, child: const Center(child: Icon(Icons.broken_image_outlined, color: AppColors.textSecondary))),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item['komik_title'] ?? 'Judul Komik', style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.bold, fontSize: 16), maxLines: 1, overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 4),
                          Text('Chapter ${item['chapter_number']}', style: GoogleFonts.beVietnamPro(color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 14)),
                          const SizedBox(height: 4),
                          Text(item['last_read_at'] ?? '', style: GoogleFonts.beVietnamPro(color: AppColors.textSecondary, fontSize: 11)),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: AppColors.textSecondary),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}