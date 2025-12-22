import 'package:flutter/material.dart';
import '../models/horario.dart';
import '../models/servicio.dart';
import '../services/api_service.dart';
import 'nuevo_horario_screen.dart';
import 'disponibilidad_screen.dart';

class HorariosScreen extends StatefulWidget {
  final Servicio servicio;

  const HorariosScreen({super.key, required this.servicio});

  @override
  State<HorariosScreen> createState() => _HorariosScreenState();
}

class _HorariosScreenState extends State<HorariosScreen> {
  late Future<List<Horario>> horariosFuture;

  @override
  void initState() {
    super.initState();
    horariosFuture = cargarHorarios();
  }

  Future<List<Horario>> cargarHorarios() async {
    final data = await ApiService.getHorarios(widget.servicio.id);
    return data.map<Horario>((e) => Horario.fromJson(e)).toList();
  }

  void refrescar() {
    setState(() {
      horariosFuture = cargarHorarios();
    });
  }

  String diaTexto(int d) {
    const dias = [
      'Lunes',
      'Martes',
      'Miércoles',
      'Jueves',
      'Viernes',
      'Sábado',
      'Domingo',
    ];
    return dias[d];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Horarios'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.event_available_outlined),
            tooltip: 'Ver disponibilidad',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      DisponibilidadScreen(servicio: widget.servicio),
                ),
              );
            },
          ),
        ],
      ),

      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // =======================
            // 🧾 CONTEXTO SERVICIO
            // =======================
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  widget.servicio.nombre,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            Text(
              'Horarios configurados',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 12),

            Expanded(
              child: FutureBuilder<List<Horario>>(
                future: horariosFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }

                  if (snapshot.hasError) {
                    return const Center(
                      child: Text('Error al cargar horarios'),
                    );
                  }

                  final horarios = snapshot.data!;

                  if (horarios.isEmpty) {
                    return const Center(
                      child: Text(
                        'No hay horarios cargados',
                        style: TextStyle(fontSize: 16),
                      ),
                    );
                  }

                  return ListView.separated(
                    itemCount: horarios.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final h = horarios[index];
                      return Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: ListTile(
                          leading: const Icon(Icons.schedule_outlined),
                          title: Text(
                            diaTexto(h.diaSemana),
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: Text(
                            '${h.horaInicio} - ${h.horaFin}',
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),

      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('Nuevo horario'),
        onPressed: () async {
          final ok = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => NuevoHorarioScreen(
                servicio: widget.servicio,
              ),
            ),
          );

          if (ok == true) {
            refrescar();
          }
        },
      ),
    );
  }
}
