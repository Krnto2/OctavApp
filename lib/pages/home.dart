import 'package:flutter/material.dart';

class HomePage extends StatefulWidget {
  final Function(bool) onToggleTheme;
  final bool isDarkMode;
  final bool isAdmin;
  final void Function(BuildContext)? onLogout;

  const HomePage({
    super.key,
    required this.onToggleTheme,
    required this.isDarkMode,
    required this.isAdmin,
    this.onLogout,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  List<Widget> get _views => [
        const CarrosView(),
        const Center(child: Text('Inventario')),
        const Center(child: Text('Reportes')),
        SettingsView(
          isDarkMode: widget.isDarkMode,
          onToggleTheme: widget.onToggleTheme,
        ),
        const Center(child: Text('Saliendo...')), // Placeholder
      ];

  void _handleNavigation(int index) {
    if (index == 4 && widget.onLogout != null) {
      _confirmLogout(context);
    } else {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('¿Cerrar sesión?'),
        content: const Text('¿Estás seguro de que deseas cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context); // cerrar el diálogo
              widget.onLogout!(context); // ejecutar logout
            },
            icon: const Icon(Icons.logout),
            label: const Text('Cerrar sesión'),
            style: ElevatedButton.styleFrom(backgroundColor: const Color.fromARGB(255, 238, 138, 130)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: _selectedIndex,
            onDestinationSelected: _handleNavigation,
            labelType: NavigationRailLabelType.selected,
            leading: Column(
              children: [
                const SizedBox(height: 24),
                const Icon(Icons.home, size: 32),
                if (widget.isAdmin) ...[
                  const SizedBox(height: 20),
                  const Tooltip(
                    message: 'Modo Administrador',
                    child: Icon(Icons.security, color: Colors.red, size: 30),
                  ),
                ],
              ],
            ),
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.fire_truck_outlined),
                selectedIcon: Icon(Icons.fire_truck),
                label: Text('Carros'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.inventory_2_outlined),
                selectedIcon: Icon(Icons.inventory),
                label: Text('Inventario'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.bar_chart_outlined),
                selectedIcon: Icon(Icons.bar_chart),
                label: Text('Reportes'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.settings_outlined),
                selectedIcon: Icon(Icons.settings),
                label: Text('Config.'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.logout),
                selectedIcon: Icon(Icons.logout),
                label: Text('Salir'),
              ),
            ],
          ),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(
            child: _views[_selectedIndex],
          ),
        ],
      ),
    );
  }
}

// CarrosView, DetalleCarroPage, and SettingsView remain unchanged


class CarrosView extends StatelessWidget {
  const CarrosView({super.key});

  void _navigateToCarro(BuildContext context, String nombreCarro) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DetalleCarroPage(nombreCarro: nombreCarro),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final carros = [
      {'nombre': 'B-8', 'imagen': 'assets/images/b8.png'},
      {'nombre': 'H-8', 'imagen': 'assets/images/h8.png'},
      {'nombre': 'F-8', 'imagen': 'assets/images/f8.png'},
    ];

    return Center(
      child: SizedBox(
        width: 600,
        child: GridView.count(
          shrinkWrap: true,
          crossAxisCount: 1,
          childAspectRatio: 2,
          mainAxisSpacing: 20,
          children: carros.map((carro) {
            return GestureDetector(
              onTap: () => _navigateToCarro(context, carro['nombre']!),
              child: Card(
                elevation: 4,
                child: Column(
                  children: [
                    Expanded(
                      child: Image.asset(
                        carro['imagen']!,
                        fit: BoxFit.cover,
                        width: double.infinity,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        carro['nombre']!,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class DetalleCarroPage extends StatelessWidget {
  final String nombreCarro;

  const DetalleCarroPage({super.key, required this.nombreCarro});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(nombreCarro),
      ),
      body: const Center(
        child: Text('Secciones del carro aquí'),
      ),
    );
  }
}

class SettingsView extends StatelessWidget {
  final bool isDarkMode;
  final Function(bool) onToggleTheme;

  const SettingsView({
    super.key,
    required this.isDarkMode,
    required this.onToggleTheme,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SwitchListTile(
        title: const Text('Modo oscuro'),
        value: isDarkMode,
        onChanged: (bool value) {
          onToggleTheme(value);
        },
        secondary: const Icon(Icons.dark_mode),
      ),
    );
  }
}
