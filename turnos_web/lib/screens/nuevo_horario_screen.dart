import 'package:flutter/material.dart';
import '../models/servicio.dart';
import '../services/api_service.dart';

class NuevoHorarioScreen extends StatefulWidget {
  final Servicio servicio;

  const NuevoHorarioScreen({super.key, required this.servicio});

  @override
  State<NuevoHorarioScreen> createState() => _NuevoHorarioScreenState();
}

class _NuevoHorarioScreenState extends State<NuevoHorarioScreen> {
  int dia = 0;
  TimeOfDay inicio = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay fin = const TimeOfDay(hour: 13, minute: 0);
  bool guardando = false;

  Future<void> pickHora(bool esInicio) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: esInicio ? inicio : fin,
    );
    if (picked != null) {
      setState(() {
        esInicio ? inicio = picked : fin = picked;
      });
    }
  }

  String fmt(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  Future<void> guardar() async {
    setState(() => guardando = true);
    try {
      await ApiService.crearHorario(
        servicioId: widget.servicio.id,
        diaSemana: dia,
        horaInicio: fmt(inicio),
        horaFin: fmt(fin),
      );
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al guardar horario')),
      );
    } finally {
      setState(() => guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nuevo horario'),
        centerTitle: true,
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

            // =======================
            // 🕒 FORMULARIO HORARIO
            // =======================
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    DropdownButtonFormField<int>(
                      value: dia,
                      decoration: InputDecoration(
                        labelText: 'Día de la semana',
                        prefixIcon:
                            const Icon(Icons.calendar_today_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(
                            value: 0, child: Text('Lunes')),
                        DropdownMenuItem(
                            value: 1, child: Text('Martes')),
                        DropdownMenuItem(
                            value: 2, child: Text('Miércoles')),
                        DropdownMenuItem(
                            value: 3, child: Text('Jueves')),
                        DropdownMenuItem(
                            value: 4, child: Text('Viernes')),
                        DropdownMenuItem(
                            value: 5, child: Text('Sábado')),
                        DropdownMenuItem(
                            value: 6, child: Text('Domingo')),
                      ],
                      onChanged: (v) => setState(() => dia = v!),
                    ),

                    const SizedBox(height: 20),

                    ListTile(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      tileColor:
                          theme.colorScheme.surfaceVariant,
                      title: const Text('Hora de inicio'),
                      subtitle: Text(
                        fmt(inicio),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      trailing:
                          const Icon(Icons.access_time_outlined),
                      onTap: () => pickHora(true),
                    ),

                    const SizedBox(height: 12),

                    ListTile(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      tileColor:
                          theme.colorScheme.surfaceVariant,
                      title: const Text('Hora de fin'),
                      subtitle: Text(
                        fmt(fin),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      trailing:
                          const Icon(Icons.access_time_outlined),
                      onTap: () => pickHora(false),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),

            // =======================
            // 💾 GUARDAR
            // =======================
            guardando
                ? const Center(child: CircularProgressIndicator())
                : SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: guardar,
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      child: const Text('Guardar horario'),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
