import 'dart:io';

import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../core/app_paths.dart';
import '../core/errors.dart';
import '../domain/entities/geo_point.dart';
import '../domain/repositories/services.dart';

/// GPS con el paquete geolocator.
class GeolocatorLocationService implements LocationService {
  @override
  Future<GeoPoint> currentPosition() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        throw const AppException('Activa la ubicación (GPS) del iPhone.');
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw const AppException(
            'Se necesita permiso de ubicación. Actívalo en Ajustes del iPhone.');
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
      return GeoPoint(pos.latitude, pos.longitude);
    } on AppException {
      rethrow;
    } catch (_) {
      throw const AppException('No se pudo obtener tu ubicación.');
    }
  }

  @override
  double distanceMeters(GeoPoint a, GeoPoint b) =>
      Geolocator.distanceBetween(a.lat, a.lng, b.lat, b.lng);
}

/// Cámara y galería con image_picker. La imagen se copia al directorio
/// propio de la app para que no dependa de archivos temporales.
class ImagePickerMediaService implements MediaService {
  final ImagePicker _picker = ImagePicker();

  @override
  Future<String?> pickPhoto(PhotoSource source) async {
    try {
      final picked = await _picker.pickImage(
        source: source == PhotoSource.camera
            ? ImageSource.camera
            : ImageSource.gallery,
        maxWidth: 1600,
        imageQuality: 80,
      );
      if (picked == null) return null; // el usuario canceló
      final name = 'res_${DateTime.now().millisecondsSinceEpoch}.jpg';
      await File(picked.path).copy(AppPaths.photo(name).path);
      return name;
    } catch (_) {
      throw const AppException(
          'No se pudo obtener la foto. Revisa los permisos de cámara/fotos.');
    }
  }
}

/// Dictado: el micrófono captura el audio y speech_to_text lo transcribe.
class SttSpeechService implements SpeechService {
  final SpeechToText _stt = SpeechToText();
  bool _ready = false;

  @override
  bool get isListening => _stt.isListening;

  @override
  Future<void> start(void Function(String text) onText,
      {void Function()? onDone}) async {
    try {
      if (!_ready) {
        _ready = await _stt.initialize(
          onStatus: (s) {
            if (s == 'done' || s == 'notListening') onDone?.call();
          },
        );
      }
      if (!_ready) {
        throw const AppException(
            'Dictado no disponible. Activa micrófono y reconocimiento de voz.');
      }
      await _stt.listen(
        onResult: (r) => onText(r.recognizedWords),
        listenOptions:
            SpeechListenOptions(partialResults: true, localeId: 'es_MX'),
      );
    } on AppException {
      rethrow;
    } catch (_) {
      throw const AppException('No se pudo iniciar el dictado.');
    }
  }

  @override
  Future<void> stop() => _stt.stop();
}
