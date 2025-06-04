import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

class InventarioView extends StatefulWidget {
  const InventarioView({super.key});

  @override
  State<InventarioView> createState() => _InventarioViewState();
}

class _InventarioViewState extends State<InventarioView> {
  final estadosDisponibles = ['Operativo', 'Fuera de servicio'];
  final ubicacionesDisponibles = ['Bodega', 'B-8', 'H-8', 'F-8'];

  final tiposConSubtipos = {
    "Material de Agua": ["Piton", "Copla", "Manguera", "Otro"],
    "Herramienta": ["Manual", "Combustión", "Eléctrica", "Otro"],
    "EPP": ["Máscara", "Botella", "Otro"],
  };

  final tiposSinSubtipos = [
    "Equipo de medición",
    "Material Estabilización",
    "Escala",
    "Botiquín",
    "Extintor",
    "Cuerdas/Arnés",
    "Material Haz-Mat",
    "DEA",
    "Otro"
  ];

  final zonasB8 = ["Cajonera 1", "Cajonera 2", "Cajonera 3", "Cajonera 4", "Cajonera 5", "Cajonera 6", "Cajonera 7", "Bomba", "Cabina", "Techo", "Frente"];
  final zonasH8 = ["Cajonera 1", "Cajonera 2", "Cajonera 3", "Cajonera 4", "Cajonera 5", "Cajonera 6", "Cajonera 7", "Techo", "Cabina"];
  final zonasF8 = ["Cajonera 1", "Cajonera 2", "Techo", "Cabina", "Atrás"];

  File? nuevaImagen;
  File? nuevoPDF;

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
      setState(() => nuevaImagen = File(picked.path));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('items').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: \${snapshot.error}'));
          }

          final items = snapshot.data?.docs ?? [];

          if (items.isEmpty) {
            return const Center(child: Text('No hay ítems registrados.'));
          }

          return Padding(
            padding: const EdgeInsets.all(24.0),
            child: ListView.builder(
              itemCount: items.length,
              itemBuilder: (_, index) {
                final data = items[index].data() as Map<String, dynamic>;
                final docId = items[index].id;
                final nombre = data['nombre'] ?? 'Sin nombre';
                final tipo = data['tipo'] ?? 'Tipo desconocido';
                final base64Image = data['imagen_base64'];

                return GestureDetector(
                  onTap: () => _abrirDialogoEditar(context, data, docId),
                  child: Card(
                    elevation: 4,
                    margin: const EdgeInsets.only(bottom: 20),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: const BorderRadius.horizontal(left: Radius.circular(12)),
                          child: base64Image != null
                              ? Image.memory(
                                  base64Decode(base64Image),
                                  height: 100,
                                  width: 100,
                                  fit: BoxFit.cover,
                                )
                              : Container(
                                  color: Colors.grey[300],
                                  height: 100,
                                  width: 100,
                                  child: const Icon(Icons.image, size: 40),
                                ),
                        ),
                        Expanded(
                          child: ListTile(
                            title: Text(nombre),
                            subtitle: Text(tipo),
                            trailing: const Icon(Icons.edit),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  void _abrirDialogoEditar(BuildContext context, Map<String, dynamic> data, String docId) {
    final nombreCtrl = TextEditingController(text: data['nombre']);
    final cbtCtrl = TextEditingController(text: data['codigo_cbt']);
    final descCtrl = TextEditingController(text: data['descripcion']);

    String? tipoRaw = data['tipo'];
    String? subtipoRaw = data['subtipo'];

    final todosLosTipos = [...tiposConSubtipos.keys, ...tiposSinSubtipos];
    String? tipoFinal = todosLosTipos.firstWhere(
      (t) => t.toLowerCase() == (tipoRaw?.toLowerCase() ?? ''),
      orElse: () => '',
    );
    tipoFinal = todosLosTipos.contains(tipoFinal) ? tipoFinal : null;

    List<String> subtiposDisponibles = tipoFinal != null && tiposConSubtipos.containsKey(tipoFinal)
        ? tiposConSubtipos[tipoFinal]!
        : [];

    String? subtipoFinal = subtiposDisponibles.firstWhere(
      (s) => s.toLowerCase() == (subtipoRaw?.toLowerCase() ?? ''),
      orElse: () => '',
    );
    subtipoFinal = subtiposDisponibles.contains(subtipoFinal) ? subtipoFinal : null;

    String? estado = estadosDisponibles.firstWhere(
      (e) => e.toLowerCase() == (data['estado']?.toString().toLowerCase() ?? ''),
      orElse: () => '',
    );
    if (!estadosDisponibles.contains(estado)) estado = null;

    String? ubicacion = ubicacionesDisponibles.firstWhere(
      (u) => u.toLowerCase() == (data['ubicacion']?.toString().toLowerCase() ?? ''),
      orElse: () => '',
    );
    if (!ubicacionesDisponibles.contains(ubicacion)) ubicacion = null;

    String? zona = data['zona'];

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Editar ítem'),
            content: SingleChildScrollView(
              child: Column(
                children: [
                  TextFormField(controller: nombreCtrl, decoration: const InputDecoration(labelText: 'Nombre')),
                  TextFormField(controller: cbtCtrl, decoration: const InputDecoration(labelText: 'Código CBT')),
                  TextFormField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Descripción')),

                  DropdownButtonFormField<String>(
                    value: tipoFinal,
                    decoration: const InputDecoration(labelText: 'Tipo'),
                    items: todosLosTipos.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                    onChanged: (val) {
                      setState(() {
                        tipoFinal = val;
                        subtiposDisponibles = tiposConSubtipos[val] ?? [];
                        subtipoFinal = null;
                      });
                    },
                  ),

                  if (tipoFinal != null && tiposConSubtipos.containsKey(tipoFinal))
                    DropdownButtonFormField<String>(
                      value: subtipoFinal,
                      decoration: const InputDecoration(labelText: 'Subtipo'),
                      items: subtiposDisponibles.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                      onChanged: (val) => setState(() => subtipoFinal = val),
                    ),

                  DropdownButtonFormField<String>(
                    value: estado,
                    decoration: const InputDecoration(labelText: 'Estado'),
                    items: estadosDisponibles.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                    onChanged: (val) => setState(() => estado = val),
                  ),

                  DropdownButtonFormField<String>(
                    value: ubicacion,
                    decoration: const InputDecoration(labelText: 'Ubicación'),
                    items: ubicacionesDisponibles.map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
                    onChanged: (val) => setState(() {
                      ubicacion = val;
                      zona = null;
                    }),
                  ),

                  if (ubicacion != null && ubicacion != 'Bodega')
                    DropdownButtonFormField<String>(
                      value: getZonasPorUbicacion(ubicacion).contains(zona) ? zona : null,
                      decoration: const InputDecoration(labelText: 'Zona'),
                      items: getZonasPorUbicacion(ubicacion).map((z) => DropdownMenuItem(value: z, child: Text(z))).toList(),
                      onChanged: (val) => setState(() => zona = val),
                    ),

                  const SizedBox(height: 10),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () => _pickImage(true),
                        icon: const Icon(Icons.camera_alt),
                        label: const Text("Cámara"),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton.icon(
                        onPressed: () => _pickImage(false),
                        icon: const Icon(Icons.photo),
                        label: const Text("Galería"),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  ElevatedButton.icon(
                    icon: const Icon(Icons.picture_as_pdf),
                    label: const Text('Subir PDF'),
                    onPressed: () async {
                      final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['pdf']);
                      if (result != null && result.files.single.path != null) {
                        setState(() => nuevoPDF = File(result.files.single.path!));
                      }
                    },
                  ),
                ],
              ),
            ),
            actionsAlignment: MainAxisAlignment.center,
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
              ElevatedButton.icon(
                icon: const Icon(Icons.delete),
                label: const Text('Eliminar ítem'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text('¿Eliminar ítem?'),
                      content: const Text('¿Estás seguro de que deseas eliminar este ítem? Esta acción no se puede deshacer.'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                          onPressed: () async {
                            Navigator.pop(context);
                            Navigator.pop(context);
                            await FirebaseFirestore.instance.collection('items').doc(docId).delete();
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Ítem eliminado correctamente')),
                              );
                            }
                          },
                          child: const Text('Sí, eliminar'),
                        ),
                      ],
                    ),
                  );
                },
              ),
              ElevatedButton(
                child: const Text('Guardar'),
                onPressed: () async {
                  final codigoCBT = cbtCtrl.text.trim().toUpperCase();

                  if (nombreCtrl.text.trim().isEmpty || tipoFinal == null || estado == null || ubicacion == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Por favor completa todos los campos obligatorios')),
                    );
                    return;
                  }

                  if (tiposConSubtipos.containsKey(tipoFinal) && (subtipoFinal?.isEmpty ?? true)) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Selecciona un subtipo')),
                    );
                    return;
                  }

                  if (ubicacion != 'Bodega' && (zona?.isEmpty ?? true)) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Selecciona una zona del carro')),
                    );
                    return;
                  }

                  final duplicado = await FirebaseFirestore.instance
                      .collection('items')
                      .where('codigo_cbt', isEqualTo: codigoCBT)
                      .limit(1)
                      .get();

                  if (duplicado.docs.isNotEmpty && duplicado.docs.first.id != docId) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Ya existe un ítem con ese código CBT')),
                      );
                    }
                    return;
                  }

                  final updates = {
                    'nombre': nombreCtrl.text.trim().toUpperCase(),
                    'codigo_cbt': codigoCBT,
                    'descripcion': descCtrl.text.trim(),
                    'estado': estado,
                    'ubicacion': ubicacion,
                    'zona': ubicacion == 'Bodega' ? null : zona,
                    'tipo': tipoFinal,
                    'subtipo': tiposConSubtipos.containsKey(tipoFinal) ? subtipoFinal : null,
                  };

                  final bytes = await nuevaImagen?.readAsBytes();
                  if (bytes != null) {
                    updates['imagen_base64'] = base64Encode(bytes);
                  }

                  if (nuevoPDF != null) {
                    final pdfName = '${DateTime.now().millisecondsSinceEpoch}.pdf';
                    final ref = FirebaseStorage.instance.ref().child('manuales/$pdfName');
                    await ref.putFile(nuevoPDF!);
                    final pdfUrl = await ref.getDownloadURL();
                    updates['manual_pdf_url'] = pdfUrl;
                  }

                  await FirebaseFirestore.instance.collection('items').doc(docId).update(updates);
                  if (context.mounted) Navigator.pop(context);
                },
              ),
            ],
          );
        },
      ),
    );
  }
}
