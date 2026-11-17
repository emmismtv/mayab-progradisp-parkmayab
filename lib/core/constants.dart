/// Constantes globales de la aplicación.
class AppConstants {
  AppConstants._();

  /// Centro aproximado del campus (Carretera Mérida-Progreso km 15.5).
  /// Es configurable desde Ajustes ("Calibrar campus") porque es un valor
  /// aproximado, no un dato oficial.
  static const double defaultCampusLat = 21.0925;
  static const double defaultCampusLng = -89.6010;

  /// Radio en el que se permite apartar lugar (2 km).
  static const double defaultRadiusMeters = 2000;

  /// Minutos que dura una reserva antes de expirar.
  static const int reservationMinutes = 15;

  /// Contenido del QR que está impreso en la pluma de entrada.
  static const String gateQrPayload = 'PARKMAYAB|ENTRADA-1';

  /// Estructura (inventada) del edificio de estacionamiento.
  static const int floors = 3;
  static const List<String> wings = ['A', 'B'];
  static const int slotsPerWing = 10;
}
