import 'package:flutter/material.dart';

import 'main_screen.dart';
import 'add_transaction_screen.dart';
import 'login_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Expense Tracker Final',
      theme: ThemeData(primarySwatch: Colors.amber),
      // MENGGUNAKAN NAMED ROUTES
      initialRoute: '/login',
      // Mulai dari login tanpa menumpuk halaman utama di belakangnya.
      onGenerateInitialRoutes: (initialRoute) => [
        MaterialPageRoute(
          settings: RouteSettings(name: initialRoute),
          builder: (context) => const LoginScreen(),
        ),
      ],
      routes: {
        '/': (context) => const MainScreen(),
        '/add': (context) => const AddTransactionScreen(),
        '/login': (context) => const LoginScreen(),
      },
    );
  }
}
