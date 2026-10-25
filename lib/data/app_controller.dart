import 'dart:convert';
import 'dart:math';

import 'package:cryptography/cryptography.dart';
import 'package:flutter/foundation.dart';

import '../models/finance_transaction.dart';
import '../models/user_account.dart';
import 'app_database.dart';
import 'app_exception.dart';

/// Coordinates authentication and the currently signed-in user's local data.
class AppController extends ChangeNotifier {
  AppController(this.database);

  final AppDatabase database;
  static final Pbkdf2 _passwordKdf = Pbkdf2.hmacSha256(
    iterations: 120000,
    bits: 256,
  );

  UserAccount? _currentUser;
  List<FinanceTransaction> _transactions = const [];
  bool _balanceVisible = true;
  Map<String, String> _savedValues = const {};
  bool _initialized = false;
  Future<void> _balanceToggleQueue = Future<void>.value();

  UserAccount? get currentUser => _currentUser;
  List<FinanceTransaction> get transactions => _transactions;
  int get balance => _transactions.fold(0, (sum, tx) => sum + tx.signedAmount);
  bool get balanceVisible => _balanceVisible;
  String savedValue(String key) => _savedValues[key] ?? '';

  Future<void> initialize() async {
    if (_initialized) return;
    await database.open();
    _initialized = true;
    final id = await database.currentSessionUserId();
    if (id != null) {
      _currentUser = await database.userById(id);
      if (_currentUser != null) {
        _balanceVisible = await database.balanceVisibility(id);
        _transactions = await database.transactionsForUser(id);
        _savedValues = await database.valuesForUser(id);
      } else {
        await database.setSession(null);
      }
    }
    notifyListeners();
  }

  Future<UserAccount> register({
    required String name,
    required String email,
    required String password,
  }) async {
    _ensureInitialized();
    final cleanName = name.trim();
    final cleanEmail = email.trim();
    final normalizedEmail = cleanEmail.toLowerCase();
    if (cleanName.length < 2 || cleanName.length > 80) {
      throw const AppException('Nama harus terdiri dari 2 sampai 80 karakter.');
    }
    if (cleanEmail.length > 254 || !_validEmail.hasMatch(cleanEmail)) {
      throw const AppException('Masukkan alamat email yang valid.');
    }
    if (password.trim().isEmpty) {
      throw const AppException('Kata sandi tidak boleh kosong.');
    }
    if (password.length < 6 || password.length > 256) {
      throw const AppException(
        'Kata sandi harus terdiri dari 6 sampai 256 karakter.',
      );
    }
    if (await database.findUserByEmail(normalizedEmail) != null) {
      throw const AppException('Email sudah terdaftar.');
    }

    final salt = _randomBytes(16);
    final hash = await _derive(password, salt);
    try {
      return await database.createUser(
        name: cleanName,
        email: cleanEmail,
        normalizedEmail: normalizedEmail,
        salt: base64UrlEncode(salt),
        passwordHash: base64UrlEncode(hash),
      );
    } on AppException {
      rethrow;
    } catch (error) {
      // The unique index also closes the race between concurrent registrations.
      if (error.toString().toLowerCase().contains('unique')) {
        throw const AppException('Email sudah terdaftar.');
      }
      rethrow;
    }
  }

  Future<void> login({required String email, required String password}) async {
    _ensureInitialized();
    final normalizedEmail = email.trim().toLowerCase();
    if (!_validEmail.hasMatch(normalizedEmail) || password.trim().isEmpty) {
      throw const AppException('Email atau kata sandi salah.');
    }
    final credentials = await database.credentialsForEmail(normalizedEmail);
    if (credentials == null) {
      throw const AppException('Email atau kata sandi salah.');
    }

    final salt = base64Url.decode(credentials['password_salt'] as String);
    final expected = base64Url.decode(credentials['password_hash'] as String);
    final actual = await _derive(password, salt);
    if (!_constantTimeEquals(actual, expected)) {
      throw const AppException('Email atau kata sandi salah.');
    }

    final user = await database.userById(credentials['id'] as int);
    if (user == null) {
      throw const AppException('Email atau kata sandi salah.');
    }
    await database.setSession(user.id);
    _currentUser = user;
    _transactions = await database.transactionsForUser(user.id);
    _balanceVisible = await database.balanceVisibility(user.id);
    _savedValues = await database.valuesForUser(user.id);
    notifyListeners();
  }

  Future<void> logout() async {
    _ensureInitialized();
    await database.setSession(null);
    _currentUser = null;
    _transactions = const [];
    _balanceVisible = true;
    _savedValues = const {};
    notifyListeners();
  }

  Future<void> addTransaction({
    required String title,
    required int amount,
    required String kind,
    required String category,
    required DateTime date,
  }) async {
    _ensureInitialized();
    final user = _currentUser;
    if (user == null) {
      throw const AppException('Silakan masuk terlebih dahulu.');
    }
    final cleanTitle = title.trim();
    final cleanCategory = category.trim();
    if (cleanTitle.isEmpty || cleanTitle.length > 120) {
      throw const AppException(
        'Judul transaksi harus diisi (maksimal 120 karakter).',
      );
    }
    if (amount <= 0 || amount > 9000000000000) {
      throw const AppException(
        'Jumlah transaksi harus antara Rp1 dan Rp9.000.000.000.000.',
      );
    }
    if (!const {'income', 'expense', 'transfer'}.contains(kind)) {
      throw const AppException('Jenis transaksi tidak valid.');
    }
    if (cleanCategory.isEmpty || cleanCategory.length > 80) {
      throw const AppException('Kategori transaksi harus diisi.');
    }
    final tx = await database.addTransaction(
      userId: user.id,
      title: cleanTitle,
      amount: amount,
      kind: kind,
      category: cleanCategory,
      date: date,
    );
    if (_currentUser?.id != user.id) return;
    _transactions = [tx, ..._transactions]..sort(_compareTransactions);
    notifyListeners();
  }

  Future<void> toggleBalanceVisibility() {
    final operation = _balanceToggleQueue.then(
      (_) => _toggleBalanceVisibility(),
    );
    _balanceToggleQueue = operation.then<void>(
      (_) {},
      onError: (Object _, StackTrace _) {},
    );
    return operation;
  }

  Future<void> _toggleBalanceVisibility() async {
    _ensureInitialized();
    final user = _currentUser;
    if (user == null) {
      throw const AppException('Silakan masuk terlebih dahulu.');
    }
    final next = !_balanceVisible;
    await database.setBalanceVisibility(user.id, next);
    if (_currentUser?.id != user.id) return;
    _balanceVisible = next;
    notifyListeners();
  }

  Future<void> saveValues(Map<String, String> values) async {
    _ensureInitialized();
    final user = _currentUser;
    if (user == null) {
      throw const AppException('Silakan masuk terlebih dahulu.');
    }
    for (final entry in values.entries) {
      if (entry.key.trim().isEmpty || entry.key.length > 100) {
        throw const AppException('Kunci data tidak valid.');
      }
      if (entry.value.length > 10000) {
        throw const AppException('Nilai data terlalu panjang.');
      }
    }
    if (values.isEmpty) return;
    await database.saveValues(user.id, values);
    if (_currentUser?.id != user.id) return;
    _savedValues = {..._savedValues, ...values};
    notifyListeners();
  }

  Future<void> reload() async {
    _ensureInitialized();
    final id = await database.currentSessionUserId();
    final user = id == null ? null : await database.userById(id);
    _currentUser = user;
    if (user == null) {
      _transactions = const [];
      _balanceVisible = true;
      _savedValues = const {};
    } else {
      _transactions = await database.transactionsForUser(user.id);
      _balanceVisible = await database.balanceVisibility(user.id);
      _savedValues = await database.valuesForUser(user.id);
    }
    notifyListeners();
  }

  void _ensureInitialized() {
    if (!_initialized) {
      throw StateError('AppController.initialize() must be called first');
    }
  }

  static final RegExp _validEmail = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

  static List<int> _randomBytes(int length) {
    final random = Random.secure();
    return List<int>.generate(length, (_) => random.nextInt(256));
  }

  static Future<List<int>> _derive(String password, List<int> salt) async {
    final result = await _passwordKdf.deriveKey(
      secretKey: SecretKey(utf8.encode(password)),
      nonce: salt,
    );
    return result.extractBytes();
  }

  static bool _constantTimeEquals(List<int> a, List<int> b) {
    var diff = a.length ^ b.length;
    final length = min(a.length, b.length);
    for (var i = 0; i < length; i++) {
      diff |= a[i] ^ b[i];
    }
    return diff == 0;
  }

  static int _compareTransactions(FinanceTransaction a, FinanceTransaction b) {
    final byDate = b.date.compareTo(a.date);
    return byDate != 0 ? byDate : b.id.compareTo(a.id);
  }
}
