import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../widgets/app_drawer.dart';
import '../services/api_service.dart';

// =======================
// 🎨 PALETA MONOCROMÁTICA ROSA
// =======================
const rosaBase = Color(0xFFF2A1C6);
const rosaOscuro = Color(0xFFD96A9E);
const rosaClaro = Color(0xFFFFE6F0);
const rosaUltraClaro = Color(0xFFFFF5FA);

const grisTitulo = Color(0xFF2E2E2E);
const grisTexto = Color(0xFF6E6E6E);
const grisSubtexto = Color(0xFF9A9A9A);

class TurnosScreen extends StatefulWidget {
  const TurnosScreen({super.key});

  @override
  State<TurnosScreen> createState() => _TurnosScreenState();
}

class _TurnosScreenState extends State<TurnosScreen> {
  DateTime fechaSeleccionada = DateTime.now();
  late Future<List<dynamic>> turnosFuture;

  @override
  void initState() {
    super.initState();
    turnosFuture = cargarTurnos();
  }

  Future<List<dynamic>> cargarTurnos() async {
    final f = DateFormat('yyyy-MM-dd').format(fechaSeleccionada);
    return ApiService.getTurnosPorFecha(f);
  }

  Future<void> seleccionarFecha() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: fechaSeleccionada,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) {
      setState(() {
        fechaSeleccionada = picked;
        turnosFuture = cargarTurnos();
      });
    }
  }

  String horaCorta(String hora) {
    try {
      final dt = DateFormat('HH:mm:ss').parse(hora);
      return DateFormat('HH:mm').format(dt);
    } catch (_) {
      return hora.substring(0, 5);
    }
  }

  // ======================
  // 📲 WHATSAPP
  // ======================
  Future<void> enviarWhatsApp({
    required String telefono,
    required String nombre,
    required String servicio,
    required String hora,
  }) async {
    final fecha = DateFormat('dd/MM/yyyy').format(fechaSeleccionada);

    final mensaje = Uri.encodeComponent(
      'Hola $nombre 👋\n\n'
      'Te escribimos para confirmar tu turno de *$servicio* '
      'el día *$fecha* a las *$hora*.\n\n'
      '¡Te esperamos! 💕',
    );

    final telLimpio = telefono.replaceAll(RegExp(r'\D'), '');
    final url = Uri.parse('https://wa.me/549$telLimpio?text=$mensaje');

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  // ======================
  // 🗑 ELIMINAR TURNO (CONFIRMACIÓN)
  // ======================
  Future<void> confirmarEliminarTurno(int turnoId) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text(
          'Eliminar turno',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: grisTitulo,
          ),
        ),
        content: const Text(
          'Este turno NO está confirmado.\n\n'
          'Si lo eliminás, el horario quedará libre para otro cliente.\n\n'
          '¿Querés continuar?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: rosaBase,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (ok == true) {
      await ApiService.eliminarTurno(turnoId);
      setState(() {
        turnosFuture = cargarTurnos();
      });
    }
  }

  // ======================
  // 💰 MODAL PAGO
  // ======================
  Future<void> mostrarModalPago(int turnoId) async {
    String metodo = 'efectivo';
    final montoCtrl = TextEditingController();

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text(
          'Registrar pago',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: grisTitulo,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              value: metodo,
              items: const [
                DropdownMenuItem(value: 'efectivo', child: Text('Efectivo')),
                DropdownMenuItem(value: 'tarjeta', child: Text('Tarjeta')),
                DropdownMenuItem(
                    value: 'transferencia', child: Text('Transferencia')),
              ],
              onChanged: (v) => metodo = v!,
              decoration: const InputDecoration(labelText: 'Método de pago'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: montoCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Monto',
                prefixText: '\$ ',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: rosaBase,
            ),
            onPressed: () async {
              await ApiService.registrarPago(
                turnoId: turnoId,
                metodo: metodo,
                monto: double.parse(montoCtrl.text),
              );
              Navigator.pop(context);
              setState(() {
                turnosFuture = cargarTurnos();
              });
            },
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
  }

  // ======================
  // 🧩 ITEM TURNO
  // ======================
  Widget turnoItem(Map t, String servicio) {
    final confirmado = t['confirmado'] == true;
    final hora = horaCorta(t['hora']);
    final double totalPagado = (t['total_pagado'] ?? 0).toDouble();
    final bool pagado = totalPagado > 0;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: pagado ? rosaClaro : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: pagado ? rosaBase : Colors.grey.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.schedule_outlined, color: rosaOscuro),
              const SizedBox(width: 8),
              Text(
                hora,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: grisTitulo,
                ),
              ),
              const Spacer(),
              Chip(
                label: Text(
                  pagado
                      ? 'Pagado \$${totalPagado.toStringAsFixed(0)}'
                      : 'Sin pago',
                ),
                backgroundColor: pagado
                    ? rosaBase.withOpacity(0.15)
                    : Colors.grey.shade100,
                labelStyle: TextStyle(
                  color: pagado ? rosaOscuro : grisSubtexto,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 8),
              Chip(
                label: Text(confirmado ? 'Confirmado' : 'Pendiente'),
                backgroundColor: confirmado
                    ? rosaBase.withOpacity(0.12)
                    : rosaBase.withOpacity(0.06),
                labelStyle: TextStyle(
                  color: confirmado ? rosaOscuro : grisSubtexto,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${t['cliente_nombre']} · ${t['cliente_telefono']}',
            style: const TextStyle(color: grisTexto),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Radio<bool>(
                value: true,
                groupValue: confirmado,
                activeColor: rosaOscuro,
                onChanged: confirmado
                    ? null
                    : (_) async {
                        await ApiService.confirmarTurno(t['id']);
                        setState(() {
                          turnosFuture = cargarTurnos();
                        });
                      },
              ),
              const Text('Confirmado', style: TextStyle(color: grisTexto)),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.message_outlined,
                    color: rosaOscuro),
                onPressed: () => enviarWhatsApp(
                  telefono: t['cliente_telefono'],
                  nombre: t['cliente_nombre'],
                  servicio: servicio,
                  hora: hora,
                ),
              ),
              if (!confirmado)
                IconButton(
                  icon: const Icon(Icons.delete_outline,
                      color: rosaOscuro),
                  onPressed: () => confirmarEliminarTurno(t['id']),
                ),
              IconButton(
                icon: Icon(
                  Icons.payments_outlined,
                  color: pagado ? rosaOscuro : grisSubtexto,
                ),
                onPressed: () => mostrarModalPago(t['id']),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ======================
  // 🖥 UI
  // ======================
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: rosaUltraClaro,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Turnos',
          style: TextStyle(
            color: grisTitulo,
            fontWeight: FontWeight.w600,
          ),
        ),
        iconTheme: const IconThemeData(color: grisTitulo),
      ),
      drawer: const AppDrawer(current: 'turnos'),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            InkWell(
              onTap: seleccionarFecha,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    vertical: 14, horizontal: 18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: rosaBase.withOpacity(0.12),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.calendar_month,
                        color: rosaOscuro),
                    const SizedBox(width: 10),
                    Text(
                      DateFormat('EEEE dd/MM', 'es')
                          .format(fechaSeleccionada),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: grisTitulo,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: FutureBuilder<List<dynamic>>(
                future: turnosFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const Center(
                        child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return const Center(
                        child: Text('Error al cargar turnos'));
                  }

                  final turnos = snapshot.data!;
                  if (turnos.isEmpty) {
                    return const Center(
                        child: Text('No hay turnos para este día'));
                  }

                  final Map<String, List<dynamic>> porServicio = {};
                  for (final t in turnos) {
                    porServicio.putIfAbsent(t['servicio'], () => []);
                    porServicio[t['servicio']]!.add(t);
                  }

                  return ListView(
                    children: porServicio.entries.map((entry) {
                      final servicio = entry.key;
                      final lista = entry.value;

                      return Container(
                        margin:
                            const EdgeInsets.only(bottom: 24),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius:
                              BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color:
                                  rosaBase.withOpacity(0.12),
                              blurRadius: 12,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(
                              servicio,
                              style: theme
                                  .textTheme.titleMedium
                                  ?.copyWith(
                                fontWeight:
                                    FontWeight.bold,
                                color: grisTitulo,
                              ),
                            ),
                            const SizedBox(height: 12),
                            ...lista.map(
                                (t) => turnoItem(
                                    t, servicio)),
                          ],
                        ),
                      );
                    }).toList(),
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
