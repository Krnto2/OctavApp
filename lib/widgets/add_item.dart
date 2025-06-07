import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';

class AddItemWidget extends StatefulWidget {
  const AddItemWidget({super.key});

  @override
  State<AddItemWidget> createState() => _AddItemWidgetState();
}

class _AddItemWidgetState extends State<AddItemWidget> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _codigoController = TextEditingController();
  final _descripcionController = TextEditingController();

  String? tipoSeleccionado;
  String? subtipoSeleccionado;
  String? estadoSeleccionado;
  String? ubicacionSeleccionada;
  String? zonaEspecifica;
  File? _imagen;
  File? _manualPDF;

  final estados = ["Operativo", "Fuera de servicio"];
  final ubicaciones = ["Bodega", "B-8", "H-8", "F-8"];

  final zonasB8 = ["Cajonera 1", "Cajonera 2", "Cajonera 3", "Cajonera 4", "Cajonera 5", "Cajonera 6", "Cajonera 7", "Bomba", "Cabina", "Techo", "Frente"];
  final zonasH8 = ["Cajonera 1", "Cajonera 2", "Cajonera 3", "Cajonera 4", "Cajonera 5", "Cajonera 6", "Cajonera 7", "Techo", "Cabina"];
  final zonasF8 = ["Cajonera 1", "Cajonera 2", "Techo", "Cabina", "Atras"];

  final Map<String, List<String>> tiposConSubtipos = {
    "Material de Agua": ["Piton", "Copla", "Manguera", "Otro"],
    "Herramienta": ["Manual", "Combustión", "Eléctrica", "Otro"],
    "EPP": ["Arnes ERA", "Máscara", "Botella", "Otro"]
  };

  final List<String> tiposSinSubtipos = [
    "Equipo de medicion",
    "Material Estabilizacion",
    "Escala",
    "Botiquin",
    "Extintor",
    "Cuerdas/Arnes",
    "Material Haz-Mat",
    "DEA",
    "Otro"
  ];

  List<String> getZonasPorUbicacion(String? ubicacion) {
    switch (ubicacion) {
      case "B-8": return zonasB8;
      case "H-8": return zonasH8;
      case "F-8": return zonasF8;
      default: return [];
    }
  }

  Future<void> _pickImage(bool fromCamera) async {
    final picked = await ImagePicker().pickImage(
      source: fromCamera ? ImageSource.camera : ImageSource.gallery,
      imageQuality: 75,
    );
    if (picked != null) setState(() => _imagen = File(picked.path));
  }

  Future<void> _pickPDF() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (result != null && result.files.single.path != null) {
      setState(() => _manualPDF = File(result.files.single.path!));
    }
  }

  Future<String?> _convertImageToBase64(File image) async {
    final bytes = await image.readAsBytes();
    return base64Encode(bytes);
  }

  Future<void> _subirItem() async {
    if (!_formKey.currentState!.validate()) return;

    final codigoCBT = _codigoController.text.trim();
    final nombre = _nombreController.text.trim();
    final tipo = tipoSeleccionado;
    final subtipo = subtipoSeleccionado;
    final estado = estadoSeleccionado;
    final ubicacion = estado == 'Fuera de servicio' ? 'Bodega' : ubicacionSeleccionada;
    final zona = (ubicacion != 'Bodega') ? zonaEspecifica : null;
    final descripcion = _descripcionController.text.trim();
    final userEmail = FirebaseAuth.instance.currentUser?.email ?? "desconocido@cbt.cl";

    try {
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
          return;
        }
      }

      String? imagenBase64;
      if (_imagen != null) {
        imagenBase64 = await _convertImageToBase64(_imagen!);
      }

      String? manualPdfUrl;
      if (_manualPDF != null) {
        final pdfName = DateTime.now().millisecondsSinceEpoch.toString();
final ref = FirebaseStorage.instance.ref().child('manuales/$pdfName.pdf');

        await ref.putFile(_manualPDF!);
        manualPdfUrl = await ref.getDownloadURL();
      }

      await FirebaseFirestore.instance.collection('items').add({
        'nombre': nombre,
        'tipo': tipo,
        'subtipo': subtipo,
        'codigo_cbt': codigoCBT.isEmpty ? null : codigoCBT,
        'estado': estado,
        'ubicacion': ubicacion,
        'zona': zona,
        'descripcion': descripcion.isEmpty ? null : descripcion,
        'manual_pdf_url': manualPdfUrl,
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
          SnackBar(content: Text('Error al guardar el ítem: \$e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool tieneSubtipos = tipoSeleccionado != null && tiposConSubtipos.containsKey(tipoSeleccionado);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: 'Tipo de ítem'),
              value: tipoSeleccionado,
              items: [...tiposConSubtipos.keys, ...tiposSinSubtipos]
                  .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                  .toList(),
              onChanged: (val) {
                setState(() {
                  tipoSeleccionado = val;
                  if (val == null || !tiposConSubtipos.containsKey(val)) {
                    subtipoSeleccionado = null;
                  } else {
                    final nuevosSubtipos = tiposConSubtipos[val]!;
                    if (!nuevosSubtipos.contains(subtipoSeleccionado)) {
                      subtipoSeleccionado = null;
                    }
                  }
                });
              },
              validator: (val) => val == null ? 'Selecciona un tipo' : null,
            ),
            if (tieneSubtipos)
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Subtipo'),
                value: subtipoSeleccionado,
                items: tiposConSubtipos[tipoSeleccionado]!
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: (val) => setState(() => subtipoSeleccionado = val),
                validator: (val) => val == null ? 'Selecciona un subtipo' : null,
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
            TextFormField(
              controller: _descripcionController,
              decoration: const InputDecoration(
                labelText: 'Descripción (opcional)',
                border: OutlineInputBorder(),
              ),
              maxLength: 300,
              maxLines: 3,
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.camera_alt),
                  label: const Text("Cámara"),
                  onPressed: () => _pickImage(true),
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.photo_library),
                  label: const Text("Galería"),
                  onPressed: () => _pickImage(false),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Center(
              child: ElevatedButton.icon(
                onPressed: _pickPDF,
                icon: const Icon(Icons.picture_as_pdf),
                label: Text(_manualPDF == null ? 'Adjuntar manual PDF' : 'PDF adjuntado'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _manualPDF == null ? const Color.fromARGB(255, 245, 163, 139) : Colors.green,
                ),
              ),
            ),
            if (_imagen != null)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Image.file(_imagen!, height: 150),
              ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: 'Estado'),
              value: estadoSeleccionado,
              items: estados.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: (val) => setState(() {
                estadoSeleccionado = val;
                if (val == 'Fuera de servicio') {
                  ubicacionSeleccionada = 'Bodega';
                  zonaEspecifica = null;
                }
              }),
              validator: (val) => val == null ? 'Selecciona un estado' : null,
            ),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: 'Ubicación'),
              value: ubicacionSeleccionada,
              items: ubicaciones.map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
              onChanged: (estadoSeleccionado == 'Fuera de servicio')
                  ? null
                  : (val) {
                      setState(() {
                        ubicacionSeleccionada = val;
                        final nuevasZonas = getZonasPorUbicacion(val);
                        if (!nuevasZonas.contains(zonaEspecifica)) {
                          zonaEspecifica = null;
                        }
                      });
                    },
              validator: (val) => val == null ? 'Selecciona una ubicación' : null,
            ),
            if (ubicacionSeleccionada != null && ubicacionSeleccionada != 'Bodega')
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Zona específica'),
                value: getZonasPorUbicacion(ubicacionSeleccionada).contains(zonaEspecifica) ? zonaEspecifica : null,
                items: getZonasPorUbicacion(ubicacionSeleccionada)
                    .map((z) => DropdownMenuItem(value: z, child: Text(z)))
                    .toList(),
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
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}