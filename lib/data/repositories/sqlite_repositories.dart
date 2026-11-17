import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

import '../../core/constants.dart';
import '../../core/errors.dart';
import '../../domain/entities/app_settings.dart';
import '../../domain/entities/geo_point.dart';
import '../../domain/entities/parking_slot.dart';
import '../../domain/entities/reservation.dart';
import '../../domain/repositories/repositories.dart';
import '../app_database.dart';

/// Ejecuta una operación de base de datos traduciendo cualquier error técnico
/// a una [AppException] legible (manejo de errores con try-catch).
Future<T> _guard<T>(Future<T> Function() action, String message) async {
  try {
    return await action();
  } on DatabaseException catch (_) {
    throw AppException(message);
  } catch (e) {
    if (e is AppException) rethrow;
    throw AppException(message);
  }
}

class SqliteSlotRepository implements SlotRepository {
  final AppDatabase _helper;
  SqliteSlotRepository(this._helper);

  ParkingSlot _fromMap(Map<String, Object?> m) => ParkingSlot(
        id: m['id'] as int,
        floor: m['floor'] as int,
        wing: m['wing'] as String,
        number: m['number'] as int,
        status: SlotStatus.values[m['status'] as int],
      );

  /// Siembra el edificio inventado: 3 pisos x 2 alas x 10 cajones.
  /// La ocupación inicial es simulada (no hay sensores reales).
  @override
  Future<void> seedIfEmpty() => _guard(() async {
        final db = await _helper.database;
        final count = Sqflite.firstIntValue(
            await db.rawQuery('SELECT COUNT(*) FROM slots'));
        if (count != null && count > 0) return;

        final batch = db.batch();
        for (var floor = 1; floor <= AppConstants.floors; floor++) {
          for (final wing in AppConstants.wings) {
            for (var n = 1; n <= AppConstants.slotsPerWing; n++) {
              final hash = (floor * 31 + n * 17 + (wing == 'A' ? 0 : 5)) % 10;
              final status =
                  hash < 4 ? SlotStatus.occupied : SlotStatus.free;
              batch.insert('slots', {
                'floor': floor,
                'wing': wing,
                'number': n,
                'status': status.index,
              });
            }
          }
        }
        await batch.commit(noResult: true);
      }, 'No se pudo inicializar el estacionamiento.');

  @override
  Future<List<ParkingSlot>> getByFloor(int floor) => _guard(() async {
        final db = await _helper.database;
        final rows = await db.query('slots',
            where: 'floor = ?',
            whereArgs: [floor],
            orderBy: 'wing ASC, number ASC');
        return rows.map(_fromMap).toList();
      }, 'No se pudieron cargar los cajones.');

  @override
  Future<ParkingSlot?> getById(int id) => _guard(() async {
        final db = await _helper.database;
        final rows = await db.query('slots', where: 'id = ?', whereArgs: [id]);
        return rows.isEmpty ? null : _fromMap(rows.first);
      }, 'No se pudo consultar el cajón.');

  @override
  Future<void> updateStatus(int id, SlotStatus status) => _guard(() async {
        final db = await _helper.database;
        await db.update('slots', {'status': status.index},
            where: 'id = ?', whereArgs: [id]);
      }, 'No se pudo actualizar el cajón.');
}

class SqliteReservationRepository implements ReservationRepository {
  final AppDatabase _helper;
  SqliteReservationRepository(this._helper);

  Reservation _fromMap(Map<String, Object?> m) => Reservation(
        id: m['id'] as int,
        slotId: m['slot_id'] as int,
        slotCode: m['slot_code'] as String,
        floor: m['floor'] as int,
        wing: m['wing'] as String,
        createdAt: DateTime.fromMillisecondsSinceEpoch(m['created_at'] as int),
        expiresAt: DateTime.fromMillisecondsSinceEpoch(m['expires_at'] as int),
        status: ReservationStatus.values[m['status'] as int],
        lat: (m['lat'] as num).toDouble(),
        lng: (m['lng'] as num).toDouble(),
        photoFile: m['photo_file'] as String?,
        note: m['note'] as String?,
      );

  @override
  Future<int> insert(Reservation r) => _guard(() async {
        final db = await _helper.database;
        return db.insert('reservations', {
          'slot_id': r.slotId,
          'slot_code': r.slotCode,
          'floor': r.floor,
          'wing': r.wing,
          'created_at': r.createdAt.millisecondsSinceEpoch,
          'expires_at': r.expiresAt.millisecondsSinceEpoch,
          'status': r.status.index,
          'lat': r.lat,
          'lng': r.lng,
          'photo_file': r.photoFile,
          'note': r.note,
        });
      }, 'No se pudo guardar la reserva.');

  @override
  Future<List<Reservation>> getAll() => _guard(() async {
        final db = await _helper.database;
        final rows = await db.query('reservations', orderBy: 'created_at DESC');
        return rows.map(_fromMap).toList();
      }, 'No se pudo cargar el historial.');

  @override
  Future<Reservation?> getById(int id) => _guard(() async {
        final db = await _helper.database;
        final rows =
            await db.query('reservations', where: 'id = ?', whereArgs: [id]);
        return rows.isEmpty ? null : _fromMap(rows.first);
      }, 'No se pudo cargar la reserva.');

  @override
  Future<Reservation?> getCurrent() => _guard(() async {
        final db = await _helper.database;
        final rows = await db.query('reservations',
            where: 'status IN (?, ?)',
            whereArgs: [
              ReservationStatus.active.index,
              ReservationStatus.used.index,
            ],
            orderBy: 'id DESC',
            limit: 1);
        return rows.isEmpty ? null : _fromMap(rows.first);
      }, 'No se pudo consultar tu reserva.');

  @override
  Future<void> updateStatus(int id, ReservationStatus status) =>
      _guard(() async {
        final db = await _helper.database;
        await db.update('reservations', {'status': status.index},
            where: 'id = ?', whereArgs: [id]);
      }, 'No se pudo actualizar la reserva.');
}

/// Preferencias simples (modo demo, centro del campus) en SharedPreferences.
class PrefsSettingsRepository implements SettingsRepository {
  static const _kDemo = 'demo_mode';
  static const _kLat = 'campus_lat';
  static const _kLng = 'campus_lng';

  @override
  Future<AppSettings> load() async {
    final defaults = AppSettings.defaults();
    try {
      final prefs = await SharedPreferences.getInstance();
      return AppSettings(
        demoMode: prefs.getBool(_kDemo) ?? false,
        campus: GeoPoint(
          prefs.getDouble(_kLat) ?? defaults.campus.lat,
          prefs.getDouble(_kLng) ?? defaults.campus.lng,
        ),
        radiusMeters: defaults.radiusMeters,
      );
    } catch (_) {
      return defaults; // si falla la lectura, se usan valores por defecto
    }
  }

  @override
  Future<void> save(AppSettings s) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_kDemo, s.demoMode);
      await prefs.setDouble(_kLat, s.campus.lat);
      await prefs.setDouble(_kLng, s.campus.lng);
    } catch (_) {
      throw const AppException('No se pudieron guardar los ajustes.');
    }
  }
}
