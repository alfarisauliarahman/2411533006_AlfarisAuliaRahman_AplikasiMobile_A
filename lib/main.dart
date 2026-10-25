import 'package:flutter/material.dart';

import 'add_transaction_screen.dart';
import 'app_scope.dart';
import 'data/app_controller.dart';
import 'data/app_database.dart';
import 'exercises/basic_form_screen.dart';
import 'exercises/basic_textfield_screen.dart';
import 'exercises/calculator_screen.dart';
import 'login_screen.dart';
import 'main_screen.dart';
import 'models/finance_transaction.dart';
import 'register_screen.dart';
import 'transaction_detail_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const AppBootstrap());
}

class AppBootstrap extends StatefulWidget {
  const AppBootstrap({super.key});

  @override
  State<AppBootstrap> createState() => _AppBootstrapState();
}

class _AppBootstrapState extends State<AppBootstrap> {
  late Future<AppController> _initialization = _initialize();

  Future<AppController> _initialize() async {
    final database = AppDatabase();
    final controller = AppController(database);
    try {
      await controller.initialize();
      return controller;
    } catch (_) {
      controller.dispose();
      await database.close();
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AppController>(
      future: _initialization,
      builder: (context, snapshot) {
        if (snapshot.hasData) return MyApp(controller: snapshot.data!);
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ThemeData(primarySwatch: Colors.amber),
          home: Scaffold(
            body: Center(
              child: snapshot.hasError
                  ? Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('Penyimpanan lokal belum dapat dibuka.'),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () => setState(() {
                              _initialization = _initialize();
                            }),
                            child: const Text('Coba lagi'),
                          ),
                        ],
                      ),
                    )
                  : const CircularProgressIndicator(),
            ),
          ),
        );
      },
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, required this.controller});

  final AppController controller;

  Route<dynamic> _route(RouteSettings settings) {
    final authenticated = controller.currentUser != null;
    final authRoute = settings.name == '/login' || settings.name == '/register';
    if (!authenticated && !authRoute) {
      return MaterialPageRoute(
        settings: const RouteSettings(name: '/login'),
        builder: (_) => const LoginScreen(),
      );
    }
    Widget page;
    switch (settings.name) {
      case '/login':
        page = const LoginScreen();
      case '/register':
        page = const RegisterScreen();
      case '/':
        page = const MainScreen();
      case '/add':
        final argument = settings.arguments;
        page = AddTransactionScreen(
          kind: argument is String ? argument : 'expense',
        );
      case '/detail':
        final transaction = settings.arguments;
        // A detail route never displays another account's record.
        if (transaction is FinanceTransaction &&
            transaction.userId == controller.currentUser?.id) {
          page = TransactionDetailScreen(transaction: transaction);
        } else {
          page = const MainScreen();
        }
      case '/calculator':
        page = Theme(
          data: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
            useMaterial3: true,
          ),
          child: const CalculatorPage(),
        );
      case '/basic-textfield':
        page = Theme(data: ThemeData(), child: const BasicTextFieldScreen());
      case '/basic-form':
        page = Theme(data: ThemeData(), child: const BasicFormScreen());
      default:
        page = authenticated ? const MainScreen() : const LoginScreen();
    }
    return MaterialPageRoute(settings: settings, builder: (_) => page);
  }

  @override
  Widget build(BuildContext context) {
    return AppScope(
      controller: controller,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Expense Tracker',
        theme: ThemeData(primarySwatch: Colors.amber),
        initialRoute: controller.currentUser == null ? '/login' : '/',
        onGenerateInitialRoutes: (name) => [_route(RouteSettings(name: name))],
        onGenerateRoute: _route,
      ),
    );
  }
}
