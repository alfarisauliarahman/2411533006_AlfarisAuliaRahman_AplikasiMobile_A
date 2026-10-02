import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:praktikum_satu/main.dart' as app;
import 'package:praktikum_satu/transaction_detail_screen.dart';

void main() {
  testWidgets('push passes transaction values and back restores dashboard', (
    tester,
  ) async {
    await tester.pumpWidget(const app.MyApp());
    await tester.tap(find.text('Makan Siang'));
    await tester.pumpAndSettle();
    final detail = tester.widget<TransactionDetailScreen>(
      find.byType(TransactionDetailScreen),
    );
    expect(detail.title, 'Makan Siang');
    expect(detail.amount, '- Rp 50.000');
    expect(detail.category.trim(), 'Makanan');
    expect(detail.date, '13 September 2026');
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.text('Dashboard Keuangan'), findsOneWidget);
    await tester.tap(find.text('Gaji Bulanan'));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<TransactionDetailScreen>(find.byType(TransactionDetailScreen))
          .amount,
      '+ Rp 5.000.000',
    );
  });
  testWidgets('required date blocks pop; valid form returns with snackbar', (
    tester,
  ) async {
    await tester.pumpWidget(const app.MyApp());
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'Internet');
    await tester.enterText(fields.at(1), '120000');
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Simpan'));
    await tester.tap(find.text('Simpan'));
    await tester.pumpAndSettle();
    expect(find.text('Tanggal transaksi wajib diisi'), findsOneWidget);
    expect(find.text('Catat Transaksi'), findsOneWidget);
    await tester.tap(find.byTooltip('Pilih tanggal'));
    await tester.pumpAndSettle();
    expect(find.byType(DatePickerDialog), findsOneWidget);
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<TextFormField>(fields.at(2)).controller!.text,
      matches(RegExp(r'^\d{2}/\d{2}/\d{4}$')),
    );
    await tester.enterText(fields.at(2), '03/10/2026');
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Simpan'));
    await tester.tap(find.text('Simpan'));
    await tester.pumpAndSettle();
    expect(find.text('Dashboard Keuangan'), findsOneWidget);
    expect(find.text('Transaksi Berhasil Disimpan!'), findsOneWidget);
    expect(find.text('Internet'), findsNothing);
  });
}
