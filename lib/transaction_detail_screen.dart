import 'package:flutter/material.dart';

class TransactionDetailScreen extends StatelessWidget{
  // Deklarasi variabel penampung data (harus final karena StatelessWidget)
  final String title;
  final String amount;
  final String category;
  final String date;

  // Constructor yang mewajibkan pengisian data (required)
  const TransactionDetailScreen({
    super.key,
    required this.title,
    required this.amount,
    required this.category,
    required this.date,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:const Text("Detail Transaksi"),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsetsGeometry.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Icon(Icons.receipt_long, size: 80, color: Colors.redAccent),
            const SizedBox(height: 24),
            Text(title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(amount,style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.red)),
            const Divider(height: 40, thickness: 2),
            _buildDetailRow('Kategori', category),
            const SizedBox(height: 16),
            _buildDetailRow('Tanggal', date),
            const SizedBox(height: 16),
            _buildDetailRow('Status', 'Berhasil'),
          ],
        ),
      ),
    );
  }

  // Widger pembantu untuk merapikan layout baris detail
  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 16, color: Colors.grey)),
        Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
