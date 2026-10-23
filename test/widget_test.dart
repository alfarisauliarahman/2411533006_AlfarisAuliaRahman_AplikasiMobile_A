import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:praktikum_6/main.dart';

Future<void> login(WidgetTester tester, String email) async {
  await tester.enterText(find.widgetWithText(TextFormField, 'Email'), email);
  await tester.enterText(
    find.widgetWithText(TextFormField, 'Password'),
    'password123',
  );
  await tester.tap(find.widgetWithText(ElevatedButton, 'Login'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Login memvalidasi email dan password', (tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();
    expect(find.text('Dashboard Keuangan'), findsNothing);
    expect(Navigator.of(tester.element(find.byType(Form))).canPop(), isFalse);

    await tester.tap(find.widgetWithText(ElevatedButton, 'Login'));
    await tester.pumpAndSettle();
    expect(find.text('Email wajib diisi'), findsOneWidget);
    expect(find.text('Password wajib diisi'), findsOneWidget);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Email'),
      'bukan-email',
    );
    await tester.tap(find.widgetWithText(ElevatedButton, 'Login'));
    await tester.pumpAndSettle();
    expect(find.text('Masukkan email yang valid'), findsOneWidget);
    expect(find.text('Dashboard Keuangan'), findsNothing);
  });

  testWidgets('Login, navigasi, detail, form, profil, dan logout', (
    tester,
  ) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();
    await login(tester, 'budi@example.com');

    expect(find.text('Dashboard Keuangan'), findsOneWidget);
    expect(find.text('budi@example.com'), findsOneWidget);
    expect(
      Navigator.of(tester.element(find.byType(BottomNavigationBar))).canPop(),
      isFalse,
    );

    await tester.tap(find.text('Riwayat'));
    await tester.pumpAndSettle();
    expect(find.text('Riwayat Transaksi'), findsOneWidget);
    expect(find.text('Makan Siang'), findsOneWidget);
    expect(find.text('Gaji Bulanan'), findsOneWidget);

    await tester.tap(find.text('Makan Siang'));
    await tester.pumpAndSettle();
    expect(find.text('Detail Transaksi'), findsOneWidget);
    expect(find.text('Makanan'), findsOneWidget);
    expect(find.text('13 September 2026'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Riwayat Transaksi'), findsOneWidget);

    await tester.tap(find.text('Beranda'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    expect(find.text('Catat Transaksi'), findsOneWidget);
    expect(
      ModalRoute.of(tester.element(find.byType(Form)))?.settings.name,
      '/add',
    );
    await tester.tap(find.widgetWithText(ElevatedButton, 'Simpan'));
    await tester.pumpAndSettle();
    expect(find.text('Tidak boleh kosong'), findsNWidgets(2));
    expect(find.text('Tanggal transaksi wajib diisi'), findsOneWidget);
    await tester.enterText(find.widgetWithText(TextFormField, 'Judul'), 'Buku');
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Nominal'),
      '25000',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Tanggal Transaksi'),
      '23/10/2026',
    );
    await tester.tap(find.widgetWithText(ElevatedButton, 'Simpan'));
    await tester.pumpAndSettle();
    expect(find.text('Dashboard Keuangan'), findsOneWidget);
    expect(find.text('Transaksi Berhasil Disimpan!'), findsOneWidget);

    await tester.tap(find.text('Profil'));
    await tester.pumpAndSettle();
    expect(find.byType(CircleAvatar), findsOneWidget);
    expect(find.text('Budi'), findsOneWidget);
    expect(find.text('budi@example.com'), findsOneWidget);
    await tester.tap(find.text('Logout'));
    await tester.pumpAndSettle();
    expect(find.byType(TextFormField), findsNWidgets(2));
    expect(find.byType(BottomNavigationBar), findsNothing);
    expect(find.text('budi@example.com'), findsNothing);
    expect(Navigator.of(tester.element(find.byType(Form))).canPop(), isFalse);

    await login(tester, 'siti@example.com');
    expect(find.text('siti@example.com'), findsOneWidget);
    expect(find.text('budi@example.com'), findsNothing);
    await tester.tap(find.text('Profil'));
    await tester.pumpAndSettle();
    expect(find.text('siti@example.com'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
