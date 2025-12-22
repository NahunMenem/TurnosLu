import 'package:flutter/material.dart';
import '../models/servicio.dart';
import '../services/api_service.dart';
import '../widgets/app_drawer.dart';
import 'disponibilidad_publica_screen.dart';

// 🎨 Paleta app
const rosaPrincipal = Color(0xFFF2A1C6);
const rosaSuave = Color(0xFFFFF1F6);
const grisTexto = Color(0xFF4A4A4A);

class TurnosPublicosScreen extends StatefulWidget {
  const TurnosPublicosScreen({super.key});

  @override
  State<TurnosPublicosScreen> createState() =>
      _TurnosPublicosScreenState();
}

class _TurnosPublicosScreenState extends State<TurnosPublicosScreen> {
  late Future<List<Servicio>> serviciosFuture;

  @override
  void initState() {
    super.initState();
    serviciosFuture = cargarServicios();
  }

  Future<List<Servicio>> cargarServicios() async {
    final data = await ApiService.getServicios();
    return data.map<Servicio>((e) => Servicio.fromJson(e)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: rosaSuave,

      // =========================
      // DRAWER
      // =========================
      drawer: const AppDrawer(current: 'publico'),

      // =========================
      // APP BAR
      // =========================
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Sacar turno',
          style: TextStyle(color: Colors.black),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
      ),

      // =========================
      // CONTENIDO
      // =========================
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: FutureBuilder<List<Servicio>>(
          future: serviciosFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            if (snapshot.hasError) {
              return const Center(
                child: Text('Error al cargar servicios'),
              );
            }

            final servicios = snapshot.data!;

            if (servicios.isEmpty) {
              return const Center(
                child: Text(
                  'No hay servicios disponibles',
                  style: TextStyle(
                    fontSize: 16,
                    color: grisTexto,
                  ),
                ),
              );
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Elegí un servicio',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),

                const SizedBox(height: 16),

                Expanded(
                  child: ListView.separated(
                    itemCount: servicios.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      final s = servicios[index];

                      return Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.06),
                              blurRadius: 12,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: ListTile(
                          contentPadding:
                              const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 16,
                          ),
                          leading: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color:
                                  rosaPrincipal.withOpacity(0.15),
                              borderRadius:
                                  BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.spa_outlined,
                              color: rosaPrincipal,
                              size: 26,
                            ),
                          ),
                          title: Text(
                            s.nombre,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                          subtitle: Padding(
                            padding:
                                const EdgeInsets.only(top: 4),
                            child: Text(
                              'Duración aproximada: ${s.duracionMinutos} minutos',
                              style: theme.textTheme.bodyMedium
                                  ?.copyWith(
                                color: Colors.grey[600],
                              ),
                            ),
                          ),
                          trailing: const Icon(
                            Icons.chevron_right,
                            color: Colors.grey,
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    DisponibilidadPublicaScreen(
                                  servicio: s,
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
