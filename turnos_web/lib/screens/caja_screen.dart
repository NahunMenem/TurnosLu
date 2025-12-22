import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/api_service.dart';

/// 🎨 PALETA MONOCROMÁTICA ROSA
const rosaBase = Color(0xFFF2A1C6);
const rosaOscuro = Color(0xFFD96A9E);
const rosaClaro = Color(0xFFFFE6F0);
const rosaUltraClaro = Color(0xFFFFF5FA);

const grisTitulo = Color(0xFF2E2E2E);
const grisTexto = Color(0xFF6E6E6E);
const grisSubtexto = Color(0xFF9A9A9A);

class CajaScreen extends StatefulWidget {
  const CajaScreen({super.key});

  @override
  State<CajaScreen> createState() => _CajaScreenState();
}

class _CajaScreenState extends State<CajaScreen> {
  DateTime desde = DateTime.now();
  DateTime hasta = DateTime.now();

  bool cargando = false;
  Map<String, dynamic>? caja;

  @override
  void initState() {
    super.initState();
    cargarCaja();
  }

  Future<void> cargarCaja() async {
    setState(() => cargando = true);

    final data = await ApiService.getCaja(
      desde: DateFormat('yyyy-MM-dd').format(desde),
      hasta: DateFormat('yyyy-MM-dd').format(hasta),
    );

    setState(() {
      caja = data;
      cargando = false;
    });
  }

  Future<void> pickFecha(bool esDesde) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: esDesde ? desde : hasta,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        esDesde ? desde = picked : hasta = picked;
      });
      cargarCaja();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: rosaUltraClaro,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Caja',
          style: TextStyle(
            color: grisTitulo,
            fontWeight: FontWeight.w600,
          ),
        ),
        iconTheme: const IconThemeData(color: grisTitulo),
      ),
      body: cargando || caja == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// ======================
                  /// 🧾 HEADER
                  /// ======================
                  const Text(
                    'Resumen de ingresos',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: grisTitulo,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Facturación y pagos del período seleccionado',
                    style: TextStyle(color: grisSubtexto),
                  ),

                  const SizedBox(height: 24),

                  /// ======================
                  /// 📅 FILTRO FECHAS
                  /// ======================
                  _card(
                    child: Row(
                      children: [
                        _fechaBox('Desde', desde, () => pickFecha(true)),
                        const SizedBox(width: 12),
                        _fechaBox('Hasta', hasta, () => pickFecha(false)),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  /// ======================
                  /// 💰 KPIs
                  /// ======================
                  Row(
                    children: [
                      _kpi(
                        titulo: 'Total facturado',
                        valor:
                            '\$ ${caja!['total_general'].toStringAsFixed(0)}',
                        icono: Icons.attach_money,
                      ),
                      const SizedBox(width: 12),
                      _kpi(
                        titulo: 'Turnos atendidos',
                        valor: caja!['total_turnos'].toString(),
                        icono: Icons.event_available,
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  /// ======================
                  /// 📊 FACTURACIÓN POR SERVICIO
                  /// ======================
                  _sectionTitle('Facturación por servicio'),
                  _card(child: _barChartServicios()),

                  const SizedBox(height: 32),

                  /// ======================
                  /// 🥧 MÉTODOS DE PAGO
                  /// ======================
                  _sectionTitle('Distribución por método de pago'),
                  _card(child: _pieChartPagos()),

                  const SizedBox(height: 32),

                  /// ======================
                  /// 📈 SERVICIOS MÁS SOLICITADOS
                  /// ======================
                  _sectionTitle('Servicios más solicitados'),
                  _card(
                    child: Column(
                      children: caja!['servicios_mas_solicitados']
                          .map<Widget>((s) {
                        return _rankingItem(
                          s['servicio'],
                          '${s['porcentaje']}%',
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  /// =====================================================
  /// 📊 GRÁFICO BARRAS – SERVICIOS
  /// =====================================================
  Widget _barChartServicios() {
    final servicios = caja!['total_por_servicio'] as List;

    return SizedBox(
      height: 260,
      child: BarChart(
        BarChartData(
          gridData: FlGridData(show: false),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            leftTitles:
                AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:
                AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles:
                AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final i = value.toInt();
                  if (i >= servicios.length) return const SizedBox();
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      servicios[i]['servicio'],
                      style: const TextStyle(
                        fontSize: 11,
                        color: grisTexto,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          barGroups: List.generate(servicios.length, (i) {
            return BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: servicios[i]['total'].toDouble(),
                  color: rosaBase,
                  width: 22,
                  borderRadius: BorderRadius.circular(8),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }

  /// =====================================================
  /// 🥧 GRÁFICO TORTA – MÉTODOS DE PAGO
  /// =====================================================
  Widget _pieChartPagos() {
    final metodos = caja!['total_por_metodo'] as List;

    final colores = [
      rosaOscuro,
      rosaBase,
      rosaBase.withOpacity(0.8),
      rosaBase.withOpacity(0.6),
      rosaBase.withOpacity(0.4),
    ];

    return SizedBox(
      height: 260,
      child: PieChart(
        PieChartData(
          sectionsSpace: 2,
          centerSpaceRadius: 45,
          sections: List.generate(metodos.length, (i) {
            final m = metodos[i];
            final total = m['total'].toDouble();
            return PieChartSectionData(
              value: total,
              title:
                  '${m['metodo'].toString().toUpperCase()}\n\$${total.toStringAsFixed(0)}',
              color: colores[i % colores.length],
              radius: 70,
              titleStyle: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            );
          }),
        ),
      ),
    );
  }

  /// =====================================================
  /// 🧩 COMPONENTES UI
  /// =====================================================
  Widget _card({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: rosaBase.withOpacity(0.12),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _fechaBox(String label, DateTime fecha, VoidCallback onTap) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: grisSubtexto)),
            const SizedBox(height: 6),
            Text(
              DateFormat('dd/MM/yyyy').format(fecha),
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 15,
                color: grisTitulo,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _kpi({
    required String titulo,
    required String valor,
    required IconData icono,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: rosaClaro,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icono, color: rosaOscuro),
            const SizedBox(height: 10),
            Text(
              titulo,
              style: const TextStyle(
                color: grisSubtexto,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              valor,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: rosaOscuro,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String t) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        t,
        style: const TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.bold,
          color: grisTitulo,
        ),
      ),
    );
  }

  Widget _rankingItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: grisTitulo,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: rosaOscuro,
            ),
          ),
        ],
      ),
    );
  }
}
