import 'package:flutter/material.dart';
import '../widgets/universal_app_bar.dart';

class H8Page extends StatelessWidget {
  const H8Page({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const UniversalAppBar(titulo: 'Carro H-8'),
      body: const Center(
        child: Text('Contenido del Carro H-8'),
      ),
    );
  }
}