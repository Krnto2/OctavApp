import 'dart:io';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
  final estados = ["Operativo", "Fuera de servicio"];
  final ubicaciones = ["Bodega", "B-8", "H-8", "F-8"];

  final zonasB8 = [
    "Cajonera 1", "Cajonera 2", "Cajonera 3", "Cajonera 4", "Cajonera 5",
    "Cajonera 6", "Cajonera 7", "Bomba", "Cabina", "Techo", "Frente"
  ];
  final zonasH8 = [
    "Cajonera 1", "Cajonera 2", "Cajonera 3", "Cajonera 4", "Cajonera 5",
    "Cajonera 6", "Cajonera 7", "Techo", "Cabina"
  ];
  final zonasF8 = ["Cajonera 1", "Cajonera 2", "Techo", "Cabina", "Atras"];

  List<String> getZonasPorUbicacion(String? ubicacion) {
    switch (ubicacion) {
      case "B-8":
        return zonasB8;
      case "H-8":
        return zonasH8;
      case "F-8":
        return zonasF8;
      default:
        return [];
    }
  }

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

  final codigoCBT = _codigoController.text.trim().toUpperCase();
  final nombre = _nombreController.text.trim().toUpperCase();
  final tipo = tipoSeleccionado?.toUpperCase();
  final estado = estadoSeleccionado?.toUpperCase();
  final ubicacion = ubicacionSeleccionada?.toUpperCase();
  final zona = (ubicacionSeleccionada != 'Bodega')
      ? zonaEspecifica?.toUpperCase()
      : null;
  final userEmail = FirebaseAuth.instance.currentUser?.email ?? "desconocido@cbt.cl";

  try {
    // Verificar si ya existe un ítem con el mismo código CBT (si se ingresó)
    if (codigoCBT.isNotEmpty) {
      final duplicado = await FirebaseFirestore.instance
          .collection('items')
          .where('codigo_cbt', isEqualTo: codigoCBT)
          .limit(1)
          .get();

      if (duplicado.docs.isNotEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Ya existe un ítem con ese código CBT')),
          );
        }
        return; // No continuar con el guardado
      }
    }

    String? imagenBase64;
    if (_imagen != null) {
      imagenBase64 = await _convertImageToBase64(_imagen!);
    }

    await FirebaseFirestore.instance.collection('items').add({
      'nombre': nombre,
      'tipo': tipo,
      'codigo_cbt': codigoCBT.isEmpty ? null : codigoCBT,
      'estado': estado,
      'ubicacion': ubicacion,
      'zona': zona,
      'imagen_base64': imagenBase64,
      'registrado_por': userEmail,
      'creado': FieldValue.serverTimestamp(),
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ítem guardado correctamente')),
      );
      Navigator.pop(context);
    }
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al guardar el ítem: $e')),
      );
    }
  }
}


  @override
  Widget build(BuildContext context) {
    final zonasDinamicas = getZonasPorUbicacion(ubicacionSeleccionada);

    return Scaffold(
      appBar: AppBar(title: const Text('Añadir ítems')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'Tipo de ítem'),
                  items: tipos
                      .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                      .toList(),
                  onChanged: (val) => setState(() => tipoSeleccionado = val),
                  validator: (val) =>
                      val == null ? 'Selecciona un tipo' : null,
                ),
                TextFormField(
                  controller: _nombreController,
                  decoration:
                      const InputDecoration(labelText: 'Nombre del ítem'),
                  validator: (val) =>
                      val!.isEmpty ? 'Ingresa un nombre' : null,
                ),
                TextFormField(
                  controller: _codigoController,
                  decoration:
                      const InputDecoration(labelText: 'Código CBT (opcional)'),
                ),
                const SizedBox(height: 10),
                      Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ElevatedButton.icon(
                              icon: const Icon(Icons.camera_alt, color: Colors.white),
                              label: const Text("Cámara", style: TextStyle(color: Colors.white)),
                              onPressed: () => _pickImage(true),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color.fromRGBO(45, 98, 243, 1), // color de fondo del botón
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              ),
                            ),
                            const SizedBox(width: 20),
                            ElevatedButton.icon(
                              icon: const Icon(Icons.photo_library, color: Colors.white),
                              label: const Text("Galería", style: TextStyle(color: Colors.white)),
                              onPressed: () => _pickImage(false),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color.fromRGBO(45, 98, 243, 1), // color de fondo del botón
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              ),
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
                  items: estados
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (val) =>
                      setState(() => estadoSeleccionado = val),
                  validator: (val) =>
                      val == null ? 'Selecciona un estado' : null,
                ),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'Ubicación'),
                  items: ubicaciones
                      .map((u) => DropdownMenuItem(value: u, child: Text(u)))
                      .toList(),
                  onChanged: (val) => setState(() {
                    ubicacionSeleccionada = val;
                    zonaEspecifica = null;
                  }),
                  validator: (val) =>
                      val == null ? 'Selecciona una ubicación' : null,
                ),
                if (ubicacionSeleccionada != null &&
                    ubicacionSeleccionada != 'Bodega')
                  DropdownButtonFormField<String>(
                    decoration:
                        const InputDecoration(labelText: 'Zona específica'),
                    items: zonasDinamicas
                        .map((z) =>
                            DropdownMenuItem(value: z, child: Text(z)))
                        .toList(),
                    onChanged: (val) => setState(() => zonaEspecifica = val),
                    validator: (val) =>
                        val == null ? 'Selecciona una zona' : null,
                  ),
                const SizedBox(height: 20),
                Center(
                        child: ElevatedButton.icon(
                          onPressed: _subirItem,
                          icon: const Icon(Icons.save, color: Colors.black), // ícono en negro
                          label: const Text('Guardar ítem', style: TextStyle(color: Colors.black)), // texto en negro
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color.fromARGB(255, 91, 233, 96),
                            foregroundColor: Colors.black, // asegura que texto/ícono usen negro por defecto
                            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                          ),
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
