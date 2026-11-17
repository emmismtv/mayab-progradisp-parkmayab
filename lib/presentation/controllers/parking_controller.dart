import 'package:flutter/foundation.dart';

import '../../core/errors.dart';
import '../../domain/entities/app_settings.dart';
import '../../domain/entities/parking_slot.dart';
import '../../domain/entities/reservation.dart';
import '../../domain/repositories/repositories.dart';
import '../../domain/repositories/services.dart';
import '../../domain/usecases/usecases.dart';

/// Estado global de la app (Provider). Orquesta casos de uso y expone datos
/// a las pantallas; no contiene lógica de UI ni de persistencia.
class ParkingController extends ChangeNotifier {
  ParkingController({
    required this.settingsRepo,
    required this.slotRepo,
    required this.reservationRepo,
    required this.location,
    required this.checkGeofence,
    required this.reserveSlot,
    required this.validateGateQr,
    required this.closeReservation,
    required this.expireStale,
  });

  final SettingsRepository settingsRepo;
  final SlotRepository slotRepo;
  final ReservationRepository reservationRepo;
  final LocationService location;
  final CheckGeofence checkGeofence;
  final ReserveSlot reserveSlot;
  final ValidateGateQr validateGateQr;
  final CloseReservation closeReservation;
  final ExpireStaleReservations expireStale;

  AppSettings settings = AppSettings.defaults();
  GeofenceResult? geofence;
  String? locationError;
  bool locating = false;
  Reservation? current;
  bool ready = false;

  /// Future que consumen los FutureBuilder del historial.
  late Future<List<Reservation>> historyFuture = reservationRepo.getAll();

  bool get canReserve => settings.demoMode || (geofence?.inside ?? false);

  Future<void> init() async {
    try {
      settings = await settingsRepo.load();
      await slotRepo.seedIfEmpty();
      await refreshReservation();
    } on AppException catch (e) {
      locationError = e.message;
    }
    ready = true;
    notifyListeners();
    await refreshLocation();
  }

  Future<void> refreshLocation() async {
    locating = true;
    locationError = null;
    notifyListeners();
    try {
      geofence = await checkGeofence(
        center: settings.campus,
        radiusMeters: settings.radiusMeters,
      );
    } on AppException catch (e) {
      locationError = e.message;
    } catch (_) {
      locationError = 'No se pudo obtener tu ubicación.';
    }
    locating = false;
    notifyListeners();
  }

  Future<void> refreshReservation() async {
    await expireStale();
    current = await reservationRepo.getCurrent();
    historyFuture = reservationRepo.getAll();
    notifyListeners();
  }

  Future<List<ParkingSlot>> slotsOfFloor(int floor) =>
      slotRepo.getByFloor(floor);

  Future<void> reserve({
    required int slotId,
    String? photoFile,
    String? note,
  }) async {
    await reserveSlot(
      slotId: slotId,
      campus: settings.campus,
      radiusMeters: settings.radiusMeters,
      bypassGeofence: settings.demoMode,
      photoFile: photoFile,
      note: note,
    );
    await refreshReservation();
  }

  Future<void> validateQr(String raw) async {
    await validateGateQr(raw);
    await refreshReservation();
  }

  Future<void> closeCurrent(Reservation r) async {
    await closeReservation(r);
    await refreshReservation();
  }

  Future<void> setDemoMode(bool value) async {
    settings = settings.copyWith(demoMode: value);
    await settingsRepo.save(settings);
    notifyListeners();
  }

  /// Usa la ubicación actual como centro del campus (calibración).
  Future<void> calibrateCampusHere() async {
    final pos = await location.currentPosition();
    settings = settings.copyWith(campus: pos);
    await settingsRepo.save(settings);
    await refreshLocation();
  }
}
