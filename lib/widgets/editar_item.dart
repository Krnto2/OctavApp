// ignore_for_file: use_build_context_synchronously

import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

extension Normalize on String {
  String normalize() {
    return toLowerCase()
        .replaceAll(RegExp(r'[\u00C0-\u00C5]'), 'a')
        .replaceAll(RegExp(r'[\u00C8-\u00CB]'), 'e')
        .replaceAll(RegExp(r'[\u00CC-\u00CF]'), 'i')
        .replaceAll(RegExp(r'[\u00D2-\u00D6]'), 'o')
        .replaceAll(RegExp(r'[\u00D9-\u00DC]'), 'u')
        .trim();
  }
}

class EditarItemWidget extends StatefulWidget {
  final Map<String, dynamic> data;
  final String docId;
  final List<String> estados;
  final List<String> ubicaciones;
  final List<String> tiposSinSub;
  final Map<String, List<String>> tiposConSub;
  final List<String> zonas;
  final List<String> Function(String?) getZonas;
  final Function(File?) onPickImage;
  final File? nuevaImagen;

  const EditarItemWidget({
    super.key,
    required this.data,
    required this.docId,
    required this.estados,
    required this.ubicaciones,
    required this.tiposSinSub,
    required this.tiposConSub,
    required this.zonas,
    required this.getZonas,
    required this.onPickImage,
    this.nuevaImagen,
  });

  @override
  State<EditarItemWidget> createState() => _EditarItemWidgetState();
}

class _EditarItemWidgetState extends State<EditarItemWidget> {
  late TextEditingController nombreCtrl;
  late TextEditingController cbtCtrl;
  late TextEditingController descCtrl;

  String? tipoFinal;
  String? subtipoFinal;
  String? estado;
  String? ubicacion;
  String? zona;
  File? nuevoPDF;
  bool imagenConfirmada = false;

  @override
  void initState() {
    super.initState();
    nombreCtrl = TextEditingController(text: widget.data['nombre']);
    cbtCtrl = TextEditingController(text: widget.data['codigo_cbt']);
    descCtrl = TextEditingController(text: widget.data['descripcion']);

    final tiposTodos = [...widget.tiposConSub.keys, ...widget.tiposSinSub];
    final tipoRaw = widget.data['tipo']?.toString().normalize() ?? '';
    tipoFinal = tiposTodos.firstWhere(
      (t) => t.normalize() == tipoRaw,
      orElse: () => '',
    );
    tipoFinal = tipoFinal!.isEmpty ? null : tipoFinal;

    final subtiposDisponibles = widget.tiposConSub[tipoFinal] ?? [];
    final subtipoRaw = widget.data['subtipo']?.toString().normalize() ?? '';
    subtipoFinal = subtiposDisponibles.firstWhere(
      (s) => s.normalize() == subtipoRaw,
      orElse: () => '',
    );
    subtipoFinal = subtipoFinal!.isEmpty ? null : subtipoFinal;

    estado = widget.estados.firstWhere(
      (e) => e.normalize() == (widget.data['estado']?.toString().normalize() ?? ''),
      orElse: () => '',
    );
    estado = estado!.isEmpty ? null : estado;

    ubicacion = widget.ubicaciones.firstWhere(
      (u) => u.normalize() == (widget.data['ubicacion']?.toString().normalize() ?? ''),
      orElse: () => '',
    );
    ubicacion = ubicacion!.isEmpty ? null : ubicacion;

    zona = widget.getZonas(ubicacion).firstWhere(
      (z) => z.normalize() == (widget.data['zona']?.toString().normalize() ?? ''),
      orElse: () => '',
    );
    zona = zona!.isEmpty ? null : zona;
  }

  Future<void> _confirmarEliminacion() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: const Text(
          '¿Estás seguro de que deseas eliminar este ítem del inventario? Esta acción no se puede deshacer.',
        ),
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
      await FirebaseFirestore.instance.collection('items').doc(widget.docId).delete();
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ítem eliminado correctamente'), backgroundColor: Colors.green),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    final subtipos = widget.tiposConSub[tipoFinal] ?? [];
    final zonasActuales = widget.getZonas(ubicacion);

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
              items: [...widget.tiposConSub.keys, ...widget.tiposSinSub]
                  .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                  .toList(),
              onChanged: (val) => setState(() {
                tipoFinal = val;
                subtipoFinal = null;
              }),
            ),

            if (tipoFinal != null && widget.tiposConSub.containsKey(tipoFinal))
              DropdownButtonFormField<String>(
                value: subtipoFinal,
                decoration: const InputDecoration(labelText: 'Subtipo'),
                items: subtipos.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                onChanged: (val) => setState(() => subtipoFinal = val),
              ),

            DropdownButtonFormField<String>(
              value: estado,
              decoration: const InputDecoration(labelText: 'Estado'),
              items: widget.estados.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
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
              items: widget.ubicaciones.map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
              onChanged: estado == 'Fuera de servicio' ? null : (val) => setState(() {
                ubicacion = val;
                zona = null;
              }),
            ),

            if (estado != 'Fuera de servicio' && ubicacion != null && ubicacion != 'Bodega')
              DropdownButtonFormField<String>(
                value: zona,
                decoration: const InputDecoration(labelText: 'Zona'),
                items: zonasActuales.map((z) => DropdownMenuItem(value: z, child: Text(z))).toList(),
                onChanged: (val) => setState(() => zona = val),
              ),

            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: () async {
                    final picked = await ImagePicker().pickImage(source: ImageSource.camera, imageQuality: 75);
                    if (picked != null) {
                      widget.onPickImage(File(picked.path));
                      setState(() => imagenConfirmada = true);
                    }
                  },
                  icon: const Icon(Icons.camera_alt),
                  label: const Text("Cámara"),
                ),
                const SizedBox(width: 10),
                ElevatedButton.icon(
                  onPressed: () async {
                    final picked = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 75);
                    if (picked != null) {
                      widget.onPickImage(File(picked.path));
                      setState(() => imagenConfirmada = true);
                    }
                  },
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
  if (ubicacion == 'Bodega')
  Center(
    child: ElevatedButton(
      onPressed: _confirmarEliminacion,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
      child: const Text('Eliminar ítem'),
    ),
  ),


        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            const SizedBox(width: 20),
            ElevatedButton(
              onPressed: () async {
                final codigoCBT = cbtCtrl.text.trim().toUpperCase();
                final nombre = nombreCtrl.text.trim().toUpperCase();
                final messenger = ScaffoldMessenger.of(context);

                if (nombre.isEmpty || tipoFinal == null || estado == null || ubicacion == null ||
                    (widget.tiposConSub.containsKey(tipoFinal) && (subtipoFinal?.isEmpty ?? true)) ||
                    (estado != 'Fuera de servicio' && ubicacion != 'Bodega' && (zona?.isEmpty ?? true))) {
                  messenger.showSnackBar(
                    const SnackBar(content: Text('Completa los campos obligatorios'), backgroundColor: Colors.red),
                  );
                  return;
                }

                final duplicado = await FirebaseFirestore.instance
                    .collection('items')
                    .where('codigo_cbt', isEqualTo: codigoCBT)
                    .limit(1)
                    .get();

                if (duplicado.docs.isNotEmpty && duplicado.docs.first.id != widget.docId) {
                  if (!mounted) return;
                  messenger.showSnackBar(
                    const SnackBar(content: Text('Ya existe un ítem con ese código CBT'), backgroundColor: Colors.red),
                  );
                  return;
                }

                final updates = {
                  'nombre': nombre,
                  'codigo_cbt': codigoCBT,
                  'descripcion': descCtrl.text.trim(),
                  'estado': estado,
                  'ubicacion': estado == 'Fuera de servicio' ? 'Bodega' : ubicacion,
                  'zona': estado == 'Fuera de servicio' ? null : zona,
                  'tipo': tipoFinal,
                  'subtipo': widget.tiposConSub.containsKey(tipoFinal) ? subtipoFinal : null,
                };

                final bytes = await widget.nuevaImagen?.readAsBytes();
                if (bytes != null) updates['imagen_base64'] = base64Encode(bytes);

                if (nuevoPDF != null) {
                  final pdfName = '${DateTime.now().millisecondsSinceEpoch}.pdf';
                  final ref = FirebaseStorage.instance.ref().child('manuales/$pdfName');
                  await ref.putFile(nuevoPDF!);
                  updates['manual_pdf_url'] = await ref.getDownloadURL();
                }
                
                await FirebaseFirestore.instance.collection('items').doc(widget.docId).update(updates);
                if (mounted) Navigator.pop(context);
              },
              child: const Text('Guardar'),
            ),
          ],
        ),
      ],
    );
  }
}
