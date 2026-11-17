import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

/// Acceso único (singleton) a la base SQLite local.
class AppDatabase {
  AppDatabase._();
  static final AppDatabase instance = AppDatabase._();

  Database? _db;

  Future<Database> get database async => _db ??= await _open();

  Future<Database> _open() async {
    final path = p.join(await getDatabasesPath(), 'parkmayab.db');
    return openDatabase(
      path,
      version: 1,
      onCreate: (db, _) async {
        await db.execute('''
          CREATE TABLE slots(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            floor INTEGER NOT NULL,
            wing TEXT NOT NULL,
            number INTEGER NOT NULL,
            status INTEGER NOT NULL
          )''');
        await db.execute('''
          CREATE TABLE reservations(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            slot_id INTEGER NOT NULL,
            slot_code TEXT NOT NULL,
            floor INTEGER NOT NULL,
            wing TEXT NOT NULL,
            created_at INTEGER NOT NULL,
            expires_at INTEGER NOT NULL,
            status INTEGER NOT NULL,
            lat REAL NOT NULL,
            lng REAL NOT NULL,
            photo_file TEXT,
            note TEXT
          )''');
      },
    );
  }
}
