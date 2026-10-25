import 'package:flutter/material.dart';

import '../app_scope.dart';
import '../data/app_exception.dart';

class CalculatorPage extends StatefulWidget {
  const CalculatorPage({super.key});

  @override
  State<CalculatorPage> createState() => _CalculatorPageState();
}

class _CalculatorPageState extends State<CalculatorPage> {
  final _firstController = TextEditingController();
  final _secondController = TextEditingController();
  String _result = 'Masukkan dua angka, lalu pilih operasi.';

  bool _restored = false;
  bool _saving = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_restored) return;
    _restored = true;
    final controller = AppScope.read(context);
    _firstController.text = controller.savedValue('calculator_first');
    _secondController.text = controller.savedValue('calculator_second');
    final result = controller.savedValue('calculator_result');
    if (result.isNotEmpty) _result = result;
  }

  @override
  void dispose() {
    _firstController.dispose();
    _secondController.dispose();
    super.dispose();
  }

  Future<void> _calculate(String operation) async {
    if (_saving) return;
    final first = double.tryParse(_firstController.text.trim());
    final second = double.tryParse(_secondController.text.trim());

    if (first == null ||
        second == null ||
        !first.isFinite ||
        !second.isFinite) {
      setState(() => _result = 'Input harus berupa angka yang valid.');
      return;
    }

    if (operation == '÷' && second == 0) {
      setState(() => _result = 'Pembagian dengan nol tidak dapat dilakukan.');
      return;
    }

    final value = switch (operation) {
      '+' => first + second,
      '-' => first - second,
      '×' => first * second,
      '÷' => first / second,
      _ => 0,
    };

    if (!value.isFinite) {
      setState(() => _result = 'Hasil operasi terlalu besar.');
      return;
    }
    final formatted = value == value.truncateToDouble()
        ? value.toStringAsFixed(0)
        : value.toStringAsFixed(2);

    final result = '$first $operation $second = $formatted';
    setState(() => _saving = true);
    FocusScope.of(context).unfocus();
    try {
      await AppScope.read(context).saveValues({
        'calculator_first': _firstController.text.trim(),
        'calculator_second': _secondController.text.trim(),
        'calculator_result': result,
      });
      if (mounted) setState(() => _result = result);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error is AppException ? error.message : 'Hasil gagal disimpan.',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _operationButton(String operation) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: ElevatedButton(
          onPressed: _saving ? null : () => _calculate(operation),
          child: Text(operation, style: const TextStyle(fontSize: 22)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kalkulator Kabataku')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Masukkan dua angka',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _firstController,
            enabled: !_saving,
            keyboardType: const TextInputType.numberWithOptions(
              decimal: true,
              signed: true,
            ),
            decoration: const InputDecoration(
              labelText: 'Angka pertama',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.looks_one),
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _secondController,
            enabled: !_saving,
            keyboardType: const TextInputType.numberWithOptions(
              decimal: true,
              signed: true,
            ),
            decoration: const InputDecoration(
              labelText: 'Angka kedua',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.looks_two),
            ),
          ),
          const SizedBox(height: 22),
          const Text(
            'Pilih operasi',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _operationButton('+'),
              _operationButton('-'),
              _operationButton('×'),
              _operationButton('÷'),
            ],
          ),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Hasil',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(_result, style: const TextStyle(fontSize: 18)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
