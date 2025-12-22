class Horario {
  final int id;
  final int servicioId;
  final int diaSemana; // 0=lunes
  final String horaInicio;
  final String horaFin;

  Horario({
    required this.id,
    required this.servicioId,
    required this.diaSemana,
    required this.horaInicio,
    required this.horaFin,
  });

  factory Horario.fromJson(Map<String, dynamic> json) {
    return Horario(
      id: json['id'],
      servicioId: json['servicio_id'],
      diaSemana: json['dia_semana'],
      horaInicio: json['hora_inicio'],
      horaFin: json['hora_fin'],
    );
  }
}
