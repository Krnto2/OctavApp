import 'package:flutter/material.dart';
import 'ver.dart';

class B8Page extends StatelessWidget {
  const B8Page({super.key});

  void _irAVer(BuildContext context, String nombreZona) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => VerPage(
          cajoneraNombre: nombreZona,
          ubicacion: "B-8", // Ubicación fija para este carro
        ),
      ),
    );
  }

  Widget _imagenConZonas({
    required BuildContext context,
    required String imagePath,
    required List<_ZonaInteractiva> zonas,
    double? width,
    double? height,
  }) {
    return SizedBox(
      width: width ?? 400,
      height: height ?? 180,
      child: Stack(
        children: [
          Image.asset(imagePath, fit: BoxFit.contain),
          for (final zona in zonas)
            Positioned(
              top: zona.top,
              left: zona.left,
              child: GestureDetector(
                onTap: () => _irAVer(context, zona.nombre),
                child: Container(
                  width: zona.width,
                  height: zona.height,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    // color: const Color.fromARGB(255, 85, 119, 233).withOpacity(0.3), // Para debug visual
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Carro B-8')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _imagenConZonas(
              context: context,
              imagePath: 'assets/images/ladob8.png',
              zonas: [
                _ZonaInteractiva(nombre: 'CABINA', top: 20, left: 30, width: 95, height: 76),
                _ZonaInteractiva(nombre: 'CAJONERA 1', top: 30, left: 178, width: 50, height: 80),
                _ZonaInteractiva(nombre: 'CAJONERA 2', top: 30, left: 230, width: 70, height: 38),
                _ZonaInteractiva(nombre: 'CAJONERA 3', top: 30, left: 300, width: 60, height: 76),
                _ZonaInteractiva(nombre: 'BOMBA', top: 30, left: 130, width: 45, height: 76),
              ],
            ),
            const SizedBox(height: 20),
            _imagenConZonas(
              context: context,
              imagePath: 'assets/images/volteadob8.png',
              zonas: [
                _ZonaInteractiva(nombre: 'BOMBA', top: 30, left: 200, width: 45, height: 76),
                _ZonaInteractiva(nombre: 'CAJONERA 6', top: 30, left: 80, width: 70, height: 38),
                _ZonaInteractiva(nombre: 'CAJONERA 5', top: 30, left: 20, width: 60, height: 76),
                _ZonaInteractiva(nombre: 'CAJONERA 7', top: 30, left: 148, width: 56, height: 80),
                _ZonaInteractiva(nombre: 'CABINA', top: 20, left: 250, width: 95, height: 76),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: _imagenConZonas(
                    context: context,
                    imagePath: 'assets/images/frenteb8.png',
                    zonas: [
                      _ZonaInteractiva(nombre: 'CABINA', top: 20, left: 30, width: 130, height: 120),
                    ],
                    width: null,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _imagenConZonas(
                    context: context,
                    imagePath: 'assets/images/atrasb8.png',
                    zonas: [
                      _ZonaInteractiva(nombre: 'CAJONERA 4', top: 30, left: 30, width: 120, height: 120),
                    ],
                    width: null,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ZonaInteractiva {
  final String nombre;
  final double top;
  final double left;
  final double width;
  final double height;

  _ZonaInteractiva({
    required this.nombre,
    required this.top,
    required this.left,
    this.width = 60,
    this.height = 30,
  });
}
