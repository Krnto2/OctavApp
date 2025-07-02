import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'pages/home.dart';
import 'pages/login.dart';
import 'pages/register.dart';

// Notificaciones locales
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

// Canal de notificaciones Android
const AndroidNotificationChannel androidChannel = AndroidNotificationChannel(
  'high_importance_channel',
  'Notificaciones Importantes',
  description: 'Canal para notificaciones importantes',
  importance: Importance.high,
);

// Manejador de mensajes en segundo plano
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  // Aquí puedes registrar logs o hacer acciones si quieres
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // Activar App Check en modo debug
  await FirebaseAppCheck.instance.activate(
    androidProvider: AndroidProvider.debug,
    appleProvider: AppleProvider.debug,
  );

  // Registrar handler de segundo plano
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Configurar notificaciones
  await _setupNotifications();

  // Leer estado de sesión
  final prefs = await SharedPreferences.getInstance();
  final logueado = prefs.getBool('logueado') ?? false;
  final isAdmin = prefs.getBool('esAdmin') ?? false;

  runApp(InventarioApp(logueado: logueado, isAdmin: isAdmin));
}

Future<void> _setupNotifications() async {
  // Pedir permisos (especialmente en iOS)
  await FirebaseMessaging.instance.requestPermission();

  // Inicializar canal local
  const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
  const initSettings = InitializationSettings(android: androidSettings);
  await flutterLocalNotificationsPlugin.initialize(initSettings);

  // Crear canal en Android (si no existe)
  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(androidChannel);

  // Escuchar mensajes cuando la app esté abierta
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    final notification = message.notification;
    final android = message.notification?.android;

    if (notification != null && android != null) {
      flutterLocalNotificationsPlugin.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            androidChannel.id,
            androidChannel.name,
            channelDescription: androidChannel.description,
            importance: Importance.high,
            priority: Priority.high,
          ),
        ),
      );
    }
  });

  // Suscribirse al topic global de anuncios
  await FirebaseMessaging.instance.subscribeToTopic('anuncios');
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
