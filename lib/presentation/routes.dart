import 'package:flutter/material.dart';

import '../domain/entities/parking_slot.dart';
import '../domain/entities/reservation.dart';
import 'screens/availability_screen.dart';
import 'screens/detail_screen.dart';
import 'screens/guide_screen.dart';
import 'screens/history_screen.dart';
import 'screens/home_screen.dart';
import 'screens/reserve_screen.dart';
import 'screens/scanner_screen.dart';
import 'screens/settings_screen.dart';

/// Rutas nombradas de la aplicación.
class AppRoutes {
  AppRoutes._();
  static const home = '/';
  static const availability = '/disponibilidad';
  static const reserve = '/reservar';
  static const scanner = '/escaner';
  static const guide = '/guia';
  static const history = '/historial';
  static const detail = '/detalle';
  static const settings = '/ajustes';

  /// Genera las rutas con una transición de desvanecido + deslizamiento
  /// suave. Los argumentos viajan en `RouteSettings.arguments`.
  static Route<dynamic> onGenerateRoute(RouteSettings s) {
    final Widget page;
    switch (s.name) {
      case availability:
        page = const AvailabilityScreen();
      case reserve:
        page = ReserveScreen(slot: s.arguments as ParkingSlot);
      case scanner:
        page = const ScannerScreen();
      case guide:
        page = const GuideScreen();
      case history:
        page = const HistoryScreen();
      case detail:
        page = DetailScreen(reservation: s.arguments as Reservation);
      case settings:
        page = const SettingsScreen();
      case home:
      default:
        page = const HomeScreen();
    }
    return PageRouteBuilder(
      settings: s,
      transitionDuration: const Duration(milliseconds: 350),
      pageBuilder: (_, _, _) => page,
      transitionsBuilder: (_, animation, _, child) {
        final curved =
            CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween<Offset>(
                    begin: const Offset(0.06, 0), end: Offset.zero)
                .animate(curved),
            child: child,
          ),
        );
      },
    );
  }
}
