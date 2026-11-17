import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Resuelve rutas de archivos propios de la app.
///
/// En iOS la ruta absoluta del contenedor cambia entre instalaciones, por eso
/// en SQLite se guarda solo el nombre del archivo y aquí se reconstruye.
class AppPaths {
  AppPaths._();

  static late final Directory photosDir;

  static Future<void> init() async {
    final docs = await getApplicationDocumentsDirectory();
    photosDir = Directory(p.join(docs.path, 'photos'));
    if (!await photosDir.exists()) {
      await photosDir.create(recursive: true);
    }
  }

  static File photo(String fileName) => File(p.join(photosDir.path, fileName));
}
