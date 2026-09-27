import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:praktikum_satu/main.dart';
import 'package:praktikum_satu/date_input.dart';

void main() {
  test(
    'date formatter inserts separators and supports backspace and paste',
    () {
      final formatter = TransactionDateFormatter();
      TextEditingValue edit(String oldText, String newText) =>
          formatter.formatEditUpdate(
            TextEditingValue(
              text: oldText,
              selection: TextSelection.collapsed(offset: oldText.length),
            ),
            TextEditingValue(
              text: newText,
              selection: TextSelection.collapsed(offset: newText.length),
            ),
          );
      expect(edit('2', '27').text, '27/');
      expect(edit('27/0', '27/09').text, '27/09/');
      expect(edit('', '27092026').text, '27/09/2026');
      expect(edit('27/', '27').text, '27');
      expect(edit('27', '2').text, '2');
      expect(edit('', '27/09/2026123').text, '27/09/2026');
      expect(edit('', 'abc').text, '');
    },
  );

  test('date parser rejects impossible dates and handles leap years', () {
    expect(parseTransactionDate('29/02/2024'), DateTime(2024, 2, 29));
    for (final value in [
      '29/02/2025',
      '31/04/2026',
      '00/01/2026',
      '01/13/2026',
      '01/01/0000',
      '1/1/2026',
    ]) {
      expect(parseTransactionDate(value), isNull, reason: value);
    }
    expect(formatTransactionDate(DateTime(2026, 9, 7)), '07/09/2026');
  });

  testWidgets('typed dates are formatted and invalid dates block saving', (
    tester,
  ) async {
    await tester.pumpWidget(const MyApp());
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'Makan Siang');
    await tester.enterText(fields.at(1), '10000');
    await tester.enterText(fields.at(2), '31042026');
    await tester.pumpAndSettle();
    expect(find.text('31/04/2026'), findsOneWidget);
    expect(find.text('Tanggal transaksi tidak valid'), findsOneWidget);
    await tester.ensureVisible(find.text('Simpan Transaksi'));
    await tester.tap(find.text('Simpan Transaksi'));
    await tester.pumpAndSettle();
    expect(find.byType(SnackBar), findsNothing);
    await tester.enterText(fields.at(2), '27092026');
    tester.testTextInput.hide();
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Simpan Transaksi'));
    await tester.tap(find.text('Simpan Transaksi'));
    await tester.pumpAndSettle();
    expect(find.text('Tersimpan: Makan Siang (Rp 10000)'), findsOneWidget);
  });

  testWidgets('calendar selection fills the same date field', (tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.enterText(find.byType(TextFormField).at(2), '27092026');
    tester.testTextInput.hide();
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Pilih tanggal transaksi'));
    await tester.pumpAndSettle();
    expect(find.byType(DatePickerDialog), findsOneWidget);
    await tester.tap(find.text('Pilih'));
    await tester.pumpAndSettle();
    expect(find.text('27/09/2026'), findsOneWidget);
  });
}
