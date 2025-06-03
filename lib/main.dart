import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'pages/home.dart';
import 'pages/login.dart';
import 'pages/register.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  final prefs = await SharedPreferences.getInstance();
  final logueado = prefs.getBool('logueado') ?? false;
  final isAdmin = prefs.getBool('esAdmin') ?? false;

  runApp(InventarioApp(logueado: logueado, isAdmin: isAdmin));
}

class InventarioApp extends StatefulWidget {
  final bool logueado;
  final bool isAdmin;

  const InventarioApp({
    super.key,
    required this.logueado,
    required this.isAdmin,
  });

  @override
  State<InventarioApp> createState() => _InventarioAppState();
}

class _InventarioAppState extends State<InventarioApp> {
  bool _isDarkMode = false;

  void _toggleTheme(bool isDark) {
    setState(() {
      _isDarkMode = isDark;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Inventario Bomberos',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.red,
          brightness: _isDarkMode ? Brightness.dark : Brightness.light,
        ),
        useMaterial3: true,
      ),
      initialRoute: widget.logueado ? '/home' : '/login',
      onGenerateRoute: (settings) {
        if (settings.name == '/home') {
          final args = settings.arguments as Map<String, dynamic>? ?? {};
          final isAdmin = args['isAdmin'] ?? widget.isAdmin;

          return MaterialPageRoute(
            builder: (_) => HomePage(
              isDarkMode: _isDarkMode,
              onToggleTheme: _toggleTheme,
              isAdmin: isAdmin,
              onLogout: _handleLogout,
            ),
          );
        }

        switch (settings.name) {
          case '/login':
            return MaterialPageRoute(builder: (_) => const LoginPage());
          case '/register':
            return MaterialPageRoute(builder: (_) => const RegisterPage());
          default:
            return null;
        }
      },
    );
  }

  Future<void> _handleLogout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('logueado', false);
    await prefs.setBool('esAdmin', false);
    Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
  }
}
