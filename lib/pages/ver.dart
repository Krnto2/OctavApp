import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../widgets/universal_app_bar.dart';

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
              return Center(child: Text('Error: ${snapshot.error}'));
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
                        builder: (_) => AlertDialog(
                          contentPadding: const EdgeInsets.all(20),
                          backgroundColor: const Color(0xFFFDECEC),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          content: SingleChildScrollView(
                            child: Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Text(
                                    nombre,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.black),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 10),
                                  if (base64Image != null)
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: 12),
                                      child: Container(
                                        width: 200,
                                        height: 200,
                                        decoration: BoxDecoration(
                                          color: Colors.grey[200],
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(color: Colors.black26, width: 1),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black12,
                                              blurRadius: 6,
                                              offset: Offset(0, 3),
                                            ),
                                          ],
                                        ),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(12),
                                          child: Image.memory(
                                            base64Decode(base64Image),
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                      ),
                                    ),
                                  _buildInfoText("Tipo", data['tipo']),
                                  _buildInfoText("Subtipo", data['subtipo']),
                                  _buildInfoText("Código CBT", data['codigo_cbt']), 
                                  _buildInfoText("Descripción", data['descripcion']),
                                  const SizedBox(height: 12),
                                  if (data['manual_pdf_url'] != null)
                                    ElevatedButton.icon(
                                      icon: const Icon(Icons.picture_as_pdf),
                                      label: const Text("Ver Manual"),
                                      onPressed: () => _abrirPDF(data['manual_pdf_url'], context),
                                    ),
                                ],
                              ),
                            ),
                          ),
                          actionsAlignment: MainAxisAlignment.center,
                          actions: [
                            TextButton(
                              child: const Text("Cerrar", style: TextStyle(color: Colors.brown)),
                              onPressed: () => Navigator.of(context).pop(),
                            ),
                          ],
                        ),
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

  void _abrirPDF(String url, BuildContext context) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo abrir el PDF')),
        );
      }
    }
  }

  Widget _buildInfoText(String label, dynamic value) {
    if (value == null || (value is String && value.trim().isEmpty)) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Text.rich(
        TextSpan(
          text: "$label: ",
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
          children: [
            TextSpan(
              text: value.toString(),
              style: const TextStyle(fontWeight: FontWeight.normal, color: Colors.black),
            ),
          ],
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
