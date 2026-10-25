import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:praktikum5_akhir/data/app_controller.dart';
import 'package:praktikum5_akhir/data/app_database.dart';
import 'package:praktikum5_akhir/data/app_exception.dart';

void main() {
  late Directory tempDir;
  late String dbPath;

  setUpAll(() {
    sqfliteFfiInit();
  });
  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('finance_app_test_');
    dbPath = p.join(tempDir.path, 'finance.sqlite');
  });
  tearDown(() async {
    await tempDir.delete(recursive: true);
  });

  AppController controller() =>
      AppController(AppDatabase(path: dbPath, factory: databaseFactoryFfi));

  test(
    'register normalizes duplicate email and rejects an incorrect password',
    () async {
      final app = controller();
      await app.initialize();
      final user = await app.register(
        name: 'Ayu',
        email: 'Ayu.Example@Email.test',
        password: 'six!!6',
      );
      expect(user.email, 'Ayu.Example@Email.test');
      expect(
        app.currentUser,
        isNull,
        reason: 'Registration must not log in automatically.',
      );
      expect(app.transactions, isEmpty);
      await expectLater(
        app.register(
          name: 'Space',
          email: 'space@example.test',
          password: '        ',
        ),
        throwsA(isA<AppException>()),
      );

      await expectLater(
        app.register(
          name: 'Other',
          email: ' ayu.example@email.test ',
          password: 'another pass',
        ),
        throwsA(
          isA<AppException>().having(
            (e) => e.message,
            'message',
            contains('terdaftar'),
          ),
        ),
      );
      await expectLater(
        app.login(email: user.email, password: 'wrong password'),
        throwsA(isA<AppException>()),
      );
      expect(app.currentUser, isNull);
      await app.database.close();
    },
  );

  test('reopening restores account, transactions, preferences and session with user isolation', () async {
    final app = controller();
    await app.initialize();
    final first = await app.register(
      name: 'Ayu',
      email: 'ayu@example.test',
      password: 'password one',
    );
    final second = await app.register(
      name: 'Bima',
      email: 'bima@example.test',
      password: 'password two',
    );

    await app.login(email: first.email, password: 'password one');
    await app.addTransaction(
      title: 'Gaji',
      amount: 5000000,
      kind: 'income',
      category: 'Pekerjaan',
      date: DateTime(2026, 1, 1),
    );
    await app.addTransaction(
      title: 'Makan',
      amount: 125000,
      kind: 'expense',
      category: 'Makanan',
      date: DateTime(2026, 1, 2),
    );
    await app.addTransaction(
      title: 'Kirim',
      amount: 250000,
      kind: 'transfer',
      category: 'Transfer',
      date: DateTime(2026, 1, 3),
    );
    await expectLater(
      app.addTransaction(
        title: 'Too large',
        amount: 9000000000001,
        kind: 'income',
        category: 'Pekerjaan',
        date: DateTime(2026, 1, 4),
      ),
      throwsA(isA<AppException>()),
    );
    expect(app.balance, 4625000);
    expect(app.transactions.map((tx) => tx.title), ['Kirim', 'Makan', 'Gaji']);
    expect(app.transactions.every((tx) => tx.userId == first.id), isTrue);
    await app.toggleBalanceVisibility();
    expect(app.balanceVisible, isFalse);
    await app.saveValues({'basic_name': 'Ayu basic'});
    expect(app.savedValue('basic_name'), 'Ayu basic');
    expect(app.savedValue('form_email'), '');
    await app.database.close();

    final reopened = controller();
    await reopened.initialize();
    expect(reopened.currentUser?.id, first.id);
    expect(reopened.balance, 4625000);
    expect(reopened.transactions, hasLength(3));
    expect(reopened.balanceVisible, isFalse);
    expect(reopened.savedValue('basic_name'), 'Ayu basic');
    await reopened.logout();
    expect(reopened.currentUser, isNull);
    expect(reopened.transactions, isEmpty);
    expect(reopened.savedValue('basic_name'), '');
    await reopened.database.close();

    final freshLogin = controller();
    await freshLogin.initialize();
    expect(
      freshLogin.currentUser,
      isNull,
      reason: 'Logout clears the persisted session.',
    );
    await freshLogin.login(email: second.email, password: 'password two');
    expect(freshLogin.currentUser?.id, second.id);
    expect(freshLogin.transactions, isEmpty);
    expect(freshLogin.balance, 0);
    expect(freshLogin.balanceVisible, isTrue);
    expect(freshLogin.savedValue('basic_name'), '');
    await freshLogin.database.close();
  });

  test('same password uses distinct salts and accounts have numeric 16-digit numbers', () async {
    final app = controller();
    await app.initialize();
    final first = await app.register(
      name: 'Ayu',
      email: 'ayu@example.test',
      password: 'shared pass',
    );
    final second = await app.register(
      name: 'Bima',
      email: 'bima@example.test',
      password: 'shared pass',
    );
    expect(first.accountNumber, matches(RegExp(r'^\d{16}$')));
    expect(second.accountNumber, matches(RegExp(r'^\d{16}$')));
    expect(first.accountNumber, isNot(second.accountNumber));
    await app.database.close();

    final rawDatabase = await databaseFactoryFfi.openDatabase(dbPath);
    final rows = await rawDatabase.query('users');
    await rawDatabase.close();
    expect(rows, hasLength(2));
    final firstRow = rows.singleWhere((row) => row['email'] == first.email);
    final secondRow = rows.singleWhere((row) => row['email'] == second.email);
    expect(firstRow['password_salt'], isNot(secondRow['password_salt']));
    expect(firstRow['password_hash'], isNot(secondRow['password_hash']));
    expect(firstRow.values, isNot(contains('shared pass')));
    expect(secondRow.values, isNot(contains('shared pass')));
  });
}
