import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';

import '../../core/errors.dart';
import '../../core/theme.dart';
import '../controllers/parking_controller.dart';
import '../routes.dart';
import '../widgets/common.dart';

/// Escáner de QR de la pluma. Al validar, "abre" la pluma y lleva a la guía.
class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  final MobileScannerController _camera = MobileScannerController(
    formats: const [BarcodeFormat.qrCode],
    detectionSpeed: DetectionSpeed.noDuplicates,
  );
  bool _busy = false;

  @override
  void dispose() {
    _camera.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_busy) return;
    final raw = capture.barcodes.isEmpty ? null : capture.barcodes.first.rawValue;
    if (raw == null) return;
    _busy = true;

    final controller = context.read<ParkingController>();
    try {
      await controller.validateQr(raw);
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          icon: const Icon(Icons.check_circle, color: AppColors.free, size: 56),
          title: const Text('¡Pluma abierta!'),
          content: const Text('Bienvenido a la Anáhuac Mayab. Te llevamos a tu cajón.'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Ver guía')),
          ],
        ),
      );
      if (mounted) Navigator.pushReplacementNamed(context, AppRoutes.guide);
    } on AppException catch (e) {
      if (mounted) showSnack(context, e.message, error: true);
      // Pequeña pausa para no repetir el mensaje en bucle.
      await Future<void>.delayed(const Duration(seconds: 2));
      _busy = false;
    } catch (_) {
      if (mounted) showSnack(context, 'No se pudo validar el QR.', error: true);
      _busy = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Escanear QR de la pluma')),
      body: Stack(
        children: [
          MobileScanner(
            controller: _camera,
            onDetect: _onDetect,
            errorBuilder: (context, error) => Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'No se pudo abrir la cámara. Revisa el permiso en Ajustes del iPhone.\n(${error.errorCode.name})',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.orange, width: 4),
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
          const Positioned(
            left: 0,
            right: 0,
            bottom: 40,
            child: Text(
              'Apunta al código QR de la pluma',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  shadows: [Shadow(blurRadius: 6)]),
            ),
          ),
        ],
      ),
    );
  }
}
