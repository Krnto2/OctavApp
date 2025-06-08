import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AddAnuncioDialog extends StatefulWidget {
  const AddAnuncioDialog({super.key});

  @override
  State<AddAnuncioDialog> createState() => _AddAnuncioDialogState();
}

class _AddAnuncioDialogState extends State<AddAnuncioDialog> {
  final _tituloController = TextEditingController();
  final _descripcionController = TextEditingController();
  File? _imagen;
  bool _subiendo = false;

  Future<void> _pickImage(ImageSource source, Function setStateDialog) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source, imageQuality: 75);
    if (picked != null) {
      setState(() {
        _imagen = File(picked.path);
      });
      setStateDialog(() {}); // Actualiza dentro del diálogo
    }
  }

  Future<void> _crearAnuncio() async {
    if (_tituloController.text.trim().isEmpty || _descripcionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Título y descripción son obligatorios')),
      );
      return;
    }

    setState(() {
      _subiendo = true;
    });

    final user = FirebaseAuth.instance.currentUser;
    final now = DateTime.now();
    String? imagenBase64;

    if (_imagen != null) {
      final bytes = await _imagen!.readAsBytes();
      imagenBase64 = base64Encode(bytes);
    }

    await FirebaseFirestore.instance.collection('anuncios').add({
      'titulo': _tituloController.text.trim(),
      'descripcion': _descripcionController.text.trim(),
      'imagenBase64': imagenBase64,
      'creadoPor': user?.email ?? 'desconocido',
      'fechaCreacion': now,
      'vistoPor': [],
    });

    setState(() {
      _tituloController.clear();
      _descripcionController.clear();
      _imagen = null;
      _subiendo = false;
    });

    if (mounted) {
      Navigator.of(context).pop();
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Éxito'),
          content: const Text('El anuncio fue publicado correctamente.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Aceptar'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return StatefulBuilder(
      builder: (context, setStateDialog) => AlertDialog(
        title: const Text('Nuevo anuncio'),
        content: SingleChildScrollView(
          child: SizedBox(
            width: MediaQuery.of(context).size.width * 0.85,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: _tituloController,
                  decoration: const InputDecoration(labelText: 'Título'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _descripcionController,
                  maxLines: 4,
                  decoration: const InputDecoration(labelText: 'Descripción'),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      icon: const Icon(Icons.camera_alt),
                      label: const Text('Cámara'),
                      onPressed: () => _pickImage(ImageSource.camera, setStateDialog),
                    ),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.photo_library),
                      label: const Text('Galería'),
                      onPressed: () => _pickImage(ImageSource.gallery, setStateDialog),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                if (_imagen != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Center(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(
                          _imagen!,
                          height: 150,
                          width: 150,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        actions: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  setState(() {
                    _tituloController.clear();
                    _descripcionController.clear();
                    _imagen = null;
                  });
                },
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: _subiendo ? null : _crearAnuncio,
                child: _subiendo
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator())
                    : const Text('Publicar'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
