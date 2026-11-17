/// Ciclo de vida de una reserva:
/// active -> used (entró por la pluma) -> completed (salió)
/// active -> expired | cancelled
enum ReservationStatus { active, used, completed, expired, cancelled }

/// Una reserva de cajón. Funciona como "entrada del diario" de la app:
/// guarda foto, nota dictada y coordenadas GPS del momento de apartar.
class Reservation {
  final int? id;
  final int slotId;
  final String slotCode;
  final int floor;
  final String wing;
  final DateTime createdAt;
  final DateTime expiresAt;
  final ReservationStatus status;
  final double lat;
  final double lng;

  /// Solo el nombre del archivo; ver [AppPaths].
  final String? photoFile;
  final String? note;

  const Reservation({
    this.id,
    required this.slotId,
    required this.slotCode,
    required this.floor,
    required this.wing,
    required this.createdAt,
    required this.expiresAt,
    required this.status,
    required this.lat,
    required this.lng,
    this.photoFile,
    this.note,
  });

  bool get isExpired =>
      status == ReservationStatus.active && DateTime.now().isAfter(expiresAt);

  /// Reserva vigente (aún no termina su ciclo).
  bool get isCurrent =>
      status == ReservationStatus.active || status == ReservationStatus.used;

  Reservation copyWith({int? id, ReservationStatus? status}) => Reservation(
        id: id ?? this.id,
        slotId: slotId,
        slotCode: slotCode,
        floor: floor,
        wing: wing,
        createdAt: createdAt,
        expiresAt: expiresAt,
        status: status ?? this.status,
        lat: lat,
        lng: lng,
        photoFile: photoFile,
        note: note,
      );
}
