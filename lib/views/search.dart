// lib/views/search.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/comic_model.dart';
import '../services/api_service.dart';
import '../utils/theme.dart';
import '../utils/constants.dart';
import 'detail.dart'; // Tambahkan ini agar bisa di-klik ke halaman detail

class Search extends StatefulWidget {
  const Search({super.key});

  @override
  State<Search> createState() => _SearchState();
}

class _SearchState extends State<Search> {
  final ApiService _apiService = ApiService();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  
  bool _isSearching = false; 
  String _searchQuery = '';
  String _selectedSort = 'Terbaru';
  String? _selectedGenreSlug; 

  late Future<List<dynamic>> _futureGenres;
  Future<List<dynamic>>? _futureComics;

  @override
  void initState() {
    super.initState();
    _futureGenres = _apiService.fetchGenres();
    _fetchFilteredComics();

    _searchFocusNode.addListener(() {
      setState(() {
        _isSearching = _searchFocusNode.hasFocus || _searchController.text.isNotEmpty;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _fetchFilteredComics() {
    setState(() {
      if (_searchQuery.isNotEmpty) {
        _futureComics = _apiService.fetchKomik(query: 'keyword=$_searchQuery');
      } else if (_selectedGenreSlug != null) {
        _futureComics = _apiService.fetchKomik(query: 'genre=$_selectedGenreSlug');
      } else {
        _futureComics = _apiService.fetchKomik();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        titleSpacing: 16,
        title: _buildSearchBar(context),
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: _isSearching 
            ? _buildSearchResultsView(context) 
            : _buildExploreView(context), 
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor, 
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? Colors.white10 : Colors.black12), 
      ),
      child: TextField(
        controller: _searchController,
        focusNode: _searchFocusNode,
        style: GoogleFonts.beVietnamPro(
          color: Theme.of(context).textTheme.bodyLarge?.color, 
          fontSize: 14
        ),
        decoration: InputDecoration(
          hintText: 'Cari judul komik...',
          hintStyle: GoogleFonts.beVietnamPro(color: AppColors.textSecondary),
          prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary, size: 20),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, color: AppColors.textSecondary, size: 20),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _searchQuery = '';
                      _isSearching = _searchFocusNode.hasFocus;
                    });
                    _fetchFilteredComics();
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
        ),
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
          _fetchFilteredComics(); 
        },
      ),
    );
  }

  Widget _buildExploreView(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Eksplorasi',
                  style: GoogleFonts.beVietnamPro(
                    color: Theme.of(context).textTheme.bodyLarge?.color, 
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedSort,
                    dropdownColor: Theme.of(context).cardColor, 
                    icon: const Icon(Icons.sort, color: AppColors.primary, size: 20),
                    style: GoogleFonts.beVietnamPro(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 14),
                    items: ['Terbaru', 'Terlama'].map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    onChanged: (newValue) {
                      setState(() {
                        _selectedSort = newValue!;
                      });
                      // Refresh tampilan ketika disortir
                      setState(() {}); 
                    },
                  ),
                ),
              ],
            ),
          ),
          
          // [UPDATE UI]: Mengubah Wrap menjadi barisan scroll horizontal yang ramping
          FutureBuilder<List<dynamic>>(
            future: _futureGenres,
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const SizedBox.shrink();
              
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal, // Scroll ke samping
                padding: const EdgeInsets.symmetric(horizontal: 16), // Padding luar
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: [
                    // Chip "Semua"
                    Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: ChoiceChip(
                        label: const Text('Semua'),
                        selected: _selectedGenreSlug == null,
                        selectedColor: AppColors.primary,
                        backgroundColor: Theme.of(context).cardColor, 
                        showCheckmark: false, // Sembunyikan centang agar lebih hemat tempat
                        visualDensity: VisualDensity.compact, // Memperkecil tinggi chip
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(color: isDark ? Colors.white10 : Colors.black12),
                        ),
                        labelStyle: GoogleFonts.beVietnamPro(
                          color: _selectedGenreSlug == null ? Colors.white : Theme.of(context).textTheme.bodyLarge?.color, 
                          fontWeight: FontWeight.bold,
                          fontSize: 12, // Font diperkecil
                        ),
                        onSelected: (selected) {
                          setState(() { _selectedGenreSlug = null; });
                          _fetchFilteredComics();
                        },
                      ),
                    ),
                    // Chips dinamis dari Database
                    ...snapshot.data!.map((genre) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: ChoiceChip(
                          label: Text(genre['name']),
                          selected: _selectedGenreSlug == genre['slug'],
                          selectedColor: AppColors.accentPurple,
                          backgroundColor: Theme.of(context).cardColor, 
                          showCheckmark: false,
                          visualDensity: VisualDensity.compact,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: BorderSide(color: isDark ? Colors.white10 : Colors.black12),
                          ),
                          labelStyle: GoogleFonts.beVietnamPro(
                            color: _selectedGenreSlug == genre['slug'] ? Colors.white : Theme.of(context).textTheme.bodyLarge?.color, 
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                          onSelected: (selected) {
                            setState(() {
                              _selectedGenreSlug = selected ? genre['slug'] : null;
                            });
                            _fetchFilteredComics();
                          },
                        ),
                      );
                    }),
                  ],
                ),
              );
            }
          ),
          const SizedBox(height: 16),
          _buildComicGrid(context), 
        ],
      ),
    );
  }

  Widget _buildSearchResultsView(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            _searchQuery.isEmpty ? 'Mencari...' : 'Hasil untuk "$_searchQuery"',
            style: GoogleFonts.beVietnamPro(color: AppColors.textSecondary, fontSize: 14),
          ),
        ),
        Expanded(child: _buildComicGrid(context)), 
      ],
    );
  }

  Widget _buildComicGrid(BuildContext context) {
    return FutureBuilder<List<dynamic>>(
      future: _futureComics,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator(color: AppColors.primary)));
        } else if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Text(
                'Tidak ada komik yang ditemukan.',
                style: GoogleFonts.beVietnamPro(color: AppColors.textSecondary),
              ),
            ),
          );
        }

        List<dynamic> rawData = snapshot.data!;
        
        // [UPDATE BUG SORTING]:
        // API CI4 secara default mengirimkan data paling lama (ID 1) di urutan pertama.
        // Jadi, jika user memilih "Terbaru", kita HARUS me-reverse urutannya.
        // Jika user memilih "Terlama", kita biarkan urutan asli dari API.
        if (_selectedSort == 'Terbaru') {
          rawData = rawData.reversed.toList();
        }

        return GridView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          physics: _isSearching ? const BouncingScrollPhysics() : const NeverScrollableScrollPhysics(),
          shrinkWrap: !_isSearching,
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
    );
  }

  Widget _buildComicCard(BuildContext context, Comic comic) {
    return GestureDetector(
      onTap: () {
        // [UPDATE NAVIGASI]: Agar card bisa diklik masuk ke Detail
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
                borderRadius: BorderRadius.circular(8),
                color: Theme.of(context).cardColor, 
              ),
              clipBehavior: Clip.antiAlias,
              child: Builder(builder: (context) {
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
                    child: const Center(child: Icon(Icons.broken_image_outlined, color: AppColors.textSecondary)),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            comic.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.beVietnamPro(
              color: Theme.of(context).textTheme.bodyLarge?.color, 
              fontSize: 12, 
              fontWeight: FontWeight.w600, 
              height: 1.2
            ),
          ),
        ],
      ),
    );
  }
}