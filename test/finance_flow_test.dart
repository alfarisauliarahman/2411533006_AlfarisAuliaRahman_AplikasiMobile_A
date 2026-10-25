import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:praktikum5_akhir/add_transaction_screen.dart';
import 'package:praktikum5_akhir/data/app_controller.dart';
import 'package:praktikum5_akhir/data/app_database.dart';
import 'package:praktikum5_akhir/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late AppController controller;

  setUpAll(sqfliteFfiInit);

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('finance_ui_flow_');
    controller = AppController(
      AppDatabase(
        path: p.join(tempDir.path, 'finance.sqlite'),
        factory: databaseFactoryFfi,
      ),
    );
    await _runRealAsync(() async {
      await controller.initialize();
      await controller.register(
        name: 'Ayu Pengguna',
        email: 'ayu.finance@example.test',
        password: 'secure pass 123',
      );
      await controller.login(
        email: 'ayu.finance@example.test',
        password: 'secure pass 123',
      );
    });
  });

  tearDown(() async {
    controller.dispose();
    await _runRealAsync(() => controller.database.close());
    await tempDir.delete(recursive: true);
  });

  testWidgets(
    'finance actions persist valid entries, reject invalid dates, and show details',
    (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(MyApp(controller: controller));
      await tester.pumpAndSettle();
      expect(find.text('Dashboard Keuangan'), findsOneWidget);
      expect(find.text('Halo, Ayu Pengguna'), findsOneWidget);
      expect(
        find.text('No. Rekening: ${controller.currentUser!.accountNumber}'),
        findsOneWidget,
      );
      expect(find.text('Rp 0'), findsOneWidget);
      _expectNoLayoutException(tester);

      // The balance control is backed by the user's stored preference.
      await tester.tap(find.byTooltip('Sembunyikan saldo'));
      await _waitFor(tester, () => !controller.balanceVisible);
      expect(find.text('Rp *********'), findsOneWidget);
      await tester.tap(find.byTooltip('Tampilkan saldo'));
      await _waitFor(tester, () => controller.balanceVisible);
      expect(find.text('Rp 0'), findsOneWidget);

      // First prove an invalid calendar date cannot write a transaction.
      await tester.tap(find.text('Pemasukan'));
      await _waitForScreen(tester, 'Catat Pemasukan');
      expect(find.byType(AddTransactionScreen), findsOneWidget);
      await tester.enterText(_field(0), 'Gaji September');
      await tester.enterText(_field(1), '5000000');
      await tester.enterText(_field(2), '31/02/2026');
      await tester.tap(find.text('Simpan Transaksi'));
      await tester.pumpAndSettle();
      expect(find.text('Tanggal transaksi tidak valid'), findsOneWidget);
      expect(controller.transactions, isEmpty);
      _expectNoLayoutException(tester);

      // Valid income with a category from the income-specific dropdown.
      await tester.enterText(_field(2), '01/09/2026');
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Bonus').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Simpan Transaksi'));
      await _waitFor(tester, () => controller.transactions.length == 1);
      await tester.pumpAndSettle();
      expect(find.byType(AddTransactionScreen), findsNothing);
      expect(controller.balance, 5000000);
      expect(controller.transactions.single.kind, 'income');
      expect(controller.transactions.single.category, 'Bonus');
      expect(find.text('Rp 5.000.000'), findsOneWidget);
      _expectNoLayoutException(tester);

      // Expense shortcut passes the expense kind and its contextual categories.
      await tester.tap(find.text('Pengeluaran'));
      await _waitForScreen(tester, 'Catat Pengeluaran');
      await tester.enterText(_field(0), 'Makan siang');
      await tester.enterText(_field(1), '125000');
      await tester.enterText(_field(2), '02/09/2026');
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      expect(find.text('Makanan'), findsWidgets);
      await tester.tap(find.text('Transportasi').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Simpan Transaksi'));
      await _waitFor(tester, () => controller.transactions.length == 2);
      await tester.pumpAndSettle();
      expect(find.byType(AddTransactionScreen), findsNothing);
      expect(controller.balance, 4875000);
      expect(controller.transactions.first.kind, 'expense');
      expect(controller.transactions.first.category, 'Transportasi');
      expect(find.text('Rp 4.875.000'), findsOneWidget);
      expect(find.text('02/09/2026'), findsOneWidget);
      expect(find.byIcon(Icons.directions_car), findsOneWidget);
      _expectNoLayoutException(tester);

      // History opens a detail route with the real persisted transaction data.
      await tester.tap(find.text('Riwayat'));
      await tester.pumpAndSettle();
      expect(find.text('Makan siang'), findsOneWidget);
      expect(find.text('Gaji September'), findsOneWidget);
      expect(find.text('02/09/2026'), findsOneWidget);
      expect(find.text('Transportasi • 02/09/2026'), findsNothing);
      expect(find.byIcon(Icons.attach_money), findsOneWidget);
      await tester.tap(find.text('Gaji September'));
      await tester.pumpAndSettle();
      expect(find.text('Detail Transaksi'), findsOneWidget);
      expect(find.text('Bonus'), findsOneWidget);
      expect(find.text('Jenis'), findsNothing);
      expect(find.byIcon(Icons.receipt_long), findsOneWidget);
      expect(find.text('01/09/2026'), findsOneWidget);
      expect(find.text('+ Rp 5.000.000'), findsOneWidget);
      _expectNoLayoutException(tester);
    },
  );

  testWidgets(
    'long account and maximum amount remain readable without narrow-screen overflow',
    (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final longName = List.filled(8, 'Pengguna').join(' ');
      final longTitle = List.filled(120, 'X').join();
      late int maxUserId;
      await _runRealAsync(() async {
        final user = await controller.register(
          name: longName,
          email: 'long.name.finance@example.test',
          password: 'secure pass 456',
        );
        maxUserId = user.id;
        await controller.logout();
        await controller.login(
          email: 'long.name.finance@example.test',
          password: 'secure pass 456',
        );
        await controller.addTransaction(
          title: longTitle,
          amount: 9000000000000,
          kind: 'expense',
          category: 'Makanan',
          date: DateTime(2026, 9, 3),
        );
      });

      expect(controller.currentUser!.id, maxUserId);
      expect(controller.currentUser!.name, longName);
      expect(controller.balance, -9000000000000);

      await tester.pumpWidget(MyApp(controller: controller));
      await tester.pumpAndSettle();
      expect(find.text('Halo, $longName'), findsOneWidget);
      expect(find.text(longTitle), findsOneWidget);
      expect(find.text('- Rp 9.000.000.000.000'), findsWidgets);
      _expectNoLayoutException(tester);

      await tester.tap(find.text('Riwayat'));
      await tester.pumpAndSettle();
      expect(find.text(longTitle), findsOneWidget);
      expect(find.text('- Rp 9.000.000.000.000'), findsOneWidget);
      _expectNoLayoutException(tester);

      final historyContext = tester.element(find.text('Riwayat'));
      unawaited(
        Navigator.of(
          historyContext,
        ).pushNamed<void>('/detail', arguments: controller.transactions.single),
      );
      await tester.pumpAndSettle();
      expect(find.text('Detail Transaksi'), findsOneWidget);
      expect(find.text(longTitle), findsOneWidget);
      expect(find.text('Makanan'), findsOneWidget);
      expect(find.text('03/09/2026'), findsOneWidget);
      expect(find.text('- Rp 9.000.000.000.000'), findsOneWidget);
      _expectNoLayoutException(tester);
    },
  );
}

Finder _field(int index) => find.byType(TextFormField).at(index);

Future<void> _runRealAsync<T>(Future<T> Function() callback) async {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  await binding.runAsync(callback);
}

Future<void> _waitFor(WidgetTester tester, bool Function() condition) async {
  for (var attempt = 0; attempt < 40; attempt++) {
    if (condition()) return;
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 100)),
    );
    await tester.pump();
  }
  expect(
    condition(),
    isTrue,
    reason: 'Expected asynchronous operation to finish',
  );
}

Future<void> _waitForScreen(WidgetTester tester, String title) async {
  await _waitFor(tester, () => find.text(title).evaluate().isNotEmpty);
  await tester.pumpAndSettle();
  expect(find.text(title), findsOneWidget);
}

void _expectNoLayoutException(WidgetTester tester) {
  expect(tester.takeException(), isNull);
}
