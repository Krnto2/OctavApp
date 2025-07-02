import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CustomNavigationBar extends StatelessWidget {
  final int selectedIndex;
  final bool isAdmin;
  final bool isSuperAdmin;
  final String userEmail;
  final void Function(int) onSelect;

  const CustomNavigationBar({
    super.key,
    required this.selectedIndex,
    required this.isAdmin,
    required this.isSuperAdmin,
    required this.userEmail,
    required this.onSelect,
  });

  // ✅ Función para contar los anuncios no vistos
  Stream<int> contarAnunciosNoVistos(String userEmail) {
    return FirebaseFirestore.instance.collection('anuncios').snapshots().map((snapshot) {
      int count = 0;
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final List<dynamic>? vistos = data['vistoPor'];

        if (vistos == null || !vistos.contains(userEmail)) {
          count++;
        }
      }
      return count;
    });
  }

  @override
  Widget build(BuildContext context) {
    return NavigationRail(
      selectedIndex: selectedIndex,
      onDestinationSelected: onSelect,
      labelType: NavigationRailLabelType.selected,
      leading: Column(
        children: [
          const SizedBox(height: 24),
          if (isAdmin || isSuperAdmin) ...[
            const SizedBox(height: 10),
            const Tooltip(
              message: 'Modo Administrador',
              child: Icon(Icons.security, color: Colors.red, size: 30),
            ),
          ],
        ],
      ),
      destinations: [
        const NavigationRailDestination(
          icon: Icon(Icons.fire_truck_outlined),
          selectedIcon: Icon(Icons.fire_truck),
          label: Text('Carros'),
        ),
        const NavigationRailDestination(
          icon: Icon(Icons.inventory_2_outlined),
          selectedIcon: Icon(Icons.inventory),
          label: Text('Inventario'),
        ),
        NavigationRailDestination(
          icon: StreamBuilder<int>(
            stream: contarAnunciosNoVistos(userEmail),
            builder: (context, snapshot) {
              final cantidad = snapshot.data ?? 0;
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  const Icon(Icons.notifications_none),
                  if (cantidad > 0)
                    Positioned(
                      right: -6,
                      top: -6,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                        child: Text(
                          cantidad > 9 ? '9+' : '$cantidad',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          selectedIcon: const Icon(Icons.notifications),
          label: const Text('Anuncios'),
        ),
        if (isAdmin)
          const NavigationRailDestination(
            icon: Icon(Icons.add_box_outlined),
            selectedIcon: Icon(Icons.add_box),
            label: Text('Añadir'),
          ),
        if (isSuperAdmin)
          const NavigationRailDestination(
            icon: Icon(Icons.group_outlined),
            selectedIcon: Icon(Icons.group),
            label: Text('Usuarios'),
          ),
        const NavigationRailDestination(
          icon: Icon(Icons.settings_outlined),
          selectedIcon: Icon(Icons.settings),
          label: Text('Config.'),
        ),
        const NavigationRailDestination(
          icon: Icon(Icons.logout),
          selectedIcon: Icon(Icons.logout),
          label: Text('Salir'),
        ),
      ],
    );
  }
}
