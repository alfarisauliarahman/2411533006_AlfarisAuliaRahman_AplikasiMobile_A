import 'models/finance_transaction.dart';

String formatRupiah(int amount) {
  final digits = amount.abs().toString();
  final grouped = digits.replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (_) => '.',
  );
  return '${amount < 0 ? '- ' : ''}Rp $grouped';
}

String formatAmount(FinanceTransaction transaction) =>
    '${transaction.isIncome ? '+' : '-'} ${formatRupiah(transaction.amount)}';
