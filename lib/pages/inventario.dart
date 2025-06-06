import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/inventario_filter_bar.dart';
import '../widgets/item_resumen.dart';
import '../widgets/editar_item.dart';

class InventarioView extends StatefulWidget {
  const InventarioView({super.key});

  @override
  State<InventarioView> createState() => _InventarioViewState();
}

class _InventarioViewState extends State<InventarioView> {
  final estadosDisponibles = ['Operativo', 'Fuera de servicio'];
  final todasLasUbicaciones = ['Bodega', 'B-8', 'H-8', 'F-8'];
  List<String> ubicacionesDisponibles = [];

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
  String? rolUsuario;

  @override
  void initState() {
    super.initState();
    _obtenerRolUsuario();
  }

  Future<void> _obtenerRolUsuario() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('usuarios').doc(user.uid).get();
      setState(() {
        rolUsuario = doc['rol'];
        ubicacionesDisponibles = rolUsuario == 'bombero'
            ? todasLasUbicaciones.where((u) => u != 'Bodega').toList()
            : List.from(todasLasUbicaciones);
      });
    }
  }

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
    if (rolUsuario == 'bombero') {
      query = query.where('ubicacion', isNotEqualTo: 'Bodega');
    }
    if (filtroUbicacion?.trim().isNotEmpty ?? false) query = query.where('ubicacion', isEqualTo: filtroUbicacion);
    if (filtroZona?.trim().isNotEmpty ?? false) query = query.where('zona', isEqualTo: filtroZona);
    if (filtroTipo?.trim().isNotEmpty ?? false) query = query.where('tipo', isEqualTo: filtroTipo);
    if (filtroSubtipo?.trim().isNotEmpty ?? false) query = query.where('subtipo', isEqualTo: filtroSubtipo);
    return query.orderBy('creado', descending: ordenarDescendente).snapshots();
  }

  @override
  Widget build(BuildContext context) {
    if (rolUsuario == null) return const Center(child: CircularProgressIndicator());
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
              onUbicacionChanged: (val) => setState(() { filtroUbicacion = val; filtroZona = null; }),
              onZonaChanged: (val) => setState(() => filtroZona = val),
              onTipoChanged: (val) => setState(() { filtroTipo = val; filtroSubtipo = null; }),
              onSubtipoChanged: (val) => setState(() => filtroSubtipo = val),
              onOrdenarChanged: (val) => setState(() => ordenarDescendente = val),
              onBusquedaChanged: (_) => setState(() {}),
              controller: _searchController,
              getZonasPorUbicacion: getZonasPorUbicacion,
              onLimpiarFiltros: () => setState(() {
                filtroUbicacion = null;
                filtroZona = null;
                filtroTipo = null;
                filtroSubtipo = null;
                _searchController.clear();
              }),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _buildFilteredStream(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                  if (snapshot.hasError) return Center(child: Text('Error: \${snapshot.error}'));

                  final busqueda = _searchController.text.trim().toLowerCase();
                  final items = snapshot.data!.docs.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final nombre = data['nombre']?.toString().toLowerCase() ?? '';
                    final codigo = data['codigo_cbt']?.toString().toLowerCase() ?? '';
                    return busqueda.isEmpty || nombre.contains(busqueda) || codigo.contains(busqueda);
                  }).toList();

                  if (items.isEmpty) return const Center(child: Text('No se encontraron ítems.'));

                  return ListView.builder(
                    itemCount: items.length,
                    itemBuilder: (_, index) {
                      final data = items[index].data() as Map<String, dynamic>;
                      final docId = items[index].id;
                      final nombre = data['nombre'] ?? 'Sin nombre';
                      final tipo = data['tipo'] ?? 'Tipo desconocido';
                      final base64Image = data['imagen_base64'];

                      return GestureDetector(
                        onTap: () => rolUsuario == 'bombero'
                            ? showDialog(context: context, builder: (_) => ItemResumenWidget(data: data))
                            : showDialog(
                                context: context,
                                builder: (_) => EditarItemWidget(
                                  data: data,
                                  docId: docId,
                                  estados: estadosDisponibles,
                                  ubicaciones: ubicacionesDisponibles,
                                  tiposSinSub: tiposSinSubtipos,
                                  tiposConSub: tiposConSubtipos,
                                  zonas: getZonasPorUbicacion(data['ubicacion']),
                                  getZonas: getZonasPorUbicacion,
                                  onPickImage: (img) => setState(() => nuevaImagen = img),
                                  nuevaImagen: nuevaImagen,
                                ),
                              ),
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

                            trailing: (rolUsuario == 'superadmin' || rolUsuario == 'admin')
                                ? const Icon(Icons.edit, color: Colors.grey)
                                : null,
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
}
