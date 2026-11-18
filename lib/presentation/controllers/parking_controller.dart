import 'package:flutter/foundation.dart';

import '../../core/constants.dart';
import '../../core/errors.dart';
import '../../domain/entities/app_settings.dart';
import '../../domain/entities/parking_slot.dart';
import '../../domain/entities/reservation.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/repositories/repositories.dart';
import '../../domain/repositories/services.dart';
import '../../domain/usecases/usecases.dart';

/// Disponibilidad resumida de un piso.
typedef FloorOccupancy = ({int floor, int free, int total});

/// Estado global de la app (Provider). Orquesta casos de uso y expone datos
/// a las pantallas; no contiene lógica de UI ni de persistencia.
class ParkingController extends ChangeNotifier {
  ParkingController({
    required this.settingsRepo,
    required this.profileRepo,
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
  final ProfileRepository profileRepo;
  final SlotRepository slotRepo;
  final ReservationRepository reservationRepo;
  final LocationService location;
  final CheckGeofence checkGeofence;
  final ReserveSlot reserveSlot;
  final ValidateGateQr validateGateQr;
  final CloseReservation closeReservation;
  final ExpireStaleReservations expireStale;

  AppSettings settings = AppSettings.defaults();
  UserProfile profile = UserProfile.defaults();
  GeofenceResult? geofence;
  String? locationError;
  bool locating = false;
  Reservation? current;

  /// Futures que consumen los FutureBuilder. Se recrean cuando cambian los
  /// datos para que las pantallas vuelvan a cargar.
  late Future<List<Reservation>> historyFuture = reservationRepo.getAll();
  final Map<int, Future<List<ParkingSlot>>> _floorCache = {};
  Future<List<FloorOccupancy>>? _occupancy;

  bool get canReserve => settings.demoMode || (geofence?.inside ?? false);

  Future<void> init() async {
    try {
      settings = await settingsRepo.load();
      profile = await profileRepo.load();
      await slotRepo.seedIfEmpty();
      await refreshReservation();
    } on AppException catch (e) {
      locationError = e.message;
    }
    notifyListeners();
    await refreshLocation();
  }

  Future<void> refreshAll() async {
    await refreshReservation();
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
    _floorCache.clear();
    _occupancy = null;
    notifyListeners();
  }

  Future<List<ParkingSlot>> slotsOfFloor(int floor) =>
      _floorCache[floor] ??= slotRepo.getByFloor(floor);

  Future<List<FloorOccupancy>> get occupancyFuture =>
      _occupancy ??= _loadOccupancy();

  Future<List<FloorOccupancy>> _loadOccupancy() async {
    final result = <FloorOccupancy>[];
    for (var f = 1; f <= AppConstants.floors; f++) {
      final slots = await slotsOfFloor(f);
      final free = slots.where((s) => s.status == SlotStatus.free).length;
      result.add((floor: f, free: free, total: slots.length));
    }
    return result;
  }

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

  Future<void> saveProfile(UserProfile value) async {
    await profileRepo.save(value);
    profile = value;
    notifyListeners();
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
