import 'package:flutter/foundation.dart';

/// Índices de las pestañas de la barra inferior.
class Tabs {
  Tabs._();
  static const home = 0;
  static const spots = 1;
  static const pass = 2;
  static const history = 3;
  static const profile = 4;
}

/// Estado de navegación de la barra inferior (solo UI, sin lógica de negocio).
class ShellController extends ChangeNotifier {
  int index = Tabs.home;
  int floor = 1;

  void go(int tab, {int? floor}) {
    index = tab;
    if (floor != null) this.floor = floor;
    notifyListeners();
  }

  void selectFloor(int value) {
    floor = value;
    notifyListeners();
  }
}
