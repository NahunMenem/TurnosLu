import 'package:flutter/material.dart';
import '../services/api_service.dart';

class CrearServicioScreen extends StatefulWidget {
  const CrearServicioScreen({super.key});

  @override
  State<CrearServicioScreen> createState() => _CrearServicioScreenState();
}

class _CrearServicioScreenState extends State<CrearServicioScreen> {
  final _formKey = GlobalKey<FormState>();

  final nombreCtrl = TextEditingController();
  final descripcionCtrl = TextEditingController();
  final duracionCtrl = TextEditingController();

  bool guardando = false;

  Future<void> guardar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => guardando = true);

    try {
      await ApiService.crearServicio(
        nombre: nombreCtrl.text.trim(),
        descripcion: descripcionCtrl.text.trim().isEmpty
            ? null
            : descripcionCtrl.text.trim(),
        duracionMinutos: int.parse(duracionCtrl.text),
      );

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al guardar servicio')),
      );
    } finally {
      setState(() => guardando = false);
    }
  }

  @override
  void dispose() {
    nombreCtrl.dispose();
    descripcionCtrl.dispose();
    duracionCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nuevo servicio'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // =======================
              // 🧴 CARD FORMULARIO
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
                      TextFormField(
                        controller: nombreCtrl,
                        decoration: InputDecoration(
                          labelText: 'Nombre del servicio',
                          prefixIcon: const Icon(Icons.spa_outlined),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        validator: (v) =>
                            v == null || v.isEmpty ? 'Campo obligatorio' : null,
                      ),

                      const SizedBox(height: 16),

                      TextFormField(
                        controller: descripcionCtrl,
                        maxLines: 3,
                        decoration: InputDecoration(
                          labelText: 'Descripción (opcional)',
                          alignLabelWithHint: true,
                          prefixIcon:
                              const Icon(Icons.description_outlined),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      TextFormField(
                        controller: duracionCtrl,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Duración (minutos)',
                          prefixIcon:
                              const Icon(Icons.schedule_outlined),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) {
                            return 'Campo obligatorio';
                          }
                          if (int.tryParse(v) == null) {
                            return 'Ingresá un número válido';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // =======================
              // 💾 BOTÓN GUARDAR
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
                        child: const Text('Guardar servicio'),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
