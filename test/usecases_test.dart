import 'package:flutter_test/flutter_test.dart';
import 'package:parkmayab/core/constants.dart';
import 'package:parkmayab/core/errors.dart';
import 'package:parkmayab/domain/entities/geo_point.dart';
import 'package:parkmayab/domain/entities/parking_slot.dart';
import 'package:parkmayab/domain/entities/reservation.dart';
import 'package:parkmayab/domain/repositories/repositories.dart';
import 'package:parkmayab/domain/repositories/services.dart';
import 'package:parkmayab/domain/usecases/usecases.dart';

/// Repositorios y GPS falsos en memoria: demuestran que el dominio no
/// depende de SQLite ni de plugins (principio de inversión de dependencias).
class FakeSlots implements SlotRepository {
  final Map<int, ParkingSlot> data = {
    1: const ParkingSlot(
        id: 1, floor: 1, wing: 'A', number: 1, status: SlotStatus.free),
  };
  @override
  Future<void> seedIfEmpty() async {}
  @override
  Future<List<ParkingSlot>> getByFloor(int floor) async => data.values.toList();
  @override
  Future<ParkingSlot?> getById(int id) async => data[id];
  @override
  Future<void> updateStatus(int id, SlotStatus status) async {
    final s = data[id]!;
    data[id] = ParkingSlot(
        id: s.id, floor: s.floor, wing: s.wing, number: s.number, status: status);
  }
}

class FakeReservations implements ReservationRepository {
  final List<Reservation> items = [];
  @override
  Future<int> insert(Reservation r) async {
    items.add(r.copyWith(id: items.length + 1));
    return items.length;
  }

  @override
  Future<List<Reservation>> getAll() async => items;
  @override
  Future<Reservation?> getById(int id) async =>
      items.where((r) => r.id == id).firstOrNull;
  @override
  Future<Reservation?> getCurrent() async =>
      items.where((r) => r.isCurrent).lastOrNull;
  @override
  Future<void> updateStatus(int id, ReservationStatus status) async {
    final i = items.indexWhere((r) => r.id == id);
    items[i] = items[i].copyWith(status: status);
  }
}

class FakeLocation implements LocationService {
  FakeLocation(this.meters);
  final double meters;
  @override
  Future<GeoPoint> currentPosition() async => const GeoPoint(21.0, -89.0);
  @override
  double distanceMeters(GeoPoint a, GeoPoint b) => meters;
}

void main() {
  const campus = GeoPoint(21.0925, -89.6010);

  ({ReserveSlot reserve, ValidateGateQr validate, FakeSlots slots, FakeReservations res})
      build(double distance) {
    final slots = FakeSlots();
    final res = FakeReservations();
    final geo = CheckGeofence(FakeLocation(distance));
    return (
      reserve: ReserveSlot(slots, res, geo),
      validate: ValidateGateQr(res, slots, ExpireStaleReservations(res, slots)),
      slots: slots,
      res: res,
    );
  }

  test('no permite apartar fuera de los 2 km', () async {
    final d = build(5000);
    expect(
      () => d.reserve(
          slotId: 1, campus: campus, radiusMeters: 2000, bypassGeofence: false),
      throwsA(isA<AppException>()),
    );
  });

  test('aparta dentro del radio y marca el cajón como apartado', () async {
    final d = build(500);
    await d.reserve(
        slotId: 1, campus: campus, radiusMeters: 2000, bypassGeofence: false);
    expect(d.slots.data[1]!.status, SlotStatus.reserved);
    expect(d.res.items.single.status, ReservationStatus.active);
  });

  test('el QR correcto registra la entrada; uno incorrecto falla', () async {
    final d = build(500);
    await d.reserve(
        slotId: 1, campus: campus, radiusMeters: 2000, bypassGeofence: false);
    expect(() => d.validate('OTRO-QR'), throwsA(isA<AppException>()));
    await d.validate(AppConstants.gateQrPayload);
    expect(d.res.items.single.status, ReservationStatus.used);
    expect(d.slots.data[1]!.status, SlotStatus.occupied);
  });
}
