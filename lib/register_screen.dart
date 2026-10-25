import 'package:flutter/material.dart';

import 'app_scope.dart';
import 'data/app_exception.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmationController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmation = true;
  bool _busy = false;
  bool _allowSuccessPop = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmationController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (_busy) return;
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      final user = await AppScope.read(context).register(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      if (!mounted) return;
      setState(() {
        _allowSuccessPop = true;
        _busy = false;
      });
      await WidgetsBinding.instance.endOfFrame;
      if (!mounted) return;
      Navigator.of(context).pop(user.email);
    } on AppException catch (error) {
      if (!mounted) return;
      _showError(error.message);
    } catch (_) {
      if (!mounted) return;
      _showError('Akun belum berhasil dibuat. Silakan coba lagi.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
      );
  }

  @override
  Widget build(BuildContext context) {
    const red = Colors.redAccent;
    return PopScope(
      canPop: !_busy || _allowSuccessPop,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Daftar Akun'),
          foregroundColor: Colors.black87,
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            tooltip: 'Kembali',
            onPressed: _busy ? null : () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back),
          ),
        ),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(26, 16, 26, 32),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 430),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: Container(
                          width: 82,
                          height: 82,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: red,
                            borderRadius: BorderRadius.circular(22),
                          ),
                          child: const Icon(
                            Icons.person_add_alt_1_rounded,
                            color: Colors.white,
                            size: 40,
                          ),
                        ),
                      ),
                      const SizedBox(height: 22),
                      const Text(
                        'Buat Akun Baru',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Isi data diri untuk mulai menggunakan pencatat keuangan.',
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          height: 1.45,
                        ),
                      ),
                      const SizedBox(height: 24),
                      TextFormField(
                        controller: _nameController,
                        enabled: !_busy,
                        textCapitalization: TextCapitalization.words,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.name],
                        decoration: _inputDecoration(
                          'Nama',
                          Icons.person_outline,
                        ),
                        validator: (value) => value?.trim().isNotEmpty == true
                            ? null
                            : 'Nama wajib diisi',
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _emailController,
                        enabled: !_busy,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.email],
                        decoration: _inputDecoration(
                          'Email',
                          Icons.email_outlined,
                        ),
                        validator: (value) {
                          final email = value?.trim() ?? '';
                          if (email.isEmpty) return 'Email wajib diisi';
                          if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$')
                              .hasMatch(email)) {
                            return 'Masukkan email yang valid';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _passwordController,
                        enabled: !_busy,
                        obscureText: _obscurePassword,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.newPassword],
                        decoration:
                            _inputDecoration(
                              'Kata sandi',
                              Icons.lock_outline,
                            ).copyWith(
                              helperText: 'Minimal 6 karakter',
                              suffixIcon: IconButton(
                                tooltip: _obscurePassword
                                    ? 'Tampilkan kata sandi'
                                    : 'Sembunyikan kata sandi',
                                onPressed: _busy
                                    ? null
                                    : () => setState(
                                        () => _obscurePassword =
                                            !_obscurePassword,
                                      ),
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                ),
                              ),
                            ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Kata sandi wajib diisi';
                          }
                          if (value.length < 6) {
                            return 'Kata sandi minimal 6 karakter';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _confirmationController,
                        enabled: !_busy,
                        obscureText: _obscureConfirmation,
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _register(),
                        decoration:
                            _inputDecoration(
                              'Konfirmasi kata sandi',
                              Icons.lock_outline,
                            ).copyWith(
                              suffixIcon: IconButton(
                                tooltip: _obscureConfirmation
                                    ? 'Tampilkan kata sandi'
                                    : 'Sembunyikan kata sandi',
                                onPressed: _busy
                                    ? null
                                    : () => setState(
                                        () => _obscureConfirmation =
                                            !_obscureConfirmation,
                                      ),
                                icon: Icon(
                                  _obscureConfirmation
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                ),
                              ),
                            ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Konfirmasi kata sandi wajib diisi';
                          }
                          if (value != _passwordController.text) {
                            return 'Kata sandi belum cocok';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        height: 52,
                        child: FilledButton(
                          onPressed: _busy ? null : _register,
                          style: FilledButton.styleFrom(
                            backgroundColor: red,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _busy
                              ? const SizedBox.square(
                                  dimension: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  'Daftar',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: _busy
                            ? null
                            : () => Navigator.of(context).pop(),
                        style: TextButton.styleFrom(foregroundColor: red),
                        child: const Text('Sudah punya akun? Masuk'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

InputDecoration _inputDecoration(String label, IconData icon) =>
    InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
    );
