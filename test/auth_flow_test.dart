import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:praktikum5_akhir/data/app_controller.dart';
import 'package:praktikum5_akhir/data/app_database.dart';
import 'package:praktikum5_akhir/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late AppController controller;

  setUpAll(sqfliteFfiInit);

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('finance_auth_flow_');
    final database = AppDatabase(
      path: p.join(tempDir.path, 'auth.sqlite'),
      factory: databaseFactoryFfi,
    );
    controller = AppController(database);
    await _runRealAsync(() => controller.initialize());
    await _runRealAsync(() async {
      await controller.register(
        name: 'Existing User',
        email: 'existing@example.test',
        password: 'seed password',
      );
    });
  });

  tearDown(() async {
    await _runRealAsync(() => controller.database.close());
    controller.dispose();
    await tempDir.delete(recursive: true);
  });

  testWidgets('register, authenticate, view profile, and log out', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MyApp(controller: controller));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Daftar').last);
    await tester.pumpAndSettle();
    expect(find.text('Buat Akun Baru'), findsOneWidget);

    await tester.enterText(_field(0), 'Dewi Pengguna');
    await tester.enterText(_field(1), 'existing@example.test');
    await tester.enterText(_field(2), 'secure pass 123');
    await tester.enterText(_field(3), 'different pass 123');
    await _invokeAsyncButton(
      tester,
      find.widgetWithText(FilledButton, 'Daftar'),
    );
    expect(find.text('Kata sandi belum cocok'), findsOneWidget);

    await tester.enterText(_field(3), 'secure pass 123');
    await _invokeAsyncButton(
      tester,
      find.widgetWithText(FilledButton, 'Daftar'),
    );
    await _pumpUntil(tester, find.text('Email sudah terdaftar.'));

    await tester.enterText(_field(1), 'dewi@example.test');
    await _invokeAsyncButton(
      tester,
      find.widgetWithText(FilledButton, 'Daftar'),
    );
    await _pumpUntil(tester, find.widgetWithText(FilledButton, 'Masuk'));
    expect(_field(0), findsOneWidget);
    expect(
      tester.widget<TextFormField>(_field(0)).controller!.text,
      'dewi@example.test',
    );
    await tester.pump(const Duration(seconds: 5));

    await tester.enterText(_field(1), 'wrong pass 123');
    await _invokeAsyncButton(
      tester,
      find.widgetWithText(FilledButton, 'Masuk'),
    );
    await _pumpUntil(tester, find.text('Email atau kata sandi salah.'));
    expect(find.text('Selamat Datang'), findsOneWidget);
    await tester.pump(const Duration(seconds: 5));

    await tester.enterText(_field(1), 'secure pass 123');
    await _invokeAsyncButton(
      tester,
      find.widgetWithText(FilledButton, 'Masuk'),
    );
    await _pumpUntil(tester, find.text('Dashboard Keuangan'));
    expect(find.text('Halo, Dewi Pengguna'), findsOneWidget);

    tester.widget<BottomNavigationBar>(find.byType(BottomNavigationBar)).onTap!(
      2,
    );
    await tester.pumpAndSettle();
    expect(find.text('Dewi Pengguna'), findsOneWidget);
    expect(find.text('dewi@example.test'), findsOneWidget);

    await _invokeAsyncButton(
      tester,
      find.widgetWithText(ElevatedButton, 'Logout'),
    );
    await _pumpUntil(tester, find.text('Selamat Datang'));
    expect(find.text('Dashboard Keuangan'), findsNothing);
  });
}

Finder _field(int index) => find.byType(TextFormField).at(index);

Future<void> _tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
}

Future<void> _invokeAsyncButton(WidgetTester tester, Finder finder) async {
  await _tapVisible(tester, finder);
  await tester.pump();
}

Future<void> _runRealAsync(Future<void> Function() callback) async {
  // SQLite FFI and PBKDF2 use real asynchronous work that does not advance
  // while a widget test is inside its fake-async zone.
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  await binding.runAsync(callback);
}

Future<void> _pumpUntil(WidgetTester tester, Finder finder) async {
  for (var attempt = 0; attempt < 180; attempt++) {
    await tester.pump(const Duration(milliseconds: 20));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 10)),
    );
    if (finder.evaluate().isNotEmpty) return;
  }
  expect(finder, findsOneWidget);
}
