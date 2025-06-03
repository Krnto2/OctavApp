import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  bool esCorreoValido(String correo) {
    final regex = RegExp(r'^.+\..+\.8@cbt\.cl$');
    return regex.hasMatch(correo);
  }

  Future<void> _registrar() async {
    if (!_formKey.currentState!.validate()) return;

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    final excepcionesAdmin = ['capitan8@cbt.cl', 'director8@cbt.cl'];
    final esAdmin = excepcionesAdmin.contains(email);
    final esValido = esAdmin || esCorreoValido(email);

    if (!esValido) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Correo no válido para registro")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final credenciales = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);

      try {
        await FirebaseFirestore.instance
            .collection('usuarios')
            .doc(credenciales.user!.uid)
            .set({
          'email': email,
          'rol': esAdmin ? 'admin' : 'bombero',
        });
      } catch (_) {
        // si firestore falla, igual seguimos
      }

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Registro exitoso"),
          content: const Text("Cuenta creada correctamente."),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushReplacementNamed(context, '/login');
              },
              child: const Text("Aceptar"),
            ),
          ],
        ),
      );
    } on FirebaseAuthException catch (e) {
      String mensaje = "Error al crear la cuenta";
      if (e.code == 'email-already-in-use') {
        mensaje = "Este correo ya está registrado";
      } else if (e.code == 'invalid-email') {
        mensaje = "Correo inválido";
      } else if (e.code == 'weak-password') {
        mensaje = "Contraseña muy débil";
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(mensaje)),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error inesperado: ${e.toString()}")),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0EDED), // Fondo gris cálido, más suave y diferente
   appBar: AppBar(
  backgroundColor: const Color(0xFFD32F2F), // Rojo más fuerte
  title: const Text('Crear cuenta', style: TextStyle(color: Colors.white)),
  centerTitle: true,
  iconTheme: const IconThemeData(color: Colors.white),
),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Image.asset('assets/images/escudo.png', height: 140),
              const SizedBox(height: 30),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Correo institucional',
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Ingresa un correo' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Contraseña',
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value != null && value.length < 6 ? 'Mínimo 6 caracteres' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _confirmController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Confirmar contraseña',
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value != _passwordController.text ? 'Las contraseñas no coinciden' : null,
              ),
              const SizedBox(height: 24),
              _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFD32F2F),
                        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                      ),
                      onPressed: _registrar,
                      child: const Text('Crear cuenta', style: TextStyle(color: Colors.white)),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
