// lib/services/api_service.dart
import 'dart:convert';
import 'package:comic_flutter/models/comic_model.dart';
import 'package:http/http.dart' as http;
import '../utils/constants.dart';

class ApiService {

  // ==========================================
  // FUNGSI 1: Mengambil Data Komik
  // ==========================================
  Future<List<dynamic>> fetchKomik({String? query}) async {
    try {
      String url = ApiConstants.endpointKomik;
      if (query != null && query.isNotEmpty) {
        url += '?$query'; 
      }

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        // Parse respons dari server menjadi Object
        var jsonResponse = json.decode(response.body);
        
        return jsonResponse['data'] as List<dynamic>;
        
      } else {
        throw Exception('Gagal memuat data komik: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Terjadi kesalahan koneksi: $e');
    }
  }
  
  // ==========================================
  // FUNGSI 2: Mengambil Data Genre
  // ==========================================
  Future<List<dynamic>> fetchGenres() async {
    try {
      // Mengambil data dari endpoint /api/komik/genres di CI4
      final response = await http.get(Uri.parse('${ApiConstants.baseUrl}/komik/genres'));

      if (response.statusCode == 200) {
        var jsonResponse = json.decode(response.body);
        return jsonResponse['data'] as List<dynamic>;
      } else {
        throw Exception('Gagal memuat genre');
      }
    } catch (e) {
      throw Exception('Terjadi kesalahan koneksi: $e');
    }
  }

  // ==========================================
  // FUNGSI 3: Mengambil Detail 1 Komik
  // ==========================================
  Future<Map<String, dynamic>> fetchKomikDetail(String id, {String? userId}) async {
    try {
      // Menyusun URL. Jika ada userId, tambahkan sebagai parameter agar CI4 bisa mengecek bookmark
      String url = '${ApiConstants.endpointKomik}/$id';
      if (userId != null && userId.isNotEmpty) {
        url += '?user_id=$userId';
      }

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        var jsonResponse = json.decode(response.body);
        var data = jsonResponse['data'];

        // Mengembalikan Map berisi objek Comic dan status bookmark
        return {
          'comic': Comic.fromJson(data),
          'is_bookmarked': data['is_bookmarked'] ?? false,
        };
      } else {
        throw Exception('Gagal memuat detail komik: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Terjadi kesalahan koneksi: $e');
    }
  }

  // ==========================================
  // FUNGSI 4: Autentikasi / Login
  // ==========================================
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/auth/login'), 
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
          'password': password,
        }),
      );

      var jsonResponse = json.decode(response.body);

      if (response.statusCode == 200) {
        return jsonResponse;
      } else {
        // Jika gagal (email/password salah), lempar pesan error dari server
        throw Exception(jsonResponse['message'] ?? 'Gagal login, periksa kembali email dan password Anda.');
      }
    } catch (e) {
      throw Exception('Terjadi kesalahan: $e');
    }
  }

  // ==========================================
  // FUNGSI 5: Toggle Bookmark (Tambah/Hapus)
  // ==========================================
  Future<Map<String, dynamic>> toggleBookmark(String userId, String comicId) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/user/bookmark'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'user_id': userId,
          'komik_id': comicId,
        }),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
    
        throw Exception('Server Error ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      throw Exception('$e');
    }
  }

  // ==========================================
  // FUNGSI 6: Mengambil Data Halaman Chapter
  // ==========================================
  Future<Map<String, dynamic>> fetchChapterPages(String chapterId, {String? userId}) async {
    try {
      String url = '${ApiConstants.baseUrl}/chapter/$chapterId';     
      // Jika user login (userId ada dan bukan kata "null"), sisipkan ke dalam query parameter
      if (userId != null && userId.isNotEmpty && userId != 'null') {
        url += '?user_id=$userId';
      }

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        var jsonResponse = json.decode(response.body);
        return jsonResponse['data'] as Map<String, dynamic>;
      } else {

        throw Exception('Server Error ${response.statusCode}: ${response.body}');
      }
    } catch (e) {

      throw Exception('$e');
    }
  }

  // ==========================================
  // FUNGSI 7: Fetch Library (Bookmark User)
  // ==========================================
  Future<List<dynamic>> fetchLibrary(String userId) async {
    try {
      final response = await http.get(Uri.parse('${ApiConstants.baseUrl}/user/library/$userId'));
      if (response.statusCode == 200) {
        var jsonResponse = json.decode(response.body);
        return jsonResponse['data'] as List<dynamic>;
      } else {
        throw Exception('Gagal memuat library');
      }
    } catch (e) {
      throw Exception('Terjadi kesalahan: $e');
    }
  }

  // ==========================================
  // FUNGSI 8: Fetch History (Riwayat Bacaan User)
  // ==========================================
  Future<List<dynamic>> fetchHistory(String userId) async {
    try {
      final response = await http.get(Uri.parse('${ApiConstants.baseUrl}/user/history/$userId'));
      if (response.statusCode == 200) {
        var jsonResponse = json.decode(response.body);
        return jsonResponse['data'] as List<dynamic>;
      } else {
        throw Exception('Gagal memuat riwayat bacaan');
      }
    } catch (e) {
      throw Exception('Terjadi kesalahan: $e');
    }
  }
}