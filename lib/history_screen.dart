import 'package:flutter/material.dart';

import 'transaction_detail_screen.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat Transaksi'),
        backgroundColor: Colors.amber,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Colors.orange,
                    child: Icon(Icons.fastfood, color: Colors.white),
                  ),
                  title: const Text('Makan Siang'),
                  subtitle: const Text('13 September 2026'),
                  trailing: const Text(
                    '- Rp 50.000',
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const TransactionDetailScreen(
                          title: 'Makan Siang',
                          amount: '- Rp 50.000',
                          category: 'Makanan',
                          date: '13 September 2026',
                        ),
                      ),
                    );
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Colors.green,
                    child: Icon(Icons.attach_money, color: Colors.white),
                  ),
                  title: const Text('Gaji Bulanan'),
                  subtitle: const Text('1 September 2026'),
                  trailing: const Text(
                    '+ Rp 5.000.000',
                    style: TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const TransactionDetailScreen(
                          title: 'Gaji Bulanan',
                          amount: '+ Rp 5.000.000',
                          category: 'Pemasukan',
                          date: '1 September 2026',
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
