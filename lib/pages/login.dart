import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final email = _emailController.text.trim().toLowerCase();

      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: _passwordController.text.trim(),
      );

      final isAdmin = email == 'capitan8@cbt.cl' ||
          email == 'director8@cbt.cl' ||
          email.contains('admin');

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('logueado', true);
      await prefs.setBool('esAdmin', isAdmin);

      if (!mounted) return;
      Navigator.pushReplacementNamed(
        context,
        '/home',
        arguments: {'isAdmin': isAdmin},
      );
    } on FirebaseAuthException catch (e) {
      String mensaje = "Error al iniciar sesión";
      if (e.code == 'user-not-found') {
        mensaje = "Usuario no encontrado";
      } else if (e.code == 'wrong-password') {
        mensaje = "Contraseña incorrecta";
      }

      if (!mounted) return;
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text("Error"),
          content: Text(mensaje),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Cerrar"),
            )
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error inesperado: ${e.toString()}")),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _mostrarDialogoRecuperacion() async {
    final emailResetController = TextEditingController();

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext outerCtx) {
        return StatefulBuilder(
          builder: (BuildContext ctx, setState) {
            bool enviando = false;
            String? mensajeError;

            Future<void> enviarCorreo() async {
              final email = emailResetController.text.trim();
              if (email.isEmpty) {
                setState(() {
                  mensajeError = "Ingresa un correo válido.";
                });
                return;
              }

              setState(() {
                enviando = true;
                mensajeError = null;
              });

              try {
               Navigator.pop(ctx); // Cerrar diálogo ANTES del await

                    await FirebaseAuth.instance.sendPasswordResetEmail(email: email);

                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Se ha enviado un enlace a $email")),
                    );


                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Se ha enviado un enlace a $email")),
                );
              } on FirebaseAuthException catch (e) {
                setState(() {
                  mensajeError = e.code == 'user-not-found'
                      ? "No se encontró una cuenta con ese correo"
                      : "Error al enviar correo";
                  enviando = false;
                });
              }
            }

            return AlertDialog(
              title: const Text("Recuperar contraseña"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: emailResetController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: "Correo institucional",
                      hintText: "tucorreo@cbt.cl",
                    ),
                  ),
                  if (mensajeError != null) ...[
                    const SizedBox(height: 8),
                    Text(mensajeError!, style: const TextStyle(color: Colors.red)),
                  ]
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text("Cancelar"),
                ),
                ElevatedButton(
                  onPressed: enviando ? null : enviarCorreo,
                  child: enviando
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text("Enviar"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F8FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF4FC3F7),
        centerTitle: true,
        title: const Text('Iniciar Sesión', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                Image.asset('assets/images/escudo.png', height: 250),
                const SizedBox(height: 30),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Correo institucional',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) =>
                      value == null || value.isEmpty ? 'Ingresa tu correo' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _passwordController,
                  decoration: const InputDecoration(
                    labelText: 'Contraseña',
                    border: OutlineInputBorder(),
                  ),
                  obscureText: true,
                  validator: (value) =>
                      value == null || value.isEmpty ? 'Ingresa tu contraseña' : null,
                ),
                const SizedBox(height: 24),
                _isLoading
                    ? const CircularProgressIndicator()
                    : ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4FC3F7),
                          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                        ),
                        onPressed: _login,
                        child: const Text('Entrar', style: TextStyle(color: Colors.white)),
                      ),
                TextButton(
                  onPressed: _mostrarDialogoRecuperacion,
                  child: const Text(
                    '¿Olvidaste tu contraseña?',
                    style: TextStyle(color: Colors.blue),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/register');
                  },
                  child: const Text(
                    '¿No tienes cuenta? Regístrate',
                    style: TextStyle(color: Colors.black),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
