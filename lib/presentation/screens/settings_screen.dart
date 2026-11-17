import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../core/constants.dart';
import '../../core/errors.dart';
import '../controllers/parking_controller.dart';
import '../routes.dart';
import '../widgets/common.dart';

/// Ajustes: modo demostración, calibración del campus y QR de la pluma.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.watch<ParkingController>();

    return Scaffold(
      appBar: AppBar(title: const Text('Ajustes')),
      drawer: const AppDrawer(current: AppRoutes.settings),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SwitchListTile(
            title: const Text('Modo demostración'),
            subtitle: const Text(
                'Permite apartar aunque estés fuera del radio de 2 km.'),
            value: c.settings.demoMode,
            onChanged: c.setDemoMode,
          ),
          const Divider(),
          ListTile(
            title: const Text('Centro del campus'),
            subtitle: Text(
                '${c.settings.campus.lat.toStringAsFixed(5)}, ${c.settings.campus.lng.toStringAsFixed(5)}\n'
                'Radio: ${(c.settings.radiusMeters / 1000).toStringAsFixed(0)} km'),
            isThreeLine: true,
          ),
          OutlinedButton.icon(
            onPressed: () async {
              try {
                await c.calibrateCampusHere();
                if (context.mounted) {
                  showSnack(context, 'Campus calibrado en tu ubicación actual.');
                }
              } on AppException catch (e) {
                if (context.mounted) showSnack(context, e.message, error: true);
              }
            },
            icon: const Icon(Icons.my_location),
            label: const Text('Calibrar campus aquí'),
          ),
          const SizedBox(height: 24),
          const Text('QR de la pluma (para la demostración)',
              style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          const Text(
              'Muestra este código en otra pantalla o imprímelo y escanéalo desde "Escanear QR".'),
          const SizedBox(height: 12),
          Center(
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.all(12),
              child: QrImageView(
                data: AppConstants.gateQrPayload,
                size: 220,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
