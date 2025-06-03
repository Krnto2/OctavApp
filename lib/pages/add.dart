import 'dart:io';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class AddPage extends StatefulWidget {
  const AddPage({super.key});

  @override
  State<AddPage> createState() => _AddPageState();
}

class _AddPageState extends State<AddPage> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _codigoController = TextEditingController();

  String? tipoSeleccionado;
  String? estadoSeleccionado;
  String? ubicacionSeleccionada;
  String? zonaEspecifica;
  File? _imagen;

  final tipos = [
    "PITON", "BOQUILLA", "MANGUERA", "LLAVE DE COPLA", "MATERIAL DE AGUA",
    "HERRAMIENTAS MANUALES", "MATERIAL DE COMBUSTIÓN", "COMPRESOR",
    "ABASTECIMIENTO CILINDROS", "EPP", "EQUIPOS DE BATERÍA",
    "MATERIAL DE ESTABILIZACIÓN", "CUERDAS/ARNÉS", "ESCALAS", "BOTIQUÍN",
    "MATERIAL DE TRAUMA", "EXTINTOR", "OTRO"
  ];
  final estados = ["operativo", "fuera de servicio"];
  final ubicaciones = ["bodega", "b8", "h8", "f8"];
  final zonas = ["cajonera 1", "cajonera 2", "cajonera 3", "bomba", "cabina"];

  Future<void> _pickImage(bool fromCamera) async {
    final picked = await ImagePicker().pickImage(
      source: fromCamera ? ImageSource.camera : ImageSource.gallery,
      imageQuality: 75,
    );
    if (picked != null) {
      setState(() => _imagen = File(picked.path));
    }
  }

  Future<String?> _convertImageToBase64(File image) async {
    final bytes = await image.readAsBytes();
    return base64Encode(bytes);
  }

  Future<void> _subirItem() async {
    if (!_formKey.currentState!.validate()) return;

    String? imagenBase64;
    if (_imagen != null) {
      imagenBase64 = await _convertImageToBase64(_imagen!);
    }

    await FirebaseFirestore.instance.collection('items').add({
      'nombre': _nombreController.text,
      'tipo': tipoSeleccionado,
      'codigo_cbt': _codigoController.text.isEmpty ? null : _codigoController.text,
      'estado': estadoSeleccionado,
      'ubicacion': ubicacionSeleccionada,
      'zona': ubicacionSeleccionada != 'bodega' ? zonaEspecifica : null,
      'imagen_base64': imagenBase64,
      'creado': FieldValue.serverTimestamp(),
    });

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Añadir ítems')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Tipo de ítem'),
                items: tipos.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                onChanged: (val) => setState(() => tipoSeleccionado = val),
                validator: (val) => val == null ? 'Selecciona un tipo' : null,
              ),
              TextFormField(
                controller: _nombreController,
                decoration: const InputDecoration(labelText: 'Nombre del ítem'),
                validator: (val) => val!.isEmpty ? 'Ingresa un nombre' : null,
              ),
              TextFormField(
                controller: _codigoController,
                decoration: const InputDecoration(labelText: 'Código CBT (opcional)'),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  ElevatedButton.icon(
                    icon: const Icon(Icons.camera_alt),
                    label: const Text("Cámara"),
                    onPressed: () => _pickImage(true),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.photo_library),
                    label: const Text("Galería"),
                    onPressed: () => _pickImage(false),
                  ),
                ],
              ),
              if (_imagen != null)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Image.file(_imagen!, height: 150),
                ),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Estado'),
                items: estados.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                onChanged: (val) => setState(() => estadoSeleccionado = val),
                validator: (val) => val == null ? 'Selecciona un estado' : null,
              ),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Ubicación'),
                items: ubicaciones.map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
                onChanged: (val) => setState(() {
                  ubicacionSeleccionada = val;
                  zonaEspecifica = null;
                }),
                validator: (val) => val == null ? 'Selecciona una ubicación' : null,
              ),
              if (ubicacionSeleccionada != null && ubicacionSeleccionada != 'bodega')
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'Zona específica'),
                  items: zonas.map((z) => DropdownMenuItem(value: z, child: Text(z))).toList(),
                  onChanged: (val) => setState(() => zonaEspecifica = val),
                  validator: (val) => val == null ? 'Selecciona una zona' : null,
                ),
              const SizedBox(height: 20),
              Center(
                child: ElevatedButton.icon(
                  onPressed: _subirItem,
                  icon: const Icon(Icons.save),
                  label: const Text('Guardar ítem'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
