import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_scope.dart';
import 'data/app_exception.dart';
import 'date_input.dart';

class AddTransactionScreen extends StatefulWidget {
  const AddTransactionScreen({super.key, this.kind = 'expense'});

  final String kind;

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _dateController = TextEditingController();
  late final String _kind;
  late final List<String> _categories;
  late String _selectedCategory;
  bool _isSaving = false;
  bool _didInitializeKind = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didInitializeKind) return;
    _didInitializeKind = true;
    final routeKind = ModalRoute.of(context)?.settings.arguments;
    final requestedKind = routeKind is String ? routeKind : widget.kind;
    _kind = const {'income', 'expense', 'transfer'}.contains(requestedKind)
        ? requestedKind
        : 'expense';
    _categories = switch (_kind) {
      'income' => const ['Gaji', 'Bonus', 'Investasi', 'Hadiah', 'Lainnya'],
      'transfer' => const ['Transfer', 'Tabungan', 'Pembayaran', 'Lainnya'],
      _ => const [
        'Makanan',
        'Transportasi',
        'Hiburan',
        'Belanja',
        'Tagihan',
        'Kesehatan',
        'Lainnya',
      ],
    };
    _selectedCategory = _categories.first;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    FocusScope.of(context).unfocus();
    final selected = await showDatePicker(
      context: context,
      initialDate: parseTransactionDate(_dateController.text) ?? DateTime.now(),
      firstDate: DateTime(1),
      lastDate: DateTime(9999, 12, 31),
      helpText: 'Pilih tanggal transaksi',
      cancelText: 'Batal',
      confirmText: 'Pilih',
    );
    if (!mounted || selected == null) return;
    final text = formatTransactionDate(selected);
    _dateController.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }

  Future<void> _save() async {
    if (_isSaving || !_formKey.currentState!.validate()) return;
    final date = parseTransactionDate(_dateController.text.trim());
    final amount = int.tryParse(_amountController.text.trim());
    if (date == null || amount == null) return;

    setState(() => _isSaving = true);
    try {
      await AppScope.read(context).addTransaction(
        title: _titleController.text.trim(),
        amount: amount,
        kind: _kind,
        category: _selectedCategory,
        date: date,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Transaksi berhasil disimpan.'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } on AppException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message), backgroundColor: Colors.red),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Transaksi gagal disimpan. Silakan coba lagi.'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_pageTitle),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _titleController,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Judul Transaksi',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.title),
                ),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Judul transaksi tidak boleh kosong'
                    : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  labelText: 'Nominal (Rp)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.attach_money),
                ),
                validator: (value) {
                  final text = value?.trim() ?? '';
                  if (text.isEmpty) return 'Nominal wajib diisi';
                  final amount = int.tryParse(text);
                  if (amount == null) return 'Masukkan nominal bilangan bulat';
                  if (amount <= 0) return 'Nominal harus lebih dari 0';
                  if (amount > 9000000000000) {
                    return 'Nominal maksimal Rp 9.000.000.000.000';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Kategori',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.category),
                ),
                items: _categories
                    .map(
                      (category) => DropdownMenuItem(
                        value: category,
                        child: Text(category),
                      ),
                    )
                    .toList(),
                onChanged: _isSaving
                    ? null
                    : (value) {
                        if (value != null) {
                          setState(() => _selectedCategory = value);
                        }
                      },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _dateController,
                keyboardType: TextInputType.number,
                inputFormatters: [TransactionDateFormatter()],
                decoration: InputDecoration(
                  labelText: 'Tanggal Transaksi',
                  hintText: 'DD/MM/YYYY',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.calendar_today),
                  suffixIcon: IconButton(
                    tooltip: 'Pilih tanggal transaksi',
                    icon: const Icon(Icons.date_range),
                    onPressed: _isSaving ? null : _pickDate,
                  ),
                ),
                validator: (value) {
                  final text = value?.trim() ?? '';
                  if (text.isEmpty) return 'Tanggal transaksi wajib diisi';
                  if (!RegExp(r'^\d{2}/\d{2}/\d{4}$').hasMatch(text)) {
                    return 'Gunakan format DD/MM/YYYY';
                  }
                  if (parseTransactionDate(text) == null) {
                    return 'Tanggal transaksi tidak valid';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: _isSaving ? null : _save,
                child: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Simpan Transaksi',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String get _pageTitle => switch (_kind) {
    'income' => 'Catat Pemasukan',
    'transfer' => 'Catat Transfer',
    _ => 'Catat Pengeluaran',
  };
}
