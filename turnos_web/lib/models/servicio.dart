class Servicio {
  final int id;
  final String nombre;
  final String? descripcion;
  final int duracionMinutos;

  Servicio({
    required this.id,
    required this.nombre,
    this.descripcion,
    required this.duracionMinutos,
  });

  factory Servicio.fromJson(Map<String, dynamic> json) {
    return Servicio(
      id: json['id'],
      nombre: json['nombre'],
      descripcion: json['descripcion'],
      duracionMinutos: json['duracion_minutos'],
    );
  }
}
