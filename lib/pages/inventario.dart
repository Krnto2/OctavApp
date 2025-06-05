import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../widgets/inventario_filter_bar.dart';

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
    "EPP": ["Arnes ERA", "Máscara", "Botella", "Otro"]
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

  final TextEditingController _searchController = TextEditingController();
  String? filtroUbicacion;
  String? filtroZona;
  String? filtroTipo;
  String? filtroSubtipo;
  bool ordenarDescendente = true;

  File? nuevaImagen;
  File? nuevoPDF;

  List<String> getZonasPorUbicacion(String? ubicacion) {
    switch (ubicacion) {
      case "B-8": return zonasB8;
      case "H-8": return zonasH8;
      case "F-8": return zonasF8;
      default: return [];
    }
  }

  Stream<QuerySnapshot> _buildFilteredStream() {
    Query query = FirebaseFirestore.instance.collection('items');

    if (filtroUbicacion?.trim().isNotEmpty ?? false) {
      query = query.where('ubicacion', isEqualTo: filtroUbicacion);
    }
    if (filtroZona?.trim().isNotEmpty ?? false) {
      query = query.where('zona', isEqualTo: filtroZona);
    }
    if (filtroTipo?.trim().isNotEmpty ?? false) {
      query = query.where('tipo', isEqualTo: filtroTipo);
    }
    if (filtroSubtipo?.trim().isNotEmpty ?? false) {
      query = query.where('subtipo', isEqualTo: filtroSubtipo);
    }

    query = query.orderBy('creado', descending: ordenarDescendente);
    return query.snapshots();
  }

  Future<void> _pickImage(bool fromCamera, Function callback) async {
    final picked = await ImagePicker().pickImage(
      source: fromCamera ? ImageSource.camera : ImageSource.gallery,
      imageQuality: 75,
    );
    if (picked != null) {
      setState(() => nuevaImagen = File(picked.path));
      callback();
    }
  }

  @override
  Widget build(BuildContext context) {
    final todosLosTipos = [...tiposConSubtipos.keys, ...tiposSinSubtipos];

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            InventarioFilterBar(
              ubicaciones: ubicacionesDisponibles,
              tipos: todosLosTipos,
              tiposConSubtipos: tiposConSubtipos,
              filtroUbicacion: filtroUbicacion,
              filtroZona: filtroZona,
              filtroTipo: filtroTipo,
              filtroSubtipo: filtroSubtipo,
              ordenarDescendente: ordenarDescendente,
              onUbicacionChanged: (val) {
                setState(() {
                  filtroUbicacion = val;
                  filtroZona = null;
                });
              },
              onZonaChanged: (val) => setState(() => filtroZona = val),
              onTipoChanged: (val) {
                setState(() {
                  filtroTipo = val;
                  filtroSubtipo = null;
                });
              },
              onSubtipoChanged: (val) => setState(() => filtroSubtipo = val),
              onOrdenarChanged: (val) => setState(() => ordenarDescendente = val),
              onBusquedaChanged: (_) => setState(() {}),
              controller: _searchController,
              getZonasPorUbicacion: getZonasPorUbicacion,
              onLimpiarFiltros: () {
                setState(() {
                  filtroUbicacion = null;
                  filtroZona = null;
                  filtroTipo = null;
                  filtroSubtipo = null;
                  _searchController.clear();
                });
              },
            ),
            const SizedBox(height: 10),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _buildFilteredStream(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(child: Text('Error: \${snapshot.error}'));
                  }

                  final busqueda = _searchController.text.trim().toLowerCase();

                  final items = snapshot.data!.docs.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final nombre = data['nombre']?.toString().toLowerCase() ?? '';
                    final codigo = data['codigo_cbt']?.toString().toLowerCase() ?? '';
                    if (busqueda.isEmpty) return true;
                    return nombre.contains(busqueda) || codigo.contains(busqueda);
                  }).toList();

                  if (items.isEmpty) {
                    return const Center(child: Text('No se encontraron ítems.'));
                  }

                  return ListView.builder(
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
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            leading: base64Image != null
                                ? Image.memory(base64Decode(base64Image), height: 50, width: 50, fit: BoxFit.cover)
                                : const Icon(Icons.image, size: 50),
                            title: Text(nombre),
                          subtitle: Text(
                            '$tipo - ${data['ubicacion'] ?? 'Sin ubicación'}'
                            '${(data['zona'] != null && data['zona'].toString().trim().isNotEmpty) ? ' / ${data['zona']}' : ''}',
                          ),

                            trailing: const Icon(Icons.edit, color: Colors.grey),
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

  



  void _abrirDialogoEditar(BuildContext context, Map<String, dynamic> data, String docId) {
    final nombreCtrl = TextEditingController(text: data['nombre']);
    final cbtCtrl = TextEditingController(text: data['codigo_cbt']);
    final descCtrl = TextEditingController(text: data['descripcion']);

    final todosLosTipos = [...tiposConSubtipos.keys, ...tiposSinSubtipos];
    String? tipoFinal = todosLosTipos.firstWhere((t) => t.toLowerCase() == (data['tipo']?.toString().toLowerCase() ?? ''), orElse: () => '');
    tipoFinal = tipoFinal.isEmpty ? null : tipoFinal;
    List<String> subtiposDisponibles = tiposConSubtipos[tipoFinal] ?? [];
    String? subtipoFinal = subtiposDisponibles.firstWhere((s) => s.toLowerCase() == (data['subtipo']?.toString().toLowerCase() ?? ''), orElse: () => '');
    subtipoFinal = subtipoFinal.isEmpty ? null : subtipoFinal;
    String? estado = estadosDisponibles.firstWhere((e) => e.toLowerCase() == (data['estado']?.toString().toLowerCase() ?? ''), orElse: () => '');
    estado = estado.isEmpty ? null : estado;
    String? ubicacion = ubicacionesDisponibles.firstWhere((u) => u.toLowerCase() == (data['ubicacion']?.toString().toLowerCase() ?? ''), orElse: () => '');
    ubicacion = ubicacion.isEmpty ? null : ubicacion;
    String? zona = getZonasPorUbicacion(ubicacion).firstWhere((z) => z.toLowerCase() == (data['zona']?.toString().toLowerCase() ?? ''), orElse: () => '');
    zona = zona.isEmpty ? null : zona;

    bool imagenConfirmada = false;

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
                    onChanged: (val) => setState(() {
                      estado = val;
                      if (val == 'Fuera de servicio') {
                        ubicacion = 'Bodega';
                        zona = null;
                      } else {
                        ubicacion = null;
                      }
                    }),
                  ),

                  DropdownButtonFormField<String>(
                    value: ubicacion,
                    decoration: const InputDecoration(labelText: 'Ubicación'),
                    items: ubicacionesDisponibles.map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
                    onChanged: estado == 'Fuera de servicio' ? null : (val) => setState(() {
                      ubicacion = val;
                      zona = null;
                    }),
                  ),

                  if (estado != 'Fuera de servicio' && ubicacion != null && ubicacion != 'Bodega')
                    DropdownButtonFormField<String>(
                      value: zona,
                      decoration: const InputDecoration(labelText: 'Zona'),
                      items: getZonasPorUbicacion(ubicacion).map((z) => DropdownMenuItem(value: z, child: Text(z))).toList(),
                      onChanged: (val) => setState(() => zona = val),
                    ),

                  const SizedBox(height: 10),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () => _pickImage(true, () => setState(() => imagenConfirmada = true)),
                        icon: const Icon(Icons.camera_alt),
                        label: const Text("Cámara"),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton.icon(
                        onPressed: () => _pickImage(false, () => setState(() => imagenConfirmada = true)),
                        icon: const Icon(Icons.photo),
                        label: const Text("Galería"),
                      ),
                    ],
                  ),

                  if (imagenConfirmada)
                    const Padding(
                      padding: EdgeInsets.only(top: 8.0),
                      child: Icon(Icons.check_circle, color: Colors.green),
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
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(),
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancelar'),
                  ),
                  const SizedBox(width: 20),
                  ElevatedButton(
                    onPressed: () async {
                      final codigoCBT = cbtCtrl.text.trim().toUpperCase();
                      if (nombreCtrl.text.trim().isEmpty || tipoFinal == null || estado == null || ubicacion == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Por favor completa todos los campos obligatorios'),
                            backgroundColor: Colors.red,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                        return;
                      }
                      if (tiposConSubtipos.containsKey(tipoFinal) && (subtipoFinal?.isEmpty ?? true)) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Selecciona un subtipo'),
                            backgroundColor: Colors.red,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                        return;
                      }
                     if (estado != 'Fuera de servicio' && ubicacion != 'Bodega' && (zona?.isEmpty ?? true)) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Selecciona una zona válida del carro'),
                              backgroundColor: Colors.red,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                          return; // ← evita que continúe si hay error
                        }

                      final duplicado = await FirebaseFirestore.instance
                          .collection('items')
                          .where('codigo_cbt', isEqualTo: codigoCBT)
                          .limit(1)
                          .get();

                      if (duplicado.docs.isNotEmpty && duplicado.docs.first.id != docId) {
                        // ignore: use_build_context_synchronously
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Ya existe un ítem con ese código CBT'),
                            backgroundColor: Colors.red,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                        return;
                      }

                      final updates = {
                        'nombre': nombreCtrl.text.trim().toUpperCase(),
                        'codigo_cbt': codigoCBT,
                        'descripcion': descCtrl.text.trim(),
                        'estado': estado,
                        'ubicacion': estado == 'Fuera de servicio' ? 'Bodega' : ubicacion,
                        'zona': estado == 'Fuera de servicio' ? null : zona,
                        'tipo': tipoFinal,
                        'subtipo': tiposConSubtipos.containsKey(tipoFinal) ? subtipoFinal : null,
                      };

                      final bytes = await nuevaImagen?.readAsBytes();
                      if (bytes != null) updates['imagen_base64'] = base64Encode(bytes);

                      if (nuevoPDF != null) {
                        final pdfName = '${DateTime.now().millisecondsSinceEpoch}.pdf';
                        final ref = FirebaseStorage.instance.ref().child('manuales/$pdfName');
                        await ref.putFile(nuevoPDF!);
                        updates['manual_pdf_url'] = await ref.getDownloadURL();
                      }

                      await FirebaseFirestore.instance.collection('items').doc(docId).update(updates);
                      if (context.mounted) Navigator.pop(context);
                    },
                    child: const Text('Guardar'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Center(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.delete),
                  label: const Text('Eliminar ítem'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
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
              ),
            ],
          );
        },
      ),
    );
  }
}
