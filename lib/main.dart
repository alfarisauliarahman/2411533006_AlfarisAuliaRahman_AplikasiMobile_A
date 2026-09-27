import 'package:flutter/material.dart';

import 'add_transaction_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Expense Tracker - Modul 3',
      theme: ThemeData(
        primarySwatch: Colors.deepPurple, // Tema warna Modul 3
      ),
      home: const AddTransactionScreen(),
    );
  }
}
