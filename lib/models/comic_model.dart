// lib/models/comic_model.dart

class Comic {
  final String id;
  final String title;
  final String slug;
  final String description;
  final String coverImage;
  final String status;
  
  // Data relasi dibuat opsional (nullable '?') 
  final List<Author>? authors;
  final List<Genre>? genres;
  final List<Chapter>? chapters;

  Comic({
    required this.id,
    required this.title,
    required this.slug,
    required this.description,
    required this.coverImage,
    required this.status,
    this.authors,
    this.genres,
    this.chapters,
  });

  // Factory method untuk mengubah format JSON menjadi Object Dart
  factory Comic.fromJson(Map<String, dynamic> json) {
    return Comic(
      id: json['komik_id'].toString(),
      title: json['title'] ?? '',
      slug: json['slug'] ?? '',
      description: json['description'] ?? 'Tidak ada sinopsis.',
      coverImage: json['cover_image'] ?? 'default.jpg',
      status: json['status'] ?? 'ongoing',
      
      // Proses mapping array JSON menjadi List Object jika datanya tidak null
      authors: json['authors'] != null
          ? (json['authors'] as List).map((i) => Author.fromJson(i)).toList()
          : null,
      genres: json['genres'] != null
          ? (json['genres'] as List).map((i) => Genre.fromJson(i)).toList()
          : null,
      chapters: json['chapters'] != null
          ? (json['chapters'] as List).map((i) => Chapter.fromJson(i)).toList()
          : null,
    );
  }
}

// Pendukung untuk fetch relasi (Author, Genre, Chapter)
class Author {
  final String name;
  final String role;

  Author({required this.name, required this.role});

  factory Author.fromJson(Map<String, dynamic> json) {
    return Author(
      name: json['name'] ?? '',
      role: json['role'] ?? '',
    );
  }
}

class Genre {
  final String name;

  Genre({required this.name});

  factory Genre.fromJson(Map<String, dynamic> json) {
    return Genre(
      name: json['name'] ?? '',
    );
  }
}

class Chapter {
  final String id;
  final String chapterNumber;

  Chapter({required this.id, required this.chapterNumber});

  factory Chapter.fromJson(Map<String, dynamic> json) {
    return Chapter(
      id: json['chapter_id'].toString(),
      chapterNumber: json['chapter_number'].toString(),
    );
  }
}