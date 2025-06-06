import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../widgets/universal_app_bar.dart';
import '../widgets/item_resumen.dart';

class VerPage extends StatelessWidget {
  final String cajoneraNombre;
  final String ubicacion;

  const VerPage({
    super.key,
    required this.cajoneraNombre,
    required this.ubicacion,
  });

  @override
  Widget build(BuildContext context) {
    final zona = cajoneraNombre[0].toUpperCase() + cajoneraNombre.substring(1).toLowerCase();

    return Scaffold(
      appBar: UniversalAppBar(titulo: 'Contenido: $zona'),
      body: SafeArea(
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('items')
              .where('zona', isEqualTo: zona)
              .where('ubicacion', isEqualTo: ubicacion)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(child: Text('Error: \${snapshot.error}'));
            }

            final docs = snapshot.data?.docs ?? [];

            if (docs.isEmpty) {
              return const Center(child: Text('Sin ítems registrados.'));
            }

            return ListView.builder(
              itemCount: docs.length,
              itemBuilder: (_, index) {
                final data = docs[index].data() as Map<String, dynamic>;
                final nombre = data['nombre'] ?? 'Sin nombre';
                final tipo = data['tipo'] ?? 'Tipo desconocido';
                final base64Image = data['imagen_base64'];

                Widget leadingWidget = const Icon(Icons.inventory);
                if (base64Image != null && base64Image is String) {
                  try {
                    final bytes = base64Decode(base64Image);
                    leadingWidget = Image.memory(bytes, height: 60, width: 60, fit: BoxFit.cover);
                  } catch (_) {
                    leadingWidget = const Icon(Icons.broken_image);
                  }
                }

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    leading: leadingWidget,
                    title: Text(nombre),
                    subtitle: Text(tipo),
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (_) => ItemResumenWidget(data: data),
                      );
                    },
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
