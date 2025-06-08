import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class VerAnuncios extends StatelessWidget {
  final bool isAdmin;
  final VoidCallback onAddPressed;

  const VerAnuncios({super.key, required this.isAdmin, required this.onAddPressed});

  Future<void> _marcarComoVisto(String docId, String uid) async {
    await FirebaseFirestore.instance.collection('anuncios').doc(docId).update({
      'vistoPor': FieldValue.arrayUnion([uid])
    });
  }

  void _mostrarDetalleAnuncio(BuildContext dialogContext, Map<String, dynamic> anuncio, String docId, String uid, bool yaVisto) async {
    if (!yaVisto && uid.isNotEmpty) {
      await _marcarComoVisto(docId, uid);
    }

    final fecha = anuncio['fechaCreacion'] != null
        ? DateFormat('dd/MM/yyyy - HH:mm').format((anuncio['fechaCreacion'] as Timestamp).toDate())
        : 'Fecha no disponible';

    showDialog(
      // ignore: use_build_context_synchronously
      context: dialogContext,
      builder: (BuildContext alertContext) => AlertDialog(
        title: Text(anuncio['titulo'] ?? 'Sin título'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Publicado: $fecha", style: const TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 10),
              if (anuncio['imagenBase64'] != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Image.memory(
                    base64Decode(anuncio['imagenBase64']),
                    fit: BoxFit.cover,
                  ),
                ),
              Text(anuncio['descripcion'] ?? 'Sin descripción'),
            ],
          ),
        ),
        actions: [
          if (isAdmin)
            TextButton(
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: alertContext,
                  builder: (context) => AlertDialog(
                    title: const Text('Confirmar eliminación'),
                    content: const Text('¿Estás seguro de que deseas eliminar este anuncio?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancelar'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  await FirebaseFirestore.instance.collection('anuncios').doc(docId).delete();
                  // ignore: use_build_context_synchronously
                  Navigator.of(alertContext).pop();
                }
              },
              child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
            ),
          TextButton(
            onPressed: () => Navigator.of(alertContext).pop(),
            child: const Text('Cerrar'),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.email ?? '';

    return Column(
      children: [
        if (isAdmin)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Center(
              child: ElevatedButton.icon(
                onPressed: onAddPressed,
                icon: const Icon(Icons.add, color: Colors.white),
                label: const Text('Añadir anuncio', style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.lightBlue,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('anuncios').snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return const Center(child: Text('Error al cargar anuncios'));
              }

              final docs = snapshot.data?.docs ?? [];
              docs.sort((a, b) {
                final aFecha = a['fechaCreacion']?.toString() ?? '';
                final bFecha = b['fechaCreacion']?.toString() ?? '';
                return bFecha.compareTo(aFecha);
              });

              if (docs.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.notifications_none,
                          size: 80, color: Theme.of(context).colorScheme.primary),
                      const SizedBox(height: 20),
                      Text(
                        'No hay anuncios por ahora',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Cuando un administrador publique un anuncio,\nlo verás aquí.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final doc = docs[index];
                  final anuncio = doc.data() as Map<String, dynamic>;
                  final yaVisto = (anuncio['vistoPor'] ?? []).contains(uid);

                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                      leading: Stack(
                        alignment: Alignment.topRight,
                        children: [
                          anuncio['imagenBase64'] != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.memory(
                                    base64Decode(anuncio['imagenBase64']),
                                    width: 50,
                                    height: 50,
                                    fit: BoxFit.cover,
                                  ),
                                )
                              : const Icon(Icons.image_not_supported),
                          if (!yaVisto)
                            const Positioned(
                              right: 0,
                              top: 0,
                              child: CircleAvatar(
                                radius: 8,
                                backgroundColor: Colors.red,
                                child: Text('1', style: TextStyle(fontSize: 10, color: Colors.white)),
                              ),
                            ),
                        ],
                      ),
                      title: Text(anuncio['titulo'] ?? 'Sin título'),
                      onTap: () => _mostrarDetalleAnuncio(context, anuncio, doc.id, uid, yaVisto),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
