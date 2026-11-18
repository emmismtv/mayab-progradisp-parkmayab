import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/shell_controller.dart';
import 'availability_screen.dart';
import 'guide_screen.dart';
import 'history_screen.dart';
import 'home_screen.dart';
import 'profile_screen.dart';

/// Estructura principal: secciones que se eligen desde el Drawer lateral.
/// Cada sección tiene su propio Scaffold con AppBar y Drawer.
class ShellScreen extends StatelessWidget {
  const ShellScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final shell = context.watch<ShellController>();
    return IndexedStack(
      index: shell.index,
      children: const [
        HomeScreen(),
        AvailabilityScreen(),
        GuideScreen(),
        HistoryScreen(),
        ProfileScreen(),
      ],
    );
  }
}
