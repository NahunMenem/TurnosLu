import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/servicio.dart';
import '../services/api_service.dart';
import 'confirmar_turno_screen.dart';

// 🎨 Paleta app
const rosaPrincipal = Color(0xFFF2A1C6);
const rosaSuave = Color(0xFFFFF1F6);
const grisTexto = Color(0xFF4A4A4A);

class DisponibilidadPublicaScreen extends StatefulWidget {
  final Servicio servicio;

  const DisponibilidadPublicaScreen({
    super.key,
    required this.servicio,
  });

  @override
  State<DisponibilidadPublicaScreen> createState() =>
      _DisponibilidadPublicaScreenState();
}

class _DisponibilidadPublicaScreenState
    extends State<DisponibilidadPublicaScreen> {
  DateTime fecha = DateTime.now();
  List<String> horas = [];
  bool cargando = false;

  @override
  void initState() {
    super.initState();
    cargarDisponibilidad();
  }

  Future<void> cargarDisponibilidad() async {
    setState(() {
      cargando = true;
      horas = [];
    });

    try {
      final f = DateFormat('yyyy-MM-dd').format(fecha);

      final data = await ApiService.getDisponibilidad(
        servicioId: widget.servicio.id,
        fecha: f,
      );

      if (!mounted) return;
      setState(() => horas = data);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error al cargar disponibilidad'),
        ),
      );
    } finally {
      if (mounted) setState(() => cargando = false);
    }
  }

  Future<void> pickFecha() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: fecha,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 60)),
    );

    if (picked != null) {
      setState(() => fecha = picked);
      cargarDisponibilidad();
    }
  }

  void irAConfirmar(String hora) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ConfirmarTurnoScreen(
          servicio: widget.servicio,
          fecha: fecha,
          hora: hora,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: rosaSuave,

      // =========================
      // APP BAR
      // =========================
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Disponibilidad',
          style: TextStyle(color: Colors.black),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
      ),

      // =========================
      // CONTENIDO
      // =========================
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // =======================
            // 💆 CARD SERVICIO + FECHA
            // =======================
            Container(
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
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Text(
                      widget.servicio.nombre,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 12),
                    InkWell(
                      onTap: pickFecha,
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 18,
                        ),
                        decoration: BoxDecoration(
                          color: rosaPrincipal.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.calendar_month,
                              color: rosaPrincipal,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              DateFormat('EEEE dd/MM', 'es')
                                  .format(fecha),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: grisTexto,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 28),

            // =======================
            // ⏰ HORARIOS
            // =======================
            Text(
              'Horarios disponibles',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),

            const SizedBox(height: 16),

            if (cargando)
              const Expanded(
                child: Center(child: CircularProgressIndicator()),
              )
            else if (horas.isEmpty)
              const Expanded(
                child: Center(
                  child: Text(
                    'No hay horarios disponibles para este día',
                    style: TextStyle(
                      fontSize: 16,
                      color: grisTexto,
                    ),
                  ),
                ),
              )
            else
              Expanded(
                child: GridView.builder(
                  itemCount: horas.length,
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 14,
                    crossAxisSpacing: 14,
                    childAspectRatio: 2.8,
                  ),
                  itemBuilder: (context, index) {
                    final h = horas[index];

                    return OutlinedButton(
                      onPressed: () => irAConfirmar(h),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: rosaPrincipal,
                        side: const BorderSide(color: rosaPrincipal),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      child: Text(h),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
