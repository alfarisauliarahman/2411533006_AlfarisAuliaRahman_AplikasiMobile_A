/// A financial entry stored for a single account.
class FinanceTransaction {
  const FinanceTransaction({
    required this.id,
    required this.userId,
    required this.title,
    required this.amount,
    required this.kind,
    required this.category,
    required this.date,
    required this.createdAt,
  });

  final int id;
  final int userId;
  final String title;

  /// Positive integer rupiah amount. Direction is represented by [kind].
  final int amount;
  final String kind;
  final String category;
  final DateTime date;
  final DateTime createdAt;

  int get signedAmount => kind == 'income' ? amount : -amount;
  bool get isIncome => kind == 'income';

  factory FinanceTransaction.fromMap(Map<String, Object?> map) =>
      FinanceTransaction(
        id: map['id'] as int,
        userId: map['user_id'] as int,
        title: map['title'] as String,
        amount: map['amount'] as int,
        kind: map['kind'] as String,
        category: map['category'] as String,
        date: DateTime.fromMillisecondsSinceEpoch(map['date'] as int),
        createdAt: DateTime.fromMillisecondsSinceEpoch(
          map['created_at'] as int,
        ),
      );
}
