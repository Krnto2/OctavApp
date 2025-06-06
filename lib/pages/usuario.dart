import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UsuarioView extends StatefulWidget {
  const UsuarioView({super.key});

  @override
  State<UsuarioView> createState() => _UsuarioViewState();
}

class _UsuarioViewState extends State<UsuarioView> {
  final TextEditingController _searchController = TextEditingController();

  String getNombreDesdeCorreo(String correo) {
    try {
      final nombreParte = correo.split('@').first;
      final partes = nombreParte.split('.');
      if (partes.length >= 2) {
        final nombre = partes[0];
        final apellido = partes[1];
        return '${nombre[0].toUpperCase()}${nombre.substring(1)} ${apellido[0].toUpperCase()}${apellido.substring(1)}';
      }
      return 'Nombre desconocido';
    } catch (_) {
      return 'Nombre desconocido';
    }
  }

  bool esExcepcion(String correo) {
    return correo == 'capitan8@cbt.cl' || correo == 'director@cbt.cl';
  }

  void cambiarRol(String id, String rolActual) async {
    final nuevoRol = rolActual == 'admin' ? 'bombero' : 'admin';
    await FirebaseFirestore.instance.collection('usuarios').doc(id).update({
      'rol': nuevoRol,
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? const Color(0xFF2C2C2C) : Colors.orange[50];
    final textColor = isDark ? Colors.white : Colors.black87;
    final subtitleColor = isDark ? Colors.white70 : Colors.black54;

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Buscar por nombre',
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('usuarios').snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return const Center(child: Text('Error al cargar usuarios'));
                  }

                  final busqueda = _searchController.text.toLowerCase();
                  final usuarios = snapshot.data!.docs.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final correo = (data['email'] ?? '').toString();
                    if (esExcepcion(correo)) return false;
                    final nombreCompleto = getNombreDesdeCorreo(correo).toLowerCase();
                    return correo.toLowerCase().contains(busqueda) || nombreCompleto.contains(busqueda);
                  }).toList();

                  if (usuarios.isEmpty) {
                    return const Center(child: Text('No se encontraron usuarios'));
                  }

                  return ListView.builder(
                    itemCount: usuarios.length,
                    itemBuilder: (context, index) {
                      final doc = usuarios[index];
                      final data = doc.data() as Map<String, dynamic>;
                      final id = doc.id;
                      final correo = data['email'] ?? 'Sin correo';
                      final rol = data['rol'] ?? 'Desconocido';
                      final nombre = getNombreDesdeCorreo(correo);
                      final esSuperAdmin = rol == 'superadmin';

                      return Card(
                        color: backgroundColor,
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: const Icon(Icons.person, color: Colors.deepOrange, size: 30),
                          title: Text(nombre, style: TextStyle(color: textColor)),
                          subtitle: Text('Rol: $rol', style: TextStyle(color: subtitleColor)),
                          trailing: esSuperAdmin
                              ? const Icon(Icons.lock, color: Colors.grey)
                              : IconButton(
                                  icon: const Icon(Icons.edit, color: Colors.grey),
                                  onPressed: () => cambiarRol(id, rol),
                                ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
