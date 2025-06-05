
import 'package:flutter/material.dart';

class InventarioFilterBar extends StatelessWidget {
  final List<String> ubicaciones;
  final List<String> tipos;
  final Map<String, List<String>> tiposConSubtipos;
  final String? filtroUbicacion;
  final String? filtroZona;
  final String? filtroTipo;
  final String? filtroSubtipo;
  final bool ordenarDescendente;
  final Function(String?) onUbicacionChanged;
  final Function(String?) onZonaChanged;
  final Function(String?) onTipoChanged;
  final Function(String?) onSubtipoChanged;
  final Function(bool) onOrdenarChanged;
  final Function(String) onBusquedaChanged;
  final TextEditingController controller;

  final List<String> Function(String?) getZonasPorUbicacion;

  const InventarioFilterBar({
    super.key,
    required this.ubicaciones,
    required this.tipos,
    required this.tiposConSubtipos,
    required this.filtroUbicacion,
    required this.filtroZona,
    required this.filtroTipo,
    required this.filtroSubtipo,
    required this.ordenarDescendente,
    required this.onUbicacionChanged,
    required this.onZonaChanged,
    required this.onTipoChanged,
    required this.onSubtipoChanged,
    required this.onOrdenarChanged,
    required this.onBusquedaChanged,
    required this.controller,
    required this.getZonasPorUbicacion,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Buscar por nombre o código CBT'),
          onChanged: onBusquedaChanged,
        ),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            DropdownButton<String>(
              value: filtroUbicacion,
              hint: const Text("Ubicación"),
              items: ubicaciones.map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
              onChanged: onUbicacionChanged,
            ),
            if (filtroUbicacion != null && filtroUbicacion != "Bodega")
              DropdownButton<String>(
                value: filtroZona,
                hint: const Text("Zona"),
                items: getZonasPorUbicacion(filtroUbicacion).map((z) => DropdownMenuItem(value: z, child: Text(z))).toList(),
                onChanged: onZonaChanged,
              ),
            DropdownButton<String>(
              value: filtroTipo,
              hint: const Text("Tipo"),
              items: tipos.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
              onChanged: onTipoChanged,
            ),
            if (filtroTipo != null && tiposConSubtipos.containsKey(filtroTipo))
              DropdownButton<String>(
                value: filtroSubtipo,
                hint: const Text("Subtipo"),
                items: tiposConSubtipos[filtroTipo]!.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                onChanged: onSubtipoChanged,
              ),
            ElevatedButton.icon(
              icon: const Icon(Icons.swap_vert),
              label: const Text("Invertir orden"),
              onPressed: () => onOrdenarChanged(!ordenarDescendente),
            ),
          ],
        ),
      ],
    );
  }
}
