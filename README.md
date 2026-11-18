# ParkMayab

App Flutter para apartar lugar en el estacionamiento de la Universidad Anáhuac Mayab.
Proyecto del Parcial 2 de Programación de Dispositivos Móviles.

## Funcionalidades
- **Geocerca de 2 km:** solo se puede apartar estando cerca del campus (GPS con `geolocator`).
- **Disponibilidad por piso:** plano del edificio (3 pisos, alas A y B) con cajones libres, ocupados y apartados.
- **Nueva reserva:** foto del vehículo (cámara o galería), nota dictada por voz y captura de coordenadas GPS.
- **Pluma con QR:** al llegar se escanea el QR de la entrada para registrar el acceso.
- **Mi pase:** cajón asignado, cuenta regresiva de 15 minutos y guía paso a paso.
- **Historial y detalle:** visitas guardadas en SQLite, transición Hero y mapa de Google Maps.
- **Perfil:** datos del alumno y foto de perfil.

## Arquitectura por capas
| Capa | Carpeta | Contenido |
|---|---|---|
| Presentación | `lib/presentation` | Pantallas, rutas, Drawer y controladores (Provider) |
| Dominio | `lib/domain` | Entidades, contratos y casos de uso (Dart puro) |
| Datos | `lib/data` | SQLite (`sqflite`) y SharedPreferences |
| Servicios | `lib/services` | GPS, cámara/galería y dictado por voz |
| Núcleo | `lib/core` | Constantes, tema, rutas de archivos y errores |

Las dependencias se componen en `lib/main.dart`.

## Configuración
1. Copia `ios/Flutter/Secrets.xcconfig.example` a `ios/Flutter/Secrets.xcconfig` y escribe tu llave de Google Maps (Maps SDK for iOS).
2. Instala dependencias y ejecuta:

```bash
flutter pub get
flutter run
```

## Notas
- La ocupación de los cajones es simulada (no hay sensores ni servidor).
- La pluma es virtual: su QR contiene `PARKMAYAB|ENTRADA-1` y se muestra en **Ajustes** para la demostración.
- Las coordenadas del campus son aproximadas; se pueden calibrar en **Ajustes**.
- **Modo demostración** (Ajustes) permite apartar fuera del radio de 2 km.

## Pruebas
```bash
flutter test
```

## Reporte técnico
`docs/Reporte_Tecnico_ParkMayab.docx`
