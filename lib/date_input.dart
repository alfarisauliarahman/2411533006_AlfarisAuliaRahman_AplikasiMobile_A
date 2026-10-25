import 'package:flutter/services.dart';

DateTime? parseTransactionDate(String value) {
  if (!RegExp(r'^\d{2}/\d{2}/\d{4}$').hasMatch(value)) return null;
  final parts = value.split('/').map(int.parse).toList();
  final day = parts[0];
  final month = parts[1];
  final year = parts[2];
  if (year < 1 || month < 1 || month > 12 || day < 1 || day > 31) {
    return null;
  }
  final date = DateTime(year, month, day);
  return date.day == day && date.month == month && date.year == year
      ? date
      : null;
}

String formatTransactionDate(DateTime date) =>
    '${date.day.toString().padLeft(2, '0')}/'
    '${date.month.toString().padLeft(2, '0')}/'
    '${date.year.toString().padLeft(4, '0')}';

class TransactionDateFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (!newValue.composing.isCollapsed) return newValue;
    var digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (digits.length > 8) digits = digits.substring(0, 8);
    final deleting = newValue.text.length < oldValue.text.length;
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      buffer.write(digits[i]);
      if ((i == 1 || i == 3) && (i < digits.length - 1 || !deleting)) {
        buffer.write('/');
      }
    }
    final text = buffer.toString();
    final rawCursor = newValue.selection.extentOffset.clamp(
      0,
      newValue.text.length,
    );
    final digitsBeforeCursor = newValue.text
        .substring(0, rawCursor)
        .replaceAll(RegExp(r'\D'), '')
        .length
        .clamp(0, digits.length);
    var cursor = 0;
    var seen = 0;
    while (cursor < text.length && seen < digitsBeforeCursor) {
      if (text[cursor] != '/') seen++;
      cursor++;
    }
    if (!deleting && cursor < text.length && text[cursor] == '/') cursor++;
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: cursor),
    );
  }
}
