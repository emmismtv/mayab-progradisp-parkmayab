import 'package:flutter/material.dart';

import '../domain/entities/parking_slot.dart';
import '../domain/entities/reservation.dart';
import 'screens/detail_screen.dart';
import 'screens/reserve_screen.dart';
import 'screens/scanner_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/shell_screen.dart';

/// Rutas nombradas. La raíz ("/") contiene las pestañas
/// (Inicio, Lugares, Mi pase, Historial, Perfil); el resto se apilan
/// encima con Navigator y la transición nativa de cada plataforma.
class AppRoutes {
  AppRoutes._();
  static const home = '/';
  static const reserve = '/reservar';
  static const scanner = '/escaner';
  static const detail = '/detalle';
  static const settings = '/ajustes';

  static Route<dynamic> onGenerateRoute(RouteSettings s) {
    final Widget page = switch (s.name) {
      reserve => ReserveScreen(slot: s.arguments as ParkingSlot),
      scanner => const ScannerScreen(),
      detail => DetailScreen(reservation: s.arguments as Reservation),
      settings => const SettingsScreen(),
      _ => const ShellScreen(),
    };
    return MaterialPageRoute(settings: s, builder: (_) => page);
  }
}
