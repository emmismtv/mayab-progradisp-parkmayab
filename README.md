# ParkMayab

App Flutter para apartar lugar en el estacionamiento de la Universidad Anáhuac Mayab.
Proyecto del Parcial 2 de Programación de Dispositivos Móviles.

## Flujo
1. Inicio: mapa con el radio de 2 km del campus y tu distancia por GPS.
2. Dentro del radio se habilita "Apartar lugar" (modo demostración en Ajustes para saltarlo).
3. Disponibilidad por piso (libre / ocupado / apartado) y formulario con foto (cámara o galería),
   nota dictada por voz y captura del GPS.
4. Al llegar, se escanea el QR de la pluma (el QR de la demo está en Ajustes).
5. Guía al piso, ala y cajón. Historial y detalle con mapa y botón a Google Maps.

## Arquitectura por capas
- `lib/domain`: entidades, contratos (repositorios y servicios) y casos de uso.
- `lib/data`: SQLite (sqflite) y SharedPreferences que implementan los contratos.
- `lib/services`: GPS (geolocator), cámara/galería (image_picker), dictado (speech_to_text).
- `lib/presentation`: controlador (Provider), rutas y pantallas.
- `lib/main.dart`: composición de dependencias.

## Notas
- La ocupación de cajones es simulada (no hay sensores ni servidor); los datos viven en SQLite local.
- La pluma es simulada: el QR contiene `PARKMAYAB|ENTRADA-1`.
- Las coordenadas del campus son aproximadas; se pueden calibrar en Ajustes.
- Se necesita un iPhone real para cámara, GPS y dictado.

## Ejecutar
```bash
flutter pub get
flutter run
```
