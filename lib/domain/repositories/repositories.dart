import '../entities/app_settings.dart';
import '../entities/parking_slot.dart';
import '../entities/reservation.dart';

/// Contratos de persistencia. La capa de dominio solo conoce estas
/// interfaces (Inversión de dependencias); SQLite vive en la capa data.
abstract class SlotRepository {
  Future<void> seedIfEmpty();
  Future<List<ParkingSlot>> getByFloor(int floor);
  Future<ParkingSlot?> getById(int id);
  Future<void> updateStatus(int id, SlotStatus status);
}

abstract class ReservationRepository {
  Future<int> insert(Reservation reservation);
  Future<List<Reservation>> getAll();
  Future<Reservation?> getById(int id);

  /// Reserva en curso (active o used), si existe.
  Future<Reservation?> getCurrent();
  Future<void> updateStatus(int id, ReservationStatus status);
}

abstract class SettingsRepository {
  Future<AppSettings> load();
  Future<void> save(AppSettings settings);
}
