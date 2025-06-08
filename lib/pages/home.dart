import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'b8.dart';
import 'h8.dart';
import 'f8.dart';
import 'add.dart';
import 'inventario.dart';
import 'usuario.dart';
import 'alert.dart'; 
import '../widgets/universal_app_bar.dart';

class HomePage extends StatefulWidget {
  final Function(bool) onToggleTheme;
  final bool isDarkMode;
  final void Function(BuildContext)? onLogout;

  const HomePage({
    super.key,
    required this.onToggleTheme,
    required this.isDarkMode,
    this.onLogout,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  late String _userEmail;
  String? _rolUsuario;

  bool get isAdmin => _rolUsuario == 'admin' || _rolUsuario == 'superadmin';
  bool get isSuperAdmin => _rolUsuario == 'superadmin';

  @override
  void initState() {
    super.initState();
    _userEmail = FirebaseAuth.instance.currentUser?.email ?? 'usuario@cbt.cl';
    _obtenerRol();
  }

  void _obtenerRol() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('usuarios').doc(user.uid).get();
      if (doc.exists) {
        setState(() {
          _rolUsuario = doc['rol'];
        });
      }
    }
  }

  List<Widget> get _views {
    final views = [
      CarrosView(email: _userEmail, isDarkMode: widget.isDarkMode),
      const InventarioView(),
      AlertView(isAdmin: isAdmin),
    ];

    if (isAdmin) views.add(const ReportesView());
    if (isSuperAdmin) views.add(const UsuarioView());

    views.add(SettingsView(
      isDarkMode: widget.isDarkMode,
      onToggleTheme: widget.onToggleTheme,
    ));
    views.add(const Center(child: Text('Saliendo...')));
    return views;
  }

  List<String> get _titles {
    final titles = ['Carros', 'Inventario', 'Anuncios'];
    if (isAdmin) titles.add('Añadir');
    if (isSuperAdmin) titles.add('Usuarios');
    titles.add('Configuración');
    titles.add('Saliendo...');
    return titles;
  }

  void _handleNavigation(int index) {
    final isLogoutIndex = index == _titles.length - 1;
    if (isLogoutIndex && widget.onLogout != null) {
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
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              widget.onLogout!(context);
            },
            icon: const Icon(Icons.logout),
            label: const Text('Cerrar sesión'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color.fromARGB(255, 238, 138, 130),
            ),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_rolUsuario == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: widget.isDarkMode ? const Color(0xFF121212) : null,
      appBar: (_selectedIndex != _titles.length - 1)
          ? UniversalAppBar(titulo: _titles[_selectedIndex])
          : null,
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: _selectedIndex,
            onDestinationSelected: _handleNavigation,
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
              const NavigationRailDestination(
                icon: Icon(Icons.notifications_none),
                selectedIcon: Icon(Icons.notifications),
                label: Text('Anuncios'),
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
          ),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(child: _views[_selectedIndex]),
        ],
      ),
    );
  }
}


class CarrosView extends StatelessWidget {
  final String email;
  final bool isDarkMode;
  const CarrosView({super.key, required this.email, required this.isDarkMode});

  String getNombreDesdeCorreo(String correo) {
    final parte = correo.split('@').first;
    final nombre = parte.split('.').first;
    return nombre.isNotEmpty
        ? nombre[0].toUpperCase() + nombre.substring(1)
        : 'Bombero';
  }

  void _navigateToCarro(BuildContext context, String nombreCarro) {
    Widget page;

    switch (nombreCarro) {
      case 'B-8':
        page = const B8Page();
        break;
      case 'H-8':
        page = const H8Page();
        break;
      case 'F-8':
        page = const F8Page();
        break;
      default:
        page = Scaffold(
          appBar: AppBar(title: const Text('Carro no encontrado')),
          body: const Center(child: Text('No se encontró la página para este carro.')),
        );
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => page),
    );
  }

  @override
  Widget build(BuildContext context) {
    final nombre = getNombreDesdeCorreo(email);
    final carros = [
      {'nombre': 'B-8', 'imagen': 'assets/images/b8.png'},
      {'nombre': 'H-8', 'imagen': 'assets/images/h8.png'},
      {'nombre': 'F-8', 'imagen': 'assets/images/f8.png'},
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 25),
          Text(
            '¡Hola, $nombre!',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 15),
          Expanded(
            child: ListView.builder(
              itemCount: carros.length,
              itemBuilder: (context, index) {
                final carro = carros[index];
                return GestureDetector(
                  onTap: () => _navigateToCarro(context, carro['nombre']!),
                  child: Card(
                    elevation: 4,
                    margin: const EdgeInsets.only(bottom: 20),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                          child: Image.asset(
                            carro['imagen']!,
                            height: 140,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Text(
                            carro['nombre']!,
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class ReportesView extends StatelessWidget {
  const ReportesView({super.key});
@override
  Widget build(BuildContext context) {
    return Scaffold(
  backgroundColor: Theme.of(context).scaffoldBackgroundColor,
  body: Padding(
    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 100),
        Icon(Icons.inventory_2, size: 80, color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: 24),
        Text(
          'Añadir nuevo ítem',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Text(
          'Presiona el botón para registrar un nuevo ítem en el inventario puedes ingresar detalles como nombre, tipo, ubicación y más.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 40),
        ElevatedButton.icon(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddPage()),
          ),
          icon: const Icon(Icons.add, color: Colors.white),
          label: const Text('Añadir ítem', style: TextStyle(fontSize: 18, color: Colors.white)),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
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
    return Column(
      children: [
        Expanded(
          child: Center(
            child: SwitchListTile(
              title: const Text('Modo oscuro'),
              value: isDarkMode,
              onChanged: (bool value) {
                onToggleTheme(value);
              },
              secondary: const Icon(Icons.dark_mode),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Opacity(
            opacity: 0.4,
            child: Text(
              '© 2025 Renato Pomeri · Todos los derechos reservados',
              style: TextStyle(
                fontSize: 12,
                fontStyle: FontStyle.italic,
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ],
    );
  }
}
