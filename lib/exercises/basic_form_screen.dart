import 'package:flutter/material.dart';

import '../app_scope.dart';
import '../data/app_exception.dart';

class BasicFormScreen extends StatefulWidget {
  const BasicFormScreen({super.key});

  @override
  State<BasicFormScreen> createState() => _BasicFormScreenState();
}

class _BasicFormScreenState extends State<BasicFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  bool _restored = false;
  bool _saving = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_restored) return;
    _restored = true;
    final controller = AppScope.read(context);
    _nameController.text = controller.savedValue('form_name');
    _emailController.text = controller.savedValue('form_email');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_saving || !_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _saving = true);
    try {
      final name = _nameController.text.trim();
      final email = _emailController.text.trim();
      await AppScope.read(context)
          .saveValues({'form_name': name, 'form_email': email});
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Validasi $name, $email Berhasil')),
      );
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
      appBar: AppBar(title: const Text('Basic Form TextFormField')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const SizedBox(height: 10),
              TextFormField(
                controller: _nameController,
                enabled: !_saving,
                decoration: const InputDecoration(
                  labelText: 'Nama : ',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Masukkan nama anda'
                    : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _emailController,
                enabled: !_saving,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email : ',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Masukkan email anda';
                  }
                  return RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$')
                          .hasMatch(value.trim())
                      ? null
                      : 'Email tidak valid';
                },
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saving ? null : _submit,
                  child: Text(_saving ? 'Menyimpan…' : 'Submit'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
