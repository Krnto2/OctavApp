import 'package:flutter/material.dart';
import '../widgets/universal_app_bar.dart';
import '../widgets/add_item.dart';

class AddPage extends StatelessWidget {
  const AddPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      appBar: UniversalAppBar(titulo: 'Agregar nuevo ítem'),
      body: SafeArea(
        child: AddItemWidget(),
      ),
    );
  }
}
