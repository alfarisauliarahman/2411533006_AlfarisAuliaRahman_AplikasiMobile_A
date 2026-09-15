import 'package:flutter/material.dart';

void main() => runApp(const CalculatorApp());

class CalculatorApp extends StatelessWidget {
  const CalculatorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Kalkulator Kabataku',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const CalculatorPage(),
    );
  }
}

class CalculatorPage extends StatefulWidget {
  const CalculatorPage({super.key});

  @override
  State<CalculatorPage> createState() => _CalculatorPageState();
}

class _CalculatorPageState extends State<CalculatorPage> {
  final _firstController = TextEditingController();
  final _secondController = TextEditingController();
  String _result = 'Masukkan dua angka, lalu pilih operasi.';

  @override
  void dispose() {
    _firstController.dispose();
    _secondController.dispose();
    super.dispose();
  }

  void _calculate(String operation) {
    final first = double.tryParse(_firstController.text.trim());
    final second = double.tryParse(_secondController.text.trim());

    if (first == null || second == null) {
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

    final formatted = value == value.truncateToDouble()
        ? value.toInt().toString()
        : value.toStringAsFixed(2);

    setState(() => _result = '$first $operation $second = $formatted');
  }

  Widget _operationButton(String operation) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: ElevatedButton(
          onPressed: () => _calculate(operation),
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
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Angka pertama',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.looks_one),
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _secondController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
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
