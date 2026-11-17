import '../../core/constants.dart';
import '../../core/errors.dart';
import '../entities/geo_point.dart';
import '../entities/parking_slot.dart';
import '../entities/reservation.dart';
import '../repositories/repositories.dart';
import '../repositories/services.dart';

/// Resultado de comparar la posición del usuario contra el campus.
class GeofenceResult {
  final GeoPoint position;
  final double distanceMeters;
  final bool inside;
  const GeofenceResult(this.position, this.distanceMeters, this.inside);
}

/// Calcula qué tan cerca está el usuario del campus.
class CheckGeofence {
  final LocationService _location;
  CheckGeofence(this._location);

  Future<GeofenceResult> call({
    required GeoPoint center,
    required double radiusMeters,
  }) async {
    final pos = await _location.currentPosition();
    final d = _location.distanceMeters(pos, center);
    return GeofenceResult(pos, d, d <= radiusMeters);
  }
}

/// Libera automáticamente las reservas activas cuyo tiempo venció.
class ExpireStaleReservations {
  final ReservationRepository _reservations;
  final SlotRepository _slots;
  ExpireStaleReservations(this._reservations, this._slots);

  Future<void> call() async {
    final current = await _reservations.getCurrent();
    if (current != null && current.isExpired) {
      await _reservations.updateStatus(current.id!, ReservationStatus.expired);
      await _slots.updateStatus(current.slotId, SlotStatus.free);
    }
  }
}

/// Aparta un cajón. Reglas de negocio:
///  - solo una reserva en curso por usuario,
///  - el cajón debe estar libre,
///  - el usuario debe estar dentro del radio (salvo modo demo).
class ReserveSlot {
  final SlotRepository _slots;
  final ReservationRepository _reservations;
  final CheckGeofence _geofence;
  ReserveSlot(this._slots, this._reservations, this._geofence);

  Future<Reservation> call({
    required int slotId,
    required GeoPoint campus,
    required double radiusMeters,
    required bool bypassGeofence,
    String? photoFile,
    String? note,
  }) async {
    final current = await _reservations.getCurrent();
    if (current != null) {
      throw AppException(
          'Ya tienes una reserva en curso (${current.slotCode}).');
    }

    final slot = await _slots.getById(slotId);
    if (slot == null || slot.status != SlotStatus.free) {
      throw const AppException('Ese cajón ya no está disponible.');
    }

    // Se captura el GPS justo al guardar la reserva.
    final geo = await _geofence(center: campus, radiusMeters: radiusMeters);
    if (!geo.inside && !bypassGeofence) {
      throw const AppException(
          'Debes estar a menos de 2 km del campus para apartar.');
    }

    final now = DateTime.now();
    final draft = Reservation(
      slotId: slot.id,
      slotCode: slot.code,
      floor: slot.floor,
      wing: slot.wing,
      createdAt: now,
      expiresAt: now.add(const Duration(minutes: AppConstants.reservationMinutes)),
      status: ReservationStatus.active,
      lat: geo.position.lat,
      lng: geo.position.lng,
      photoFile: photoFile,
      note: (note == null || note.trim().isEmpty) ? null : note.trim(),
    );
    final id = await _reservations.insert(draft);
    await _slots.updateStatus(slot.id, SlotStatus.reserved);
    return draft.copyWith(id: id);
  }
}

/// Valida el QR de la pluma y "abre" la entrada.
class ValidateGateQr {
  final ReservationRepository _reservations;
  final SlotRepository _slots;
  final ExpireStaleReservations _expire;
  ValidateGateQr(this._reservations, this._slots, this._expire);

  Future<Reservation> call(String raw) async {
    if (raw.trim() != AppConstants.gateQrPayload) {
      throw const AppException('Este QR no pertenece a la pluma de ParkMayab.');
    }
    await _expire();
    final current = await _reservations.getCurrent();
    if (current == null) {
      throw const AppException(
          'No tienes una reserva activa (o ya expiró). Aparta un lugar primero.');
    }
    if (current.status == ReservationStatus.used) {
      throw const AppException('Ya registraste tu entrada.');
    }
    await _reservations.updateStatus(current.id!, ReservationStatus.used);
    await _slots.updateStatus(current.slotId, SlotStatus.occupied);
    return current.copyWith(status: ReservationStatus.used);
  }
}

/// Cancela una reserva activa o termina una visita (salida del usuario).
/// En ambos casos el cajón vuelve a quedar libre.
class CloseReservation {
  final ReservationRepository _reservations;
  final SlotRepository _slots;
  CloseReservation(this._reservations, this._slots);

  Future<void> call(Reservation r) async {
    final target = r.status == ReservationStatus.active
        ? ReservationStatus.cancelled
        : ReservationStatus.completed;
    await _reservations.updateStatus(r.id!, target);
    await _slots.updateStatus(r.slotId, SlotStatus.free);
  }
}
