import 'package:flutter/material.dart';
import '../screens/servicios_screen.dart';
import '../screens/turnos_screen.dart';
import '../screens/turnos_publicos_screen.dart';
import '../screens/caja_screen.dart';

// 🎨 Paleta alineada a la app
const rosaPrincipal = Color(0xFFF2A1C6);
const rosaSuave = Color(0xFFFFF1F6);

class AppDrawer extends StatelessWidget {
  final String current;

  const AppDrawer({
    super.key,
    required this.current,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.white,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // =====================
            // 🌸 HEADER
            // =====================
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    rosaPrincipal,
                    Color(0xFFF7B6D2),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Icon(
                    Icons.spa_outlined,
                    color: Colors.white,
                    size: 36,
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Julieta Studio',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Gestión de turnos',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // =====================
            // 🔒 ADMINISTRACIÓN
            // =====================
            _sectionTitle('Administración'),

            _drawerItem(
              context,
              icon: Icons.medical_services_outlined,
              label: 'Servicios',
              selected: current == 'servicios',
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ServiciosScreen(),
                  ),
                );
              },
            ),

            _drawerItem(
              context,
              icon: Icons.event_note_outlined,
              label: 'Turnos',
              selected: current == 'turnos',
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const TurnosScreen(),
                  ),
                );
              },
            ),

            // ✅ CAJA
            _drawerItem(
              context,
              icon: Icons.point_of_sale_outlined,
              label: 'Caja',
              selected: current == 'caja',
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const CajaScreen(),
                  ),
                );
              },
            ),

            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Divider(),
            ),

            // =====================
            // 🌐 CLIENTES
            // =====================
            _sectionTitle('Clientes'),

            _drawerItem(
              context,
              icon: Icons.calendar_today_outlined,
              label: 'Sacar turno',
              selected: current == 'publico',
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const TurnosPublicosScreen(),
                  ),
                );
              },
            ),

            const Spacer(),

            // =====================
            // FOOTER
            // =====================
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                '© ${DateTime.now().year} Julieta Studio',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =====================
  // 🔠 TÍTULO SECCIÓN
  // =====================
  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 1,
          color: Colors.grey,
        ),
      ),
    );
  }

  // =====================
  // 📄 ITEM DRAWER
  // =====================
  Widget _drawerItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Material(
        color: selected ? rosaPrincipal.withOpacity(0.12) : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: ListTile(
          leading: Icon(
            icon,
            color: selected ? rosaPrincipal : Colors.grey[700],
          ),
          title: Text(
            label,
            style: TextStyle(
              fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
              color: selected ? rosaPrincipal : Colors.grey[800],
            ),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          onTap: onTap,
        ),
      ),
    );
  }
}
