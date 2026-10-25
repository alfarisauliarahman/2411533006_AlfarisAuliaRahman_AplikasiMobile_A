import 'package:flutter/material.dart';

import 'app_scope.dart';
import 'data/app_exception.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _busy = false;
  bool _routeEmailApplied = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_routeEmailApplied) return;
    _routeEmailApplied = true;
    final email = ModalRoute.of(context)?.settings.arguments;
    if (email is String) _emailController.text = email;
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_busy) return;
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      await AppScope.read(context).login(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
    } on AppException catch (error) {
      if (!mounted) return;
      _showError(error.message);
    } catch (_) {
      if (!mounted) return;
      _showError('Login belum berhasil. Silakan coba lagi.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _openRegister() async {
    if (_busy) return;
    final result = await Navigator.of(context).pushNamed('/register');
    final email = result is String ? result : null;
    if (!mounted || email == null) return;
    setState(() {
      _emailController.text = email;
      _passwordController.clear();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Akun berhasil dibuat. Silakan masuk.')),
    );
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
    const amber = Colors.amber;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
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
                        decoration: BoxDecoration(
                          color: red,
                          borderRadius: BorderRadius.circular(22),
                        ),
                        child: const Icon(
                          Icons.account_balance_wallet_rounded,
                          color: Colors.white,
                          size: 40,
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                    const Text(
                      'Selamat Datang',
                      style: TextStyle(
                        fontSize: 27,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Masuk untuk mengelola catatan keuangan Anda.',
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 28),
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
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordController,
                      enabled: !_busy,
                      obscureText: _obscurePassword,
                      textInputAction: TextInputAction.done,
                      autofillHints: const [AutofillHints.password],
                      onFieldSubmitted: (_) => _login(),
                      decoration:
                          _inputDecoration(
                            'Kata sandi',
                            Icons.lock_outline,
                          ).copyWith(
                            suffixIcon: IconButton(
                              tooltip: _obscurePassword
                                  ? 'Tampilkan kata sandi'
                                  : 'Sembunyikan kata sandi',
                              onPressed: _busy
                                  ? null
                                  : () => setState(
                                      () =>
                                          _obscurePassword = !_obscurePassword,
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
                    const SizedBox(height: 24),
                    SizedBox(
                      height: 52,
                      child: FilledButton(
                        onPressed: _busy ? null : _login,
                        style: FilledButton.styleFrom(
                          backgroundColor: red,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: red.withValues(alpha: .55),
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
                                'Masuk',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Wrap(
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        const Text('Belum punya akun? '),
                        TextButton(
                          onPressed: _busy ? null : _openRegister,
                          style: TextButton.styleFrom(foregroundColor: red),
                          child: const Text(
                            'Daftar',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Center(
                      child: Container(
                        width: 36,
                        height: 3,
                        decoration: BoxDecoration(
                          color: amber,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ],
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
