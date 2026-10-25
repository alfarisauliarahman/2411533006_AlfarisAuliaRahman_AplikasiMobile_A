import 'package:flutter/material.dart';

import 'app_scope.dart';
import 'data/app_controller.dart';
import 'date_input.dart';
import 'formatters.dart';
import 'models/finance_transaction.dart';
import 'models/user_account.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    final user = controller.currentUser;
    final transactions = controller.transactions.toList()
      ..sort((a, b) {
        final byDate = b.date.compareTo(a.date);
        return byDate != 0 ? byDate : b.createdAt.compareTo(a.createdAt);
      });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard Keuangan'),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
        actions: [
          PopupMenuButton<String>(
            tooltip: 'Latihan lainnya',
            onSelected: (route) => Navigator.pushNamed(context, route),
            itemBuilder: (context) => const [
              PopupMenuItem(value: '/calculator', child: Text('Kalkulator')),
              PopupMenuItem(
                value: '/basic-textfield',
                child: Text('Basic TextField'),
              ),
              PopupMenuItem(value: '/basic-form', child: Text('Basic Form')),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.amber,
        foregroundColor: Colors.black87,
        tooltip: 'Tambah pengeluaran',
        onPressed: () =>
            Navigator.pushNamed(context, '/add', arguments: 'expense'),
        child: const Icon(Icons.add),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              user == null ? 'Halo' : 'Halo, ${user.name}',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (user != null) Text(user.email),
            const SizedBox(height: 20),
            _buildBalanceCard(context, controller, user),
            const SizedBox(height: 20),
            const _ActionButtons(),
            const SizedBox(height: 20),
            const Text(
              'Transaksi Terakhir',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildTransactionList(context, transactions),
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceCard(
    BuildContext context,
    AppController controller,
    UserAccount? user,
  ) {
    final visible = controller.balanceVisible;
    return Card(
      elevation: 4,
      color: Colors.redAccent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Saldo Utama',
                  style: TextStyle(fontSize: 16, color: Colors.white70),
                ),
                IconButton(
                  tooltip: visible ? 'Sembunyikan saldo' : 'Tampilkan saldo',
                  icon: Icon(
                    visible ? Icons.visibility : Icons.visibility_off,
                    color: Colors.white,
                  ),
                  onPressed: () async {
                    try {
                      await controller.toggleBalanceVisibility();
                    } catch (_) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Pengaturan saldo gagal disimpan.'),
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              visible ? formatRupiah(controller.balance) : 'Rp *********',
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            if (user != null)
              Text(
                'No. Rekening: ${user.accountNumber}',
                style: const TextStyle(fontSize: 14, color: Colors.white70),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionList(
    BuildContext context,
    List<FinanceTransaction> transactions,
  ) {
    final latest = transactions.take(5).toList();
    if (latest.isEmpty) {
      return Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Column(
              children: const [
                Icon(Icons.receipt_long, size: 38, color: Colors.grey),
                SizedBox(height: 8),
                Text('Belum ada transaksi'),
                SizedBox(height: 4),
                Text(
                  'Transaksi yang Anda catat akan tampil di sini.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      );
    }
    return Card(
      elevation: 2,
      child: Column(
        children: [
          for (var i = 0; i < latest.length; i++) ...[
            if (i > 0) const Divider(height: 1),
            _transactionTile(context, latest[i]),
          ],
        ],
      ),
    );
  }

  Widget _transactionTile(BuildContext context, FinanceTransaction tx) {
    final style = _categoryStyle(tx);
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: style.color,
        child: Icon(style.icon, color: Colors.white),
      ),
      title: Text(tx.title),
      subtitle: Text(_transactionDateLabel(tx.date)),
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

  String _transactionDateLabel(DateTime date) =>
      DateUtils.isSameDay(date, DateTime.now())
      ? 'Hari ini'
      : formatTransactionDate(date);
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

class _ActionButtons extends StatelessWidget {
  const _ActionButtons();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Wrap(
        alignment: WrapAlignment.spaceEvenly,
        runSpacing: 8,
        children: [
          _ActionButton(
            icon: Icons.arrow_downward,
            label: 'Pemasukan',
            color: Colors.green,
            kind: 'income',
          ),
          _ActionButton(
            icon: Icons.arrow_upward,
            label: 'Pengeluaran',
            color: Colors.red,
            kind: 'expense',
          ),
          _ActionButton(
            icon: Icons.swap_horiz,
            label: 'Transfer',
            color: Colors.blue,
            kind: 'transfer',
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.kind,
  });

  final IconData icon;
  final String label;
  final Color color;
  final String kind;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => Navigator.pushNamed(context, '/add', arguments: kind),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}
