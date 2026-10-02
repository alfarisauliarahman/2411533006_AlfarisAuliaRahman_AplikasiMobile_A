import 'package:flutter/material.dart';

import 'dashboard_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Expense Tracker Modul - 4',
      theme: ThemeData(primaryColor: Colors.red),
      home: const DashboardScreen(), // Halaman pertama yang dimuat
    );
  }
}
