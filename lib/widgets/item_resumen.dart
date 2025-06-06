import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class ItemResumenWidget extends StatelessWidget {
  final Map<String, dynamic> data;

  const ItemResumenWidget({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final nombre = data['nombre'] ?? 'Sin nombre';
    final base64Image = data['imagen_base64'];

    return AlertDialog(
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
                      boxShadow: const [
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
              _buildInfoText("Ubicación", data['ubicacion']),
              _buildInfoText("Zona", data['zona']),
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
    );
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
}
