// lib/views/more.dart
// ignore_for_file: use_build_context_synchronously, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/theme.dart';
import '../main.dart';
import 'login.dart';
import 'library.dart';
import 'history.dart';

class More extends StatefulWidget {
  const More({super.key});

  @override
  State<More> createState() => _MoreState();
}

class _MoreState extends State<More> {
  bool _isDarkMode = themeNotifier.value == ThemeMode.dark;
  final String _selectedLanguage = 'Indonesia';
  
  bool _isLoggedIn = false; 
  String _userName = 'Pengguna Tamu';
  String _userEmail = 'Silakan masuk untuk menyimpan komik';

  @override
  void initState() {
    super.initState();
    _loadUserSession(); 
  }

  // Membaca data dari SharedPreferences
  Future<void> _loadUserSession() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
      if (_isLoggedIn) {
        _userName = prefs.getString('userName') ?? 'User Comi';
        _userEmail = prefs.getString('userEmail') ?? 'user@comi.id';
      } else {
        _userName = 'Pengguna Tamu';
        _userEmail = 'Silakan masuk untuk menyimpan komik';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: Text(
          'Menu Lainnya',
          style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 1. BAGIAN PROFIL DINAMIS
            _buildProfileHeader(),
            const SizedBox(height: 16),

            // 2. BAGIAN AKTIVITAS (Hanya berfungsi jika Login)
            _buildMenuSection(
              title: 'Aktivitas',
              items: [
                _buildListTile(
                  icon: Icons.book_outlined,
                  title: 'Library Saya',
                  subtitle: 'Komik yang disimpan',
                  onTap: () {
                    _checkAuthBeforeAction(() {
                      // [UPDATE] Navigasi ke Library
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const LibraryPage()));
                    });
                  },
                ),
                _buildListTile(
                  icon: Icons.history,
                  title: 'Riwayat Bacaan',
                  onTap: () {
                    _checkAuthBeforeAction(() {
                      // [UPDATE] Navigasi ke History
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const HistoryPage()));
                    });
                  },
                ),
              ],
            ),

            // 3. BAGIAN PENGATURAN (Bisa diakses siapa saja)
            _buildMenuSection(
              title: 'Pengaturan',
              items: [
                _buildSwitchTile(
                  icon: Icons.dark_mode_outlined,
                  title: 'Mode Gelap',
                  value: _isDarkMode,
                  onChanged: (value) {
                    setState(() { _isDarkMode = value; });
                    themeNotifier.value = value ? ThemeMode.dark : ThemeMode.light;
                  },
                ),
                _buildListTile(
                  icon: Icons.language,
                  title: 'Bahasa',
                  trailingText: _selectedLanguage,
                  onTap: () {},
                ),
              ],
            ),

            const SizedBox(height: 24),

            // 4. TOMBOL DINAMIS (Login vs Logout)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _isLoggedIn 
                  ? _buildLogoutButton() 
                  : _buildLoginButton(),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // Helper untuk mengecek apakah user sudah login sebelum membuka fitur khusus
  void _checkAuthBeforeAction(VoidCallback action) async {
    if (_isLoggedIn) {
      action();
    } else {
      // Tunggu hasil login
      final result = await Navigator.push(context, MaterialPageRoute(builder: (context) => const Login()));
      if (result == true) {
        _loadUserSession(); // Refresh data jika login berhasil
      }
    }
  }

  Widget _buildProfileHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      color: Theme.of(context).cardColor,
      child: Row(
        children: [
          Container(
            height: 60,
            width: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _isLoggedIn ? null : Colors.grey.withOpacity(0.3), // Abu-abu jika tamu
              gradient: _isLoggedIn 
                  ? const LinearGradient(colors: [AppColors.primary, AppColors.accentPurple])
                  : null,
              border: Border.all(color: Colors.white24, width: 2),
            ),
            child: Center(
              child: _isLoggedIn
                  ? Text(_userName.isNotEmpty ? _userName[0].toUpperCase() : 'U', style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold))
                  : const Icon(Icons.person_outline, color: AppColors.textSecondary, size: 30),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _userName, 
                  style: GoogleFonts.beVietnamPro(
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _userEmail,
                  style: GoogleFonts.beVietnamPro(color: AppColors.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
          if (_isLoggedIn)
            IconButton(
              icon: const Icon(Icons.edit_outlined, color: AppColors.primary),
              onPressed: () {},
            ),
        ],
      ),
    );
  }

  Widget _buildLoginButton() {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      icon: const Icon(Icons.login),
      label: Text('Masuk / Daftar', style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.bold)),
      onPressed: () async {
        final result = await Navigator.push(context, MaterialPageRoute(builder: (context) => const Login()));
        if (result == true) {
          _loadUserSession(); // Refresh data jika login berhasil
        }
      },
    );
  }

  Widget _buildLogoutButton() {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.redAccent.withOpacity(0.1),
        foregroundColor: Colors.redAccent,
        minimumSize: const Size(double.infinity, 50),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      icon: const Icon(Icons.logout),
      label: Text('Keluar', style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.bold)),
      onPressed: () {
        // [UPDATE] Alih-alih langsung hapus sesi, panggil Modal Dialog Konfirmasi
        _showLogoutConfirmationDialog();
      },
    );
  }

  // --- TAMBAHKAN FUNGSI BARU INI DI BAWAH _buildLogoutButton ---
  void _showLogoutConfirmationDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).cardColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            'Konfirmasi Keluar',
            style: GoogleFonts.beVietnamPro(
              fontWeight: FontWeight.bold, 
              color: Theme.of(context).textTheme.bodyLarge?.color
            ),
          ),
          content: Text(
            'Apakah Anda yakin ingin keluar dari akun ini? Sesi membaca Anda akan dihentikan.',
            style: GoogleFonts.beVietnamPro(color: AppColors.textSecondary),
          ),
          actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          actions: [
            // Tombol Batal
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Tutup dialog tanpa melakukan apa-apa
              },
              child: Text(
                'Batal', 
                style: GoogleFonts.beVietnamPro(color: AppColors.textSecondary, fontWeight: FontWeight.bold)
              ),
            ),
            // Tombol Keluar
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () async {
                Navigator.pop(context); // Tutup dialognya dulu
                
                // Lakukan proses logout
                final prefs = await SharedPreferences.getInstance();
                await prefs.clear(); // Hapus memori
                _loadUserSession();  // Refresh UI menjadi tamu
                
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Anda telah berhasil keluar.'))
                  );
                }
              },
              child: Text(
                'Ya, Keluar', 
                style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.bold)
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMenuSection({required String title, required List<Widget> items}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Text(
            title.toUpperCase(),
            style: GoogleFonts.beVietnamPro(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2),
          ),
        ),
        Container(color: Theme.of(context).cardColor, child: Column(children: items)),
      ],
    );
  }

  Widget _buildListTile({required IconData icon, required String title, String? subtitle, String? trailingText, required VoidCallback onTap}) {
    return ListTile(
      leading: Icon(icon, color: AppColors.textSecondary),
      title: Text(title, style: GoogleFonts.beVietnamPro(color: Theme.of(context).textTheme.bodyLarge?.color, fontWeight: FontWeight.w500)),
      subtitle: subtitle != null ? Text(subtitle, style: GoogleFonts.beVietnamPro(color: AppColors.textSecondary, fontSize: 12)) : null,
      trailing: trailingText != null 
          ? Row(mainAxisSize: MainAxisSize.min, children: [Text(trailingText, style: GoogleFonts.beVietnamPro(color: AppColors.textSecondary)), const SizedBox(width: 8), const Icon(Icons.chevron_right, color: AppColors.textSecondary)])
          : const Icon(Icons.chevron_right, color: AppColors.textSecondary),
      onTap: onTap,
    );
  }

  Widget _buildSwitchTile({required IconData icon, required String title, required bool value, required ValueChanged<bool> onChanged}) {
    return SwitchListTile(
      secondary: Icon(icon, color: AppColors.textSecondary),
      title: Text(title, style: GoogleFonts.beVietnamPro(color: Theme.of(context).textTheme.bodyLarge?.color, fontWeight: FontWeight.w500)),
      value: value,
      activeColor: AppColors.primary,
      onChanged: onChanged,
    );
  }
}