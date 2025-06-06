import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'pages/home.dart';
import 'pages/login.dart';
import 'pages/register.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // Activar App Check en modo debug
  await FirebaseAppCheck.instance.activate(
    androidProvider: AndroidProvider.debug,
    appleProvider: AppleProvider.debug,
  );

  final prefs = await SharedPreferences.getInstance();
  final logueado = prefs.getBool('logueado') ?? false;
  final isAdmin = prefs.getBool('esAdmin') ?? false; // ✔ Agregado

  runApp(InventarioApp(logueado: logueado, isAdmin: isAdmin));
}

class InventarioApp extends StatefulWidget {
  final bool logueado;
  final bool isAdmin; // ✔ Agregado

  const InventarioApp({
    super.key,
    required this.logueado,
    required this.isAdmin, // ✔ Agregado
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
          return MaterialPageRoute(
            builder: (_) => HomePage(
              isDarkMode: _isDarkMode,
              onToggleTheme: _toggleTheme,
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
    final navigator = Navigator.of(context);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('logueado', false);
    await prefs.setBool('esAdmin', false);

    navigator.pushNamedAndRemoveUntil('/login', (_) => false);
  }
}