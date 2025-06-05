import 'package:flutter/material.dart';
import '../widgets/universal_app_bar.dart';

class F8Page extends StatelessWidget {
  const F8Page({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const UniversalAppBar(titulo: 'Carro F-8'),
      body: const Center(
        child: Text(
          'Contenido del Carro F-8',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
