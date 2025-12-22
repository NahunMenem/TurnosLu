import 'package:flutter/material.dart';
import '../models/servicio.dart';
import '../services/api_service.dart';
import 'package:intl/intl.dart';

class ConfirmarTurnoScreen extends StatefulWidget {
  final Servicio servicio;
  final DateTime fecha;
  final String hora;

  const ConfirmarTurnoScreen({
    super.key,
    required this.servicio,
    required this.fecha,
    required this.hora,
  });

  @override
  State<ConfirmarTurnoScreen> createState() => _ConfirmarTurnoScreenState();
}

class _ConfirmarTurnoScreenState extends State<ConfirmarTurnoScreen> {
  final nombreCtrl = TextEditingController();
  final telefonoCtrl = TextEditingController();
  bool guardando = false;

  Future<void> confirmar() async {
    final nombre = nombreCtrl.text.trim();
    final telefono = telefonoCtrl.text.trim();

    if (nombre.isEmpty || telefono.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Completá nombre y teléfono')),
      );
      return;
    }

    setState(() => guardando = true);

    try {
      await ApiService.reservarTurno(
        servicioId: widget.servicio.id,
        fecha: DateFormat('yyyy-MM-dd').format(widget.fecha),
        hora: widget.hora,
        clienteNombre: nombre,
        clienteTelefono: telefono,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Turno confirmado correctamente')),
      );

      Navigator.popUntil(context, (r) => r.isFirst);
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al confirmar turno')),
      );
    } finally {
      setState(() => guardando = false);
    }
  }

  @override
  void dispose() {
    nombreCtrl.dispose();
    telefonoCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Confirmar turno'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // =======================
            // 🧖‍♀️ RESUMEN DEL TURNO
            // =======================
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
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
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      DateFormat('dd/MM/yyyy').format(widget.fecha),
                      style: theme.textTheme.bodyMedium,
                    ),
                    Text(
                      widget.hora,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),

            // =======================
            // 👤 DATOS DEL CLIENTE
            // =======================
            Text(
              'Datos del cliente',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 16),

            TextField(
              controller: nombreCtrl,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                labelText: 'Nombre y apellido',
                prefixIcon: const Icon(Icons.person_outline),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

            const SizedBox(height: 16),

            TextField(
              controller: telefonoCtrl,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: 'Teléfono',
                prefixIcon: const Icon(Icons.phone_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

            const SizedBox(height: 40),

            // =======================
            // ✅ BOTÓN CONFIRMAR
            // =======================
            guardando
                ? const Center(child: CircularProgressIndicator())
                : SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: confirmar,
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      child: const Text('Confirmar turno'),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
