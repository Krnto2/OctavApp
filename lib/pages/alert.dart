import 'package:flutter/material.dart';
import '../widgets/add_anuncio.dart';
import '../widgets/ver_anuncio.dart';

class AlertView extends StatelessWidget {
  final bool isAdmin;
  const AlertView({super.key, required this.isAdmin});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: VerAnuncios(
        isAdmin: isAdmin,
        onAddPressed: () => showDialog(
          context: context,
          builder: (context) => const AddAnuncioDialog(),
        ),
      ),
    );
  }
}
