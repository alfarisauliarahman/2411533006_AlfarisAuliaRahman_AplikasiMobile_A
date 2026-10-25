import 'package:flutter/material.dart';

import '../app_scope.dart';
import '../data/app_exception.dart';

class BasicTextFieldScreen extends StatefulWidget {
  const BasicTextFieldScreen({super.key});

  @override
  State<BasicTextFieldScreen> createState() => _BasicTextFieldScreenState();
}

class _BasicTextFieldScreenState extends State<BasicTextFieldScreen> {
  final _nameController = TextEditingController();
  bool _restored = false;
  bool _saving = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_restored) return;
    _restored = true;
    _nameController.text = AppScope.read(context).savedValue('basic_name');
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_saving) return;
    FocusScope.of(context).unfocus();
    setState(() => _saving = true);
    try {
      final name = _nameController.text.trim();
      await AppScope.read(context).saveValues({'basic_name': name});
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Nama anda adalah: $name')));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error is AppException ? error.message : 'Data gagal disimpan.',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Basic Form')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Masukkan nama anda :'),
            const SizedBox(height: 10),
            TextField(
              controller: _nameController,
              enabled: !_saving,
              keyboardType: TextInputType.text,
              decoration: const InputDecoration(
                labelText: 'Nama Lengkap',
                hintText: 'Misalnya masnoer',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saving ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber,
                foregroundColor: Colors.black,
              ),
              child: Text(_saving ? 'Menyimpan…' : 'Tampilkan Nama'),
            ),
          ],
        ),
      ),
    );
  }
}
