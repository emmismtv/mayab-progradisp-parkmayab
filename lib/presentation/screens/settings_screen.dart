import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../core/constants.dart';
import '../../core/errors.dart';
import '../../core/theme.dart';
import '../controllers/parking_controller.dart';
import '../widgets/common.dart';

/// Ajustes: modo demostración, calibración del campus y QR de la pluma.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.watch<ParkingController>();

    return Scaffold(
      appBar: brandAppBar(context, title: 'Ajustes', dark: true),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          const SectionTag('Geocerca', top: 16),
          Pad(SoftCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Column(children: [
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                activeTrackColor: AppColors.orange,
                title: const Text('Modo demostración',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text(
                    'Permite apartar aunque estés fuera del radio de 2 km.'),
                value: c.settings.demoMode,
                onChanged: c.setDemoMode,
              ),
              const Divider(),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.school_outlined,
                    color: AppColors.orange),
                title: const Text('Centro del campus',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text(
                    '${c.settings.campus.lat.toStringAsFixed(5)}, '
                    '${c.settings.campus.lng.toStringAsFixed(5)} · '
                    'Radio ${(c.settings.radiusMeters / 1000).toStringAsFixed(0)} km'),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: OutlinedButton.icon(
                  onPressed: () async {
                    try {
                      await c.calibrateCampusHere();
                      if (context.mounted) {
                        showSnack(
                            context, 'Campus calibrado en tu ubicación actual.');
                      }
                    } on AppException catch (e) {
                      if (context.mounted) {
                        showSnack(context, e.message, error: true);
                      }
                    }
                  },
                  icon: const Icon(Icons.my_location),
                  label: const Text('Calibrar campus aquí'),
                ),
              ),
            ]),
          )),
          const SectionTag('QR de la pluma'),
          const Pad(Text(
              'Para la demostración: muestra este código en otra pantalla o '
              'imprímelo, y escanéalo desde "Escanear pluma".',
              style: TextStyle(color: AppColors.grey))),
          const SizedBox(height: 16),
          Center(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.black,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Container(
                color: Colors.white,
                padding: const EdgeInsets.all(12),
                child: QrImageView(
                    data: AppConstants.gateQrPayload, size: 200),
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Center(
            child: Text('Entrada 1',
                style: TextStyle(color: AppColors.grey, fontSize: 12)),
          ),
        ],
      ),
    );
  }
}
