import 'dart:math';

import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart' as sqflite;
import 'package:sqflite/sqlite_api.dart';

import '../models/finance_transaction.dart';
import '../models/user_account.dart';

/// SQLite storage. Supply [path] and [factory] to use a deterministic test DB.
class AppDatabase {
  AppDatabase({String? path, DatabaseFactory? factory})
    // The public argument stays named `path`; the backing field is private.
    : _path = path, // ignore: prefer_initializing_formals
      _factory = factory ?? sqflite.databaseFactory;

  final String? _path;
  final DatabaseFactory _factory;
  Database? _db;

  static Future<void> _createUserValuesTable(DatabaseExecutor db) =>
      db.execute('''
        CREATE TABLE user_values (
          user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
          key TEXT NOT NULL,
          value TEXT NOT NULL,
          PRIMARY KEY(user_id, key)
        )
      ''');

  Future<void> open() async {
    if (_db != null) return;
    final dbPath =
        _path ?? p.join(await _factory.getDatabasesPath(), 'finance_app.db');
    _db = await _factory.openDatabase(
      dbPath,
      options: OpenDatabaseOptions(
        version: 2,
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE users (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              name TEXT NOT NULL,
              email TEXT NOT NULL,
              email_normalized TEXT NOT NULL UNIQUE,
              password_salt TEXT NOT NULL,
              password_hash TEXT NOT NULL,
              account_number TEXT NOT NULL UNIQUE,
              created_at INTEGER NOT NULL
            )
          ''');
          await db.execute('''
            CREATE TABLE transactions (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
              title TEXT NOT NULL,
              amount INTEGER NOT NULL CHECK(amount > 0),
              kind TEXT NOT NULL CHECK(kind IN ('income', 'expense', 'transfer')),
              category TEXT NOT NULL,
              date INTEGER NOT NULL,
              created_at INTEGER NOT NULL
            )
          ''');
          await db.execute(
            'CREATE INDEX transactions_user_date ON transactions(user_id, date DESC, id DESC)',
          );
          await db.execute('''
            CREATE TABLE app_state (
              id INTEGER PRIMARY KEY CHECK(id = 1),
              current_user_id INTEGER NULL REFERENCES users(id) ON DELETE SET NULL
            )
          ''');
          await db.insert('app_state', {'id': 1, 'current_user_id': null});
          await db.execute('''
            CREATE TABLE user_preferences (
              user_id INTEGER PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
              balance_visible INTEGER NOT NULL DEFAULT 1 CHECK(balance_visible IN (0, 1))
            )
          ''');
          await _createUserValuesTable(db);
        },
        onUpgrade: (db, oldVersion, newVersion) async {
          if (oldVersion < 2) await _createUserValuesTable(db);
        },
        onConfigure: (db) async => db.execute('PRAGMA foreign_keys = ON'),
      ),
    );
  }

  Database get _database {
    final db = _db;
    if (db == null) throw StateError('AppDatabase.open() must be called first');
    return db;
  }

  Future<void> close() async {
    final db = _db;
    _db = null;
    if (db != null) await db.close();
  }

  Future<UserAccount?> findUserByEmail(String normalizedEmail) async {
    final rows = await _database.query(
      'users',
      where: 'email_normalized = ?',
      whereArgs: [normalizedEmail],
      limit: 1,
    );
    return rows.isEmpty ? null : UserAccount.fromMap(rows.single);
  }

  Future<Map<String, Object?>?> credentialsForEmail(
    String normalizedEmail,
  ) async {
    final rows = await _database.query(
      'users',
      columns: ['id', 'password_salt', 'password_hash'],
      where: 'email_normalized = ?',
      whereArgs: [normalizedEmail],
      limit: 1,
    );
    return rows.isEmpty ? null : rows.single;
  }

  Future<UserAccount?> userById(int id) async {
    final rows = await _database.query(
      'users',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return rows.isEmpty ? null : UserAccount.fromMap(rows.single);
  }

  Future<UserAccount> createUser({
    required String name,
    required String email,
    required String normalizedEmail,
    required String salt,
    required String passwordHash,
  }) async {
    final accountNumber = await _newAccountNumber();
    final id = await _database.transaction((txn) async {
      final userId = await txn.insert('users', {
        'name': name,
        'email': email,
        'email_normalized': normalizedEmail,
        'password_salt': salt,
        'password_hash': passwordHash,
        'account_number': accountNumber,
        'created_at': DateTime.now().millisecondsSinceEpoch,
      });
      await txn.insert('user_preferences', {
        'user_id': userId,
        'balance_visible': 1,
      });
      return userId;
    });
    return (await userById(id))!;
  }

  Future<String> _newAccountNumber() async {
    final random = Random.secure();
    for (var attempt = 0; attempt < 8; attempt++) {
      final number =
          '${random.nextInt(9) + 1}${List<int>.generate(15, (_) => random.nextInt(10)).join()}';
      final found = await _database.query(
        'users',
        columns: ['id'],
        where: 'account_number = ?',
        whereArgs: [number],
        limit: 1,
      );
      if (found.isEmpty) return number;
    }
    // Collision probability is negligible; fail safely instead of reusing a number.
    throw StateError('Unable to generate a unique account number');
  }

  Future<void> setSession(int? userId) async {
    await _database.update('app_state', {
      'current_user_id': userId,
    }, where: 'id = 1');
  }

  Future<int?> currentSessionUserId() async {
    final rows = await _database.query(
      'app_state',
      columns: ['current_user_id'],
      where: 'id = 1',
      limit: 1,
    );
    final value = rows.firstOrNull?['current_user_id'];
    return value as int?;
  }

  Future<bool> balanceVisibility(int userId) async {
    final rows = await _database.query(
      'user_preferences',
      columns: ['balance_visible'],
      where: 'user_id = ?',
      whereArgs: [userId],
      limit: 1,
    );
    return rows.isEmpty || rows.single['balance_visible'] == 1;
  }

  Future<void> setBalanceVisibility(int userId, bool visible) async {
    await _database.update(
      'user_preferences',
      {'balance_visible': visible ? 1 : 0},
      where: 'user_id = ?',
      whereArgs: [userId],
    );
  }

  Future<Map<String, String>> valuesForUser(int userId) async {
    final rows = await _database.query(
      'user_values',
      columns: ['key', 'value'],
      where: 'user_id = ?',
      whereArgs: [userId],
    );
    return {
      for (final row in rows) row['key'] as String: row['value'] as String,
    };
  }

  Future<void> saveValues(int userId, Map<String, String> values) async {
    await _database.transaction((txn) async {
      for (final entry in values.entries) {
        await txn.insert('user_values', {
          'user_id': userId,
          'key': entry.key,
          'value': entry.value,
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }
    });
  }

  Future<FinanceTransaction> addTransaction({
    required int userId,
    required String title,
    required int amount,
    required String kind,
    required String category,
    required DateTime date,
  }) async {
    final now = DateTime.now();
    final id = await _database.insert('transactions', {
      'user_id': userId,
      'title': title,
      'amount': amount,
      'kind': kind,
      'category': category,
      'date': date.millisecondsSinceEpoch,
      'created_at': now.millisecondsSinceEpoch,
    });
    return FinanceTransaction(
      id: id,
      userId: userId,
      title: title,
      amount: amount,
      kind: kind,
      category: category,
      date: date,
      createdAt: now,
    );
  }

  Future<List<FinanceTransaction>> transactionsForUser(int userId) async {
    final rows = await _database.query(
      'transactions',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'date DESC, id DESC',
    );
    return rows.map(FinanceTransaction.fromMap).toList(growable: false);
  }
}

extension<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
