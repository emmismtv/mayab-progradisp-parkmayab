import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';

import '../../core/errors.dart';
import '../../core/theme.dart';
import '../controllers/parking_controller.dart';
import '../controllers/shell_controller.dart';
import '../widgets/common.dart';

/// Escáner de QR de la pluma. Al validar, "abre" la pluma y lleva al pase.
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
    final raw =
        capture.barcodes.isEmpty ? null : capture.barcodes.first.rawValue;
    if (raw == null) return;
    _busy = true;

    final controller = context.read<ParkingController>();
    try {
      await controller.validateQr(raw);
      HapticFeedback.heavyImpact();
      if (!mounted) return;
      await showAdaptiveDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog.adaptive(
          icon: const Icon(Icons.check_circle, color: AppColors.free, size: 56),
          title: const Text('¡Pluma abierta!'),
          content: const Text(
              'Bienvenido a la Anáhuac Mayab. Te llevamos a tu cajón.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Ver mi pase'),
            ),
          ],
        ),
      );
      if (mounted) goToTab(context, Tabs.pass);
    } on AppException catch (e) {
      HapticFeedback.vibrate();
      if (mounted) showSnack(context, e.message, error: true);
      // Pausa para no repetir el mensaje en bucle.
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
      backgroundColor: Colors.black,
      appBar: brandAppBar(
        context,
        title: 'Escanear pluma',
        dark: true,
        actions: [
          IconButton(
            tooltip: 'Linterna',
            onPressed: _camera.toggleTorch,
            icon: const Icon(Icons.flashlight_on_outlined),
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _camera,
            onDetect: _onDetect,
            errorBuilder: (context, error) => EmptyState(
              icon: Icons.no_photography_outlined,
              title: 'Cámara no disponible',
              message:
                  'Revisa el permiso de cámara en Ajustes del iPhone.\n(${error.errorCode.name})',
            ),
          ),
          // Oscurece alrededor del recuadro de lectura.
          ColorFiltered(
            colorFilter: ColorFilter.mode(
                Colors.black.withValues(alpha: 0.55), BlendMode.srcOut),
            child: Stack(children: [
              Container(
                  decoration: const BoxDecoration(
                      color: Colors.black,
                      backgroundBlendMode: BlendMode.dstOut)),
              Center(
                child: Container(
                  width: 260,
                  height: 260,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
              ),
            ]),
          ),
          Center(
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.orange, width: 4),
                borderRadius: BorderRadius.circular(24),
              ),
            ),
          ),
          Positioned(
            left: 24,
            right: 24,
            bottom: 48,
            child: Column(children: [
              Text('Apunta al código QR de la pluma',
                  textAlign: TextAlign.center,
                  style: AppText.slab(size: 17, color: Colors.white)),
              const SizedBox(height: 6),
              const Text('Lo encontrarás en la Entrada 1 del estacionamiento.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70)),
            ]),
          ),
        ],
      ),
    );
  }
}
