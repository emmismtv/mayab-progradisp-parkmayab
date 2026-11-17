import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants.dart';
import '../../core/errors.dart';
import '../../core/theme.dart';
import '../../domain/entities/reservation.dart';
import '../controllers/parking_controller.dart';
import '../routes.dart';
import '../widgets/common.dart';

/// Indicaciones para llegar al cajón: piso, ala y posición.
class GuideScreen extends StatelessWidget {
  const GuideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.watch<ParkingController>();
    final r = c.current;

    return Scaffold(
      appBar: AppBar(title: const Text('Mi guía al cajón')),
      drawer: const AppDrawer(current: AppRoutes.guide),
      body: r == null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.directions_car_outlined,
                        size: 64, color: AppColors.brown),
                    const SizedBox(height: 12),
                    const Text('No tienes una reserva en curso.',
                        style: TextStyle(fontSize: 16)),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: () =>
                          Navigator.pushNamed(context, AppRoutes.availability),
                      child: const Text('Apartar lugar'),
                    ),
                  ],
                ),
              ),
            )
          : _GuideBody(reservation: r, controller: c),
    );
  }
}

class _GuideBody extends StatelessWidget {
  const _GuideBody({required this.reservation, required this.controller});
  final Reservation reservation;
  final ParkingController controller;

  List<(IconData, String)> _steps(Reservation r) {
    final parked = r.status == ReservationStatus.used;
    final number = int.parse(r.slotCode.split('-').last);
    return [
      (
        parked ? Icons.check_circle : Icons.qr_code_scanner,
        parked
            ? 'Entrada registrada en la pluma.'
            : 'Escanea el QR de la pluma de entrada.'
      ),
      (
        Icons.stairs,
        r.floor == 1
            ? 'Avanza por el carril principal de la planta baja (piso 1).'
            : 'Sube por la rampa hasta el piso ${r.floor}.'
      ),
      (
        r.wing == 'A' ? Icons.turn_left : Icons.turn_right,
        'Gira a la ${r.wing == 'A' ? 'izquierda' : 'derecha'} hacia el pasillo del ala ${r.wing}.'
      ),
      (
        Icons.local_parking,
        number <= AppConstants.slotsPerWing ~/ 2
            ? 'Tu cajón ${r.slotCode} está cerca del inicio del pasillo.'
            : 'Tu cajón ${r.slotCode} está al fondo del pasillo.'
      ),
    ];
  }

  Future<void> _close(BuildContext context) async {
    try {
      await controller.closeCurrent(reservation);
      if (!context.mounted) return;
      Navigator.popUntil(context, (r) => r.isFirst);
      showSnack(
          context,
          reservation.status == ReservationStatus.active
              ? 'Reserva cancelada.'
              : '¡Buen viaje! Visita finalizada.');
    } on AppException catch (e) {
      if (context.mounted) showSnack(context, e.message, error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = reservation;
    final active = r.status == ReservationStatus.active;
    final steps = _steps(r);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.brown,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(children: [
            const Text('TU CAJÓN',
                style: TextStyle(color: Colors.white70, letterSpacing: 2)),
            Text(r.slotCode,
                style: const TextStyle(
                    color: AppColors.orange,
                    fontSize: 56,
                    fontWeight: FontWeight.bold)),
            Text('Piso ${r.floor} · Ala ${r.wing}',
                style: const TextStyle(color: Colors.white, fontSize: 18)),
            const SizedBox(height: 8),
            StatusChip(r.status),
            if (active) ...[
              const SizedBox(height: 8),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Icon(Icons.timer_outlined, color: Colors.white70),
                const SizedBox(width: 6),
                CountdownText(
                    until: r.expiresAt,
                    style: const TextStyle(color: Colors.white, fontSize: 18)),
              ]),
            ],
          ]),
        ),
        const SizedBox(height: 16),
        for (var i = 0; i < steps.length; i++)
          Card(
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: AppColors.orange,
                child: Icon(steps[i].$1, color: Colors.white),
              ),
              title: Text('Paso ${i + 1}',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(steps[i].$2),
            ),
          ),
        const SizedBox(height: 12),
        if (active)
          FilledButton.icon(
            onPressed: () => Navigator.pushNamed(context, AppRoutes.scanner),
            icon: const Icon(Icons.qr_code_scanner),
            label: const Text('Escanear QR'),
          ),
        if (active) const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () => Navigator.pushNamed(context, AppRoutes.detail,
              arguments: r),
          icon: const Icon(Icons.info_outline),
          label: const Text('Ver detalle y mapa'),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () => _close(context),
          icon: Icon(active ? Icons.cancel_outlined : Icons.exit_to_app),
          label: Text(active ? 'Cancelar reserva' : 'Salir del estacionamiento'),
        ),
      ],
    );
  }
}
