import 'package:flutter/material.dart';

class UniversalAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String titulo;

  const UniversalAppBar({super.key, required this.titulo});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: const Color.fromARGB(255, 236, 46, 46),
      title: Text(
        titulo,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      centerTitle: true,
      elevation: 2,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
