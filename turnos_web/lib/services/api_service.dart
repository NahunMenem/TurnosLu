import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl =
      'https://turnoslu-production.up.railway.app';

  // =====================================================
  // 🧾 SERVICIOS
  // =====================================================
  static Future<List<dynamic>> getServicios() async {
    final response = await http.get(
      Uri.parse('$baseUrl/servicios'),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception(
        'Error al cargar servicios (${response.statusCode})',
      );
    }
  }

  static Future<void> crearServicio({
    required String nombre,
    String? descripcion,
    required int duracionMinutos,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/servicios'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'nombre': nombre,
        'descripcion': descripcion,
        'duracion_minutos': duracionMinutos,
      }),
    );

    if (response.statusCode != 200 &&
        response.statusCode != 201) {
      throw Exception(
        'Error al crear servicio (${response.statusCode})',
      );
    }
  }

  // =====================================================
  // 🕒 HORARIOS
  // =====================================================
  static Future<List<dynamic>> getHorarios(int servicioId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/servicios/$servicioId/horarios'),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Error al cargar horarios');
    }
  }

  static Future<void> crearHorario({
    required int servicioId,
    required int diaSemana,
    required String horaInicio,
    required String horaFin,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/horarios'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'servicio_id': servicioId,
        'dia_semana': diaSemana,
        'hora_inicio': horaInicio,
        'hora_fin': horaFin,
      }),
    );

    if (response.statusCode != 200 &&
        response.statusCode != 201) {
      throw Exception('Error al crear horario');
    }
  }

  // =====================================================
  // 📆 DISPONIBILIDAD
  // =====================================================
  static Future<List<String>> getDisponibilidad({
    required int servicioId,
    required String fecha, // yyyy-MM-dd
  }) async {
    final response = await http.get(
      Uri.parse(
        '$baseUrl/disponibilidad?servicio_id=$servicioId&fecha=$fecha',
      ),
    );

    if (response.statusCode == 200) {
      final List data = json.decode(response.body);
      return data.map((e) => e.toString()).toList();
    } else {
      throw Exception('Error al cargar disponibilidad');
    }
  }

  // =====================================================
  // 📅 TURNOS
  // =====================================================
  static Future<void> reservarTurno({
    required int servicioId,
    required String fecha,
    required String hora,
    required String clienteNombre,
    required String clienteTelefono,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/turnos/reservar'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'servicio_id': servicioId,
        'fecha': fecha,
        'hora': hora,
        'cliente_nombre': clienteNombre,
        'cliente_telefono': clienteTelefono,
      }),
    );

    if (response.statusCode != 200 &&
        response.statusCode != 201) {
      throw Exception('Error al reservar turno');
    }
  }

  static Future<void> reservarTurnoAdmin({
    required int servicioId,
    required String fecha,
    required String hora,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/turnos/reservar'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'servicio_id': servicioId,
        'fecha': fecha,
        'hora': hora,
        'cliente_nombre': 'ADMIN',
        'cliente_telefono': 'ADMIN',
      }),
    );

    if (response.statusCode != 200 &&
        response.statusCode != 201) {
      throw Exception('Error al reservar turno');
    }
  }

  static Future<List<dynamic>> getTurnosPorFecha(String fecha) async {
    final response = await http.get(
      Uri.parse('$baseUrl/turnos?fecha=$fecha'),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Error al cargar turnos');
    }
  }

  // =====================================================
  // ✅ CONFIRMAR TURNO
  // =====================================================
  static Future<void> confirmarTurno(int turnoId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/turnos/$turnoId/confirmar'),
    );

    if (response.statusCode != 200) {
      throw Exception('Error al confirmar turno');
    }
  }

  // =====================================================
  // 💰 REGISTRAR PAGO
  // =====================================================
  static Future<void> registrarPago({
    required int turnoId,
    required String metodo,
    required double monto,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/pagos'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'turno_id': turnoId,
        'metodo': metodo,
        'monto': monto,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Error al registrar pago');
    }
  }

    static Future<Map<String, dynamic>> getCaja({
    required String desde,
    required String hasta,
    }) async {
    final response = await http.get(
        Uri.parse('$baseUrl/caja?desde=$desde&hasta=$hasta'),
    );

    if (response.statusCode == 200) {
        return jsonDecode(response.body);
    } else {
        throw Exception(
        'Error al cargar caja (${response.statusCode})',
        );
    }
    }


    static Future<void> eliminarTurno(int turnoId) async {
    final response = await http.delete(
        Uri.parse('$baseUrl/turnos/$turnoId'),
    );

    if (response.statusCode != 200) {
        throw Exception('No se pudo eliminar el turno');
    }
    }

}
