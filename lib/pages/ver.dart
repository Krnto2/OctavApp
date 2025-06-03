import 'package:flutter/material.dart';

class VerPage extends StatelessWidget {
  final String cajoneraNombre;
  final List<String> items;

  const VerPage({
    super.key,
    required this.cajoneraNombre,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Contenido: $cajoneraNombre')),
      body: items.isEmpty
          ? const Center(child: Text('Sin ítems registrados.'))
          : ListView.builder(
              itemCount: items.length,
              itemBuilder: (_, index) => ListTile(
                leading: const Icon(Icons.check),
                title: Text(items[index]),
              ),
            ),
    );
  }
}
