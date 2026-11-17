import '../entities/geo_point.dart';

/// Contrato del GPS. Permite cambiar la implementación (o simularla en
/// pruebas) sin tocar los casos de uso.
abstract class LocationService {
  Future<GeoPoint> currentPosition();
  double distanceMeters(GeoPoint a, GeoPoint b);
}

enum PhotoSource { camera, gallery }

/// Contrato de cámara/galería. Devuelve el nombre de archivo guardado.
abstract class MediaService {
  Future<String?> pickPhoto(PhotoSource source);
}

/// Contrato de dictado por voz.
abstract class SpeechService {
  bool get isListening;
  Future<void> start(void Function(String text) onText,
      {void Function()? onDone});
  Future<void> stop();
}
