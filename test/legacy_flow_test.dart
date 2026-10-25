import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:praktikum5_akhir/data/app_controller.dart';
import 'package:praktikum5_akhir/data/app_database.dart';
import 'package:praktikum5_akhir/date_input.dart';
import 'package:praktikum5_akhir/main.dart';

void main() {
  late Directory directory;
  late AppController controller;
  setUpAll(sqfliteFfiInit);
  setUp(() async {
    directory = await Directory.systemTemp.createTemp('legacy_features_');
    controller = AppController(
      AppDatabase(
        path: p.join(directory.path, 'app.db'),
        factory: databaseFactoryFfi,
      ),
    );
    await controller.initialize();
    await controller.register(
      name: 'Alfaris',
      email: 'alfaris@example.test',
      password: 'password123',
    );
    await controller.login(
      email: 'alfaris@example.test',
      password: 'password123',
    );
  });
  tearDown(() async {
    await controller.database.close();
    controller.dispose();
    await directory.delete(recursive: true);
  });

  testWidgets('latihan lama tetap dapat dibuka dan hasilnya dipulihkan', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MyApp(controller: controller));
    await tester.pumpAndSettle();

    await openExercise(tester, 'Basic TextField');
    await tester.enterText(find.byType(TextField), 'Alfaris Praktikum');
    await tester.tap(find.text('Tampilkan Nama'));
    await waitFor(
      tester,
      () => controller.savedValue('basic_name') == 'Alfaris Praktikum',
    );
    await tester.pageBack();
    await tester.pumpAndSettle();
    await openExercise(tester, 'Basic TextField');
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      'Alfaris Praktikum',
    );
    await tester.pageBack();
    await tester.pumpAndSettle();

    await openExercise(tester, 'Basic Form');
    await tester.enterText(find.byType(TextFormField).at(0), 'Alfaris Form');
    await tester.enterText(
      find.byType(TextFormField).at(1),
      'form@example.test',
    );
    await tester.tap(find.text('Submit'));
    await waitFor(
      tester,
      () => controller.savedValue('form_email') == 'form@example.test',
    );
    await tester.pageBack();
    await tester.pumpAndSettle();

    await openExercise(tester, 'Kalkulator');
    await tester.enterText(find.byType(TextField).at(0), '12');
    await tester.enterText(find.byType(TextField).at(1), '3');
    await tester.tap(find.text('×'));
    await waitFor(
      tester,
      () => controller.savedValue('calculator_result').contains('= 36'),
    );
    expect(find.text('12.0 × 3.0 = 36'), findsOneWidget);
    await tester.enterText(find.byType(TextField).at(1), '0');
    await tester.tap(find.text('÷'));
    await tester.pumpAndSettle();
    expect(
      find.text('Pembagian dengan nol tidak dapat dilakukan.'),
      findsOneWidget,
    );
    expect(controller.savedValue('calculator_result'), contains('= 36'));
    await tester.pageBack();
    await tester.pumpAndSettle();
    await openExercise(tester, 'Kalkulator');
    expect(
      tester.widget<TextField>(find.byType(TextField).at(0)).controller!.text,
      '12',
    );
    expect(
      tester.widget<TextField>(find.byType(TextField).at(1)).controller!.text,
      '3',
    );
    expect(find.text('12.0 × 3.0 = 36'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test('validasi kalender membedakan tanggal sah dan tidak sah', () {
    expect(parseTransactionDate('29/02/2024'), DateTime(2024, 2, 29));
    expect(parseTransactionDate('29/02/2025'), isNull);
    expect(parseTransactionDate('31/04/2026'), isNull);
    expect(parseTransactionDate('25/10/2026'), DateTime(2026, 10, 25));
    expect(parseTransactionDate('25/10/26'), isNull);
  });
}

Future<void> openExercise(WidgetTester tester, String name) async {
  await tester.tap(find.byTooltip('Latihan lainnya'));
  await tester.pumpAndSettle();
  await tester.tap(find.text(name).last);
  await tester.pumpAndSettle();
}

Future<void> waitFor(WidgetTester tester, bool Function() ready) async {
  for (var i = 0; i < 60; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 60)),
    );
    await tester.pump();
    if (ready()) {
      await tester.pumpAndSettle();
      return;
    }
  }
  fail('Operasi penyimpanan tidak selesai');
}
