import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

// 1. WIDGET UTAMA
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Expense Tracker',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const DashboardScreen(), // Halaman awal aplikasi
    );
  }
}

// 2. HALAMAN UTAMA (Scaffold) - DIPERBARUI
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Praktikum 2: Layouting'),
        backgroundColor: Colors.blue,
      ),
      // MENGGUNAKAN SingleChildScrollView agar layar bisa di-scroll
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GreetingWidget(), // Memanggil StatelessWidget Dari Modul 1
            SizedBox(height: 20.0), // Jarak Vertikal
            BalanceCardWidget(), // Memanggil StatefulWidget Dari Modul 1
            SizedBox(height: 20),
            ActionButtonsWidget(), // WIDGET BARU MODUL 2
            SizedBox(height: 20),
            RecentTransactionsWidget(), // WIDGET BARU MODUL 2
          ],
        ),
      ),
    );
  }
}

// 3. STATELESS WIDGET (Sapaan - Dari Modul 1)
class GreetingWidget extends StatelessWidget {
  const GreetingWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        // Ikon Profil
        CircleAvatar(
          radius: 24,
          backgroundColor: Colors.blueAccent,
          child: Icon(
            Icons.person,
            size: 30,
            color: Colors.white,
          ),
        ),
        SizedBox(width: 12.0),

        // Teks Sapaan
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Halo, Budi',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Selamat datang kembali!',
              style: TextStyle(
                fontSize: 20,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// 4. STATEFUL WIDGET (Kartu Saldo dengan Toggle)
class BalanceCardWidget extends StatefulWidget {
  const BalanceCardWidget({super.key});

  @override
  _BalanceCardWidgetState createState() => _BalanceCardWidgetState();
}

class _BalanceCardWidgetState extends State<BalanceCardWidget> {
  // Variabel State: Menyimpan status apakah saldo terlihat atau disensor
  bool _isBalanceVisible = true;

  // Fungsi untuk mengubah state
  void _toggleVisibility() {
    setState(() {
      _isBalanceVisible =
          !_isBalanceVisible; // Membalik nilai boolean (true <-> false)
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
      ),
      color: Colors.teal, // Warna latar belakang kartu
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Baris atau kartu: Teks "Saldo Utama" & Tombol Ikon
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Saldo Utama',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                  ),
                ),

                // Tombol Mata
                IconButton(
                  icon: Icon(
                    // Logika if-else singkat (Ternary Operator)
                    _isBalanceVisible
                        ? Icons.visibility
                        : Icons.visibility_off,
                    color: Colors.white,
                  ),
                  onPressed:
                      _toggleVisibility, // Memanggil fungsi untuk state
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Teks Nominal Saldo
            Text(
              // Lofika if-else untuk menampilkan saldo atau sendor
              _isBalanceVisible ? 'Rp 5.000.000' : 'Rp *********',
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),

            Text(
              'No. Rekening: 1234-5678-9012-345',
              style: const TextStyle(
                fontSize: 14,
                color: Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// 5. WIDGET TOMBOL AKSI (ROW) - BARU
class ActionButtonsWidget extends StatelessWidget {
  // Menggunakna Row untuk menata tombol secara horizontal
  const ActionButtonsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment:
          MainAxisAlignment.spaceEvenly, // Jarak dibagi rata
      children: [
        _buildActionButton(
          Icons.arrow_downward,
          'Pemasukan',
          Colors.green,
        ),
        _buildActionButton(
          Icons.arrow_upward,
          'Pengeluaran',
          Colors.red,
        ),
        _buildActionButton(
          Icons.swap_horiz,
          'Transfer',
          Colors.blue,
        ),
      ],
    );
  }

  // Fungsi pembantu untuk membuat desain tombol agar kode tidak berulang
  Widget _buildActionButton(
    IconData icon,
    String label,
    Color color,
  ) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12.0),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: color,
            size: 28,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

// 6. WIDGET DAFTAR TRANSAKSI (COLUM & LISTTILE) - BARU
class RecentTransactionsWidget extends StatelessWidget {
  const RecentTransactionsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Transaksi Terakhir',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 12),

        // Menggunakan Card agar daftar transaksi memiliki bayangan/bingkai
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              // Item Transaksi 1
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Colors.redAccent,
                  child: Icon(Icons.fastfood, color: Colors.white),
                ),
                title: const Text('Makan Siang'),
                subtitle: const Text(
                  '13 Sep 2026',
                ), // Tanggal statis
                trailing: const Text(
                  '- Rp 50.000',
                  style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                ),
              ),

              const Divider(height: 1), // Garis pemisah

              // Item Transaksi 2
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Colors.green,
                  child: Icon(Icons.attach_money, color: Colors.white),
                ),
                title: const Text('Gaji Bulanan'),
                subtitle: const Text('01 Sep 2026'), // Tanggal statis
                trailing: const Text(
                  '+ Rp 5.000.000',
                  style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              const Divider(height: 1),

              // Item Transaksi 3
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Colors.blueAccent,
                  child: Icon(Icons.directions_car, color: Colors.white),
                ),
                title: const Text('Isi Bensin'),
                subtitle: const Text('10 Sep 2026'), // Tanggal statis
                trailing: const Text(
                  '- Rp 150.000',
                  style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                ),
              ),

              const Divider(height: 1), // Garis pemisah

              // Item Transaksi 4
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Colors.pinkAccent,
                  child: Icon(Icons.laptop_mac, color: Colors.white),
                ),
                title: const Text('Belanja Online'),
                subtitle: const Text('12 Sep 2026'), // Tanggal statis
                trailing: const Text(
                  '- Rp 300.000',
                  style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                  ),
              ),

              const Divider(height: 1), // Garis pemisah

              // Item Transaksi 5
              ListTile(
                leading:const CircleAvatar(
                  backgroundColor: Colors.orangeAccent,
                  child: Icon(Icons.network_wifi, color: Colors.white),
                ),
                title: const Text('Tagihan Internet'),
                subtitle: const Text('15 Sep 2026'), // Tanggal statis
                trailing: const Text(
                  '- Rp 200.000',
                  style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
