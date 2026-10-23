import 'package:flutter/material.dart';

import 'dashboard_screen.dart'; // Dari modul sebelumnya
import 'profile_screen.dart'; // Akan dibuat sebagai tugas akhir mahasiswa
import 'history_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});
  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0; // Tab pertama aktif secara default (Beranda)

  // List kumpulan halaman
  final List<Widget> _pages = [
    const DashboardScreen(),
    const HistoryScreen(),
    const ProfileScreen(), // Tantangan UI profil untuk mahasiswa
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex], // Ganti layar sesuai index
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.amber[800],
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Beranda'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'Riwayat'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
        ],
      ),
    );
  }
}
