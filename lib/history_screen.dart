import 'package:flutter/material.dart';

import 'app_scope.dart';
import 'date_input.dart';
import 'formatters.dart';
import 'models/finance_transaction.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final transactions = AppScope.of(context).transactions.toList()
      ..sort((a, b) {
        final byDate = b.date.compareTo(a.date);
        return byDate != 0 ? byDate : b.createdAt.compareTo(a.createdAt);
      });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat Transaksi'),
        backgroundColor: Colors.amber,
      ),
      body: transactions.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.history, size: 52, color: Colors.grey),
                    SizedBox(height: 12),
                    Text(
                      'Belum ada transaksi',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Transaksi yang Anda catat akan muncul di halaman ini.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  child: Column(
                    children: [
                      for (var i = 0; i < transactions.length; i++) ...[
                        if (i > 0) const Divider(height: 1),
                        _HistoryTile(transaction: transactions[i]),
                      ],
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({required this.transaction});

  final FinanceTransaction transaction;

  @override
  Widget build(BuildContext context) {
    final style = _categoryStyle(transaction);
    final tx = transaction;
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: style.color,
        child: Icon(style.icon, color: Colors.white),
      ),
      title: Text(tx.title),
      subtitle: Text(formatTransactionDate(tx.date)),
      trailing: Text(
        formatAmount(tx),
        style: TextStyle(
          color: tx.isIncome ? Colors.green : Colors.red,
          fontWeight: FontWeight.bold,
        ),
      ),
      onTap: () => Navigator.pushNamed(context, '/detail', arguments: tx),
    );
  }
}

class _CategoryStyle {
  const _CategoryStyle(this.icon, this.color);

  final IconData icon;
  final Color color;
}

_CategoryStyle _categoryStyle(FinanceTransaction tx) {
  if (tx.isIncome) {
    return const _CategoryStyle(Icons.attach_money, Colors.green);
  }
  if (tx.kind == 'transfer') {
    return const _CategoryStyle(Icons.swap_horiz, Colors.blue);
  }

  final category = tx.category.toLowerCase();
  if (category.contains('makan')) {
    return const _CategoryStyle(Icons.fastfood, Colors.orange);
  }
  if (category.contains('transport')) {
    return const _CategoryStyle(Icons.directions_car, Colors.blueAccent);
  }
  if (category.contains('belanja')) {
    return const _CategoryStyle(Icons.laptop_mac, Colors.pinkAccent);
  }
  if (category.contains('tagihan')) {
    return const _CategoryStyle(Icons.network_wifi, Colors.orangeAccent);
  }
  if (category.contains('hiburan')) {
    return const _CategoryStyle(Icons.movie, Colors.purple);
  }
  if (category.contains('kesehatan')) {
    return const _CategoryStyle(Icons.local_hospital, Colors.redAccent);
  }
  return const _CategoryStyle(Icons.receipt_long, Colors.orange);
}
