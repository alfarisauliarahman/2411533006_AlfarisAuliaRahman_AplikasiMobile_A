import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import 'package:praktikum5_akhir/data/app_controller.dart';
import 'package:praktikum5_akhir/data/app_database.dart';
import 'package:praktikum5_akhir/data/app_exception.dart';
import 'package:praktikum5_akhir/main.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'SQLite native bertahan setelah koneksi dan aplikasi dibuat ulang',
    (tester) async {
      final path = p.join(
        await getDatabasesPath(),
        'native_verification_only.db',
      );
      await deleteDatabase(path);
      var controller = AppController(AppDatabase(path: path));
      await controller.initialize();
      await controller.register(
        name: 'Pengujian Lokal',
        email: 'lokal@example.test',
        password: 'password123',
      );
      await controller.login(
        email: 'lokal@example.test',
        password: 'password123',
      );
      await controller.addTransaction(
        title: 'Gaji pengujian',
        amount: 5000000,
        kind: 'income',
        category: 'Gaji',
        date: DateTime(2026, 10, 25),
      );
      await controller.addTransaction(
        title: 'Makan pengujian',
        amount: 50000,
        kind: 'expense',
        category: 'Makanan',
        date: DateTime(2026, 10, 25),
      );
      await controller.saveValues({
        'calculator_first': '12',
        'calculator_second': '3',
        'calculator_result': '12.0 × 3.0 = 36',
        'basic_name': 'Nama tersimpan',
      });
      await tester.pumpWidget(MyApp(controller: controller));
      await tester.pumpAndSettle();
      expect(find.text('Dashboard Keuangan'), findsOneWidget);
      expect(find.text('Rp 4.950.000'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      controller.dispose();
      await controller.database.close();

      controller = AppController(AppDatabase(path: path));
      await controller.initialize();
      expect(controller.currentUser?.email, 'lokal@example.test');
      expect(controller.transactions, hasLength(2));
      expect(controller.balance, 4950000);
      expect(controller.savedValue('basic_name'), 'Nama tersimpan');
      await tester.pumpWidget(MyApp(controller: controller));
      await tester.pumpAndSettle();
      expect(find.text('Rp 4.950.000'), findsOneWidget);
      await tester.tap(find.text('Riwayat'));
      await tester.pumpAndSettle();
      expect(find.text('Makan pengujian'), findsOneWidget);
      await tester.tap(find.text('Makan pengujian'));
      await tester.pumpAndSettle();
      expect(find.text('Detail Transaksi'), findsOneWidget);
      expect(find.text('- Rp 50.000'), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();
      await controller.logout();
      await expectLater(
        controller.login(email: 'lokal@example.test', password: 'salah123'),
        throwsA(isA<AppException>()),
      );
      await controller.login(
        email: 'lokal@example.test',
        password: 'password123',
      );
      expect(controller.transactions, hasLength(2));
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      controller.dispose();
      await controller.database.close();
      await deleteDatabase(path);
    },
  );
}
